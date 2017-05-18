#!/bin/bash

echo "Starting the release process"

###################### CONFIGURATION SECTION #########################################

version=1.2.2

user=vmssusrroot

# Path from where all the build scripts are running
home=$(pwd)

# Prepare DB connection parameters
dbname="deckqa"
dbusername="deckqa"	
dbpassword="S3cureP@55"
dbhost="localhost"

# Name of the environment file to be used for this environment
envfile='.env.example'
indexerConfFile='config.properties.qa'
release_config_file="release_config.stage"
iepy_dbproperties_file="dbproperties.py.stage"
iepy_dbproperties_path="resources/shell_scripts/iepy_information_extraction/iepy_core/Settings"

# git repository url
core_url=git@128.199.87.138:root/pepcore.git
branch=stage

# directory where the application is going to be deployed and the backup directory
directory="/usr/local/iepycoredir/iepycorecode"
home="/home/vmssusrroot"

echo "Release configurations are set"

###################### END OF CONFIGURATION SECTION #########################################

################# GET LATEST  CODE  FROM  GIT ###############################################

cd $directory

echo "Start the current release build to $directory"

if [ -d "$directory" ]; then

  # find the current folder is empty
  echo "Check release folder empty or not"
  
 if [ $(find $directory -maxdepth 0 -type d -empty 2>/dev/null) ]; then
      
  cd $directory

  if ! [ -d "$directory/.git" ]; then
    echo "git repository not found"
    echo "Clone project UR : "$core_url
    git clone --no-checkout $core_url $directory/.tmp 
    mv $directory/.tmp/.git $directory/
    rm -rf $directory/.tmp
    cd $directory
    git reset --hard HEAD
    
  fi
  
  cd $directory
  echo "Changed the directory to $directory"

fi

cd $directory

if [ "$(ls -A)" ]; then
    echo "Directory already has data"   
    echo "Pull new code from project URL : "$core_url
    git checkout $branch
   # git fetch --all
    git checkout .
    git pull
   # git reset --hard origin/$branch
else
    echo "Empty Folder - checking out the files"
    echo "Clone project from : $core_url"
    
    git clone $core_url $directory
    git checkout $branch
fi

fi
################### INSTALL REQUIRED PACKAGES########################################

cd $home

if [ $(dpkg-query -W -f='${Status}' php7.0-curl 2>/dev/null | grep -c "ok installed") -eq 0 ];
then
  sudo apt-get install php7.0-curl -y
  
  echo "php7.0-curl has been installed"
fi

if [ $(dpkg-query -W -f='${Status}' php7.0-mysql 2>/dev/null | grep -c "ok installed") -eq 0 ];
then
  sudo apt-get install php7.0-mysql -y
  
  echo "php7.0-mysql has been installed"
fi

if [ $(dpkg-query -W -f='${Status}' php7.0-mbstring 2>/dev/null | grep -c "ok installed") -eq 0 ];
then
  sudo apt-get install php7.0-mbstring -y
  
  echo "php7.0-mbstring has been installed"
fi

if [ $(dpkg-query -W -f='${Status}' supervisor 2>/dev/null | grep -c "ok installed") -eq 0 ];
then
  sudo apt-get install supervisor  -y
  
  echo "supervisord  been installed"
fi


if [ $(dpkg-query -W -f='${Status}' php7.0-gd 2>/dev/null | grep -c "ok installed") -eq 0 ];
then
  sudo apt-get install php7.0-gd -y
  
  echo "php7.0-gd been installed"
fi



################### UPDATE REQUIRED LARAVEL PACKAGES AND DB UPDATE #####################

cd $directory

echo "Installing required laravel packages"

composer install

echo "Migrating the database"

# php artisan migrate

echo "Seed the database"

# php artisan db:seed


#################### CREATE REQUIRED FOLDERS AND SET PERMISSIONS ###########################

cd $directory

echo "Check and Creating the required directories"

if ! [ -d "storage" ]; then
mkdir -p "storage"
echo "storage directory is created"
fi

cd storage

if ! [ -d "app" ]; then
mkdir -p "app"
echo "app directory is created"
fi


if ! [ -d "logs" ]; then
mkdir -p "logs"
echo "logs directory is created"
fi


if ! [ -d "framework" ]; then
mkdir -p "framework"
echo "framework directory is created"
fi

cd $directory/storage/framework

if ! [ -d "cache" ]; then
mkdir -p "cache"
echo "cache directory is created"
fi

if ! [ -d "sessions" ]; then
mkdir -p "sessions"
echo "session directory is created"
fi

if ! [ -d "views" ]; then
mkdir -p "views"
echo "views directory is created"
fi

echo "set the permissions for the bootstap direcotry"

cd $directory
#echo $password | sudo -S chmod -R 777 storage
echo $password | sudo -S chmod -R 777 bootstrap

echo "deleting old log files"
sudo rm -rf $directory/storage/logs/*.*

#################### UPDATING ENV FILE ##############################################

cd $directory

echo "Renaming the iepy env file"

cp $envfile .env;

#################### UPDATING IE PY DB FILE ##############################################

cd $directory/$iepy_dbproperties_path

echo "Renaming the iepy db properties file"

cp $iepy_dbproperties_file dbproperties.py;

#################### CREATE REQUIRED QUEUE LISTENERS AND RESTART THE QUEUE ###################


cd $home

echo 'Creating the queue configuration for supervisor'

conf_file=iepycore.conf

# Read the queues from the release config

cd $directory

source $release_config_file > /dev/null

echo  $home/$conf_file

OIFS=$IFS;
IFS="|";

cat /dev/null > $home/$conf_file

echo '
[supervisord]
logfile='$directory'/supervisord.log       ; supervisord log file
logfile_maxbytes=50MB                           ; maximum size of logfile before rotation
logfile_backups=10                              ; number of backed up logfiles
loglevel=error                                  ; info, debug, warn, trace
pidfile=/var/run/supervisord.pid                ; pidfile location
nodaemon=false                                 ; run supervisord as a daemon
minfds=1024                                    ; number of startup file descriptors
minprocs=200                                 ; number of process descriptors
childlogdir='$directory'                 ; where child log files will live' >> $home/$conf_file

echo $queue_list_process

queues=($queue_list_process)

echo $queue

# Create the supervisor configurations and append in the conf file

for i in “${queues[@]}”

do
  
   queue_config="${i/”/}"
   queue_config="${queue_config/“/}"
      
    OIFS=$IFS;
    IFS="^";
      
    queue=($queue_config)
    
    queue_name=${queue[0]}
    no_of_process=${queue[1]}
    
    process_name='process_name='$queue_name'Listener'
    
    if [ $no_of_process != 1 ]; then
      process_name='process_name=%(program_name)s_%(process_num)02d'
    fi
    
    echo '    

[program:'$queue_name']
directory='$directory'
command=php artisan queue:work --daemon --queue='$queue_name' --tries=3  --timeout=3600
autostart=true
autorestart=true
user='$user'
numprocs='$no_of_process'
redirect_stderr=true 
'$process_name'
stdout_logfile='$directory'/storage/logs/'$queue_name'Listener.log' >> $home/$conf_file
  
done  

# Move the configuration file to the supervior conf folder and restart the listeners.

sudo mv -f $home/$conf_file /etc/supervisor/conf.d/$conf_file

sudo service supervisor stop

sleep 10

sudo service supervisor start

sleep 10

echo 'Queue listeners are configured and restarted supervior'

#################### CHECK AND UPDATE THE SYSTEM CONFIGURATIONS ###################

cd $home

upload_max_filesize=256M
post_max_size=256M
memory_limit=-1
 
restart_apache='false'

# Check that upload max file is matching or not, if not set 
php_upload_max_filesize=$(php -r "echo ini_get('upload_max_filesize');")
 
if [ $upload_max_filesize != $php_upload_max_filesize ];then
  
  restart_apache='true'
  
  if [ -d "/etc/php/7.0/cli/" ]; then   
    echo 'upload_max_filesize='$upload_max_filesize | sudo tee -a /etc/php/7.0/cli/php.ini
  fi
  
  if [ -d "/etc/php/7.0/apache2" ]; then   
    echo 'upload_max_filesize='$upload_max_filesize | sudo tee -a /etc/php/7.0/apache2/php.ini
  fi
    
  if [ -d "/etc/php/7.0/cgi" ]; then   
    echo 'upload_max_filesize='$upload_max_filesize | sudo tee -a /etc/php/7.0/cgi/php.ini
  fi
  
  echo 'php.ini upload_max_filesize has been set to '$upload_max_filesize
fi

# Check that post max size file is matching or not, if not set
php_post_max_size=$(php -r "echo ini_get('post_max_size');")
 
if [ $post_max_size != $php_post_max_size ];then
  
  restart_apache='true'
  
  if [ -d "/etc/php/7.0/cli/" ]; then   
    echo 'post_max_size='$post_max_size | sudo tee -a /etc/php/7.0/cli/php.ini
  fi
  
  if [ -d "/etc/php/7.0/apache2" ]; then   
    echo 'post_max_size='$post_max_size | sudo tee -a /etc/php/7.0/apache2/php.ini
  fi
    
  if [ -d "/etc/php/7.0/cgi" ]; then   
    echo 'post_max_size='$post_max_size | sudo tee -a /etc/php/7.0/cgi/php.ini
  fi
  
  echo 'php.ini post_max_size has been set to '$post_max_size
fi

# Check that max memory size file is matching or not, if not set
php_memory_limit=$(php -r "echo ini_get('memory_limit');")
 
if [ $memory_limit != $php_memory_limit ];then
  
  restart_apache='true'
  
  if [ -d "/etc/php/7.0/cli/" ]; then   
    echo 'memory_limit='$memory_limit | sudo tee -a /etc/php/7.0/cli/php.ini
  fi
  
  if [ -d "/etc/php/7.0/apache2" ]; then   
    echo 'memory_limit='$memory_limit | sudo tee -a /etc/php/7.0/apache2/php.ini
  fi
    
  if [ -d "/etc/php/7.0/cgi" ]; then   
    echo 'memory_limit='$memory_limit | sudo tee -a /etc/php/7.0/cgi/php.ini
  fi
  
  echo 'php.ini memory_limit has been set to '$memory_limit
fi

if [ $restart_apache = 'true' ]; then

  echo "Restarting apache2 service"

  sudo service apache2 restart

  sleep 5
fi

################### BRING UP THE SYSTEM FROM THE MAINTENANCE MODE ###################

echo "Release completed!!!"
