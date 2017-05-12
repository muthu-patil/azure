echo "Installing required packages"


 sudo apt-get install git -y
 echo "git has been installed"

  sudo apt-get install supervisor  -y
  
  echo "supervisord  been installed"


  sudo apt-get install python-software-properties -y
  sudo LC_ALL=C.UTF-8 add-apt-repository ppa:ondrej/php -y
  sudo apt-get update
  sleep 1
  sudo apt-get -y install sudo apt-get install php7.0-cli php7.0-common libapache2-mod-php7.0 php7.0 php7.0-mysql php7.0-fpm php7.0-curl php7.0-gd php7.0-bz2 && php7.0-mcrypt php7.0-zip php7.0-xml php7.0-mbstring php7.0-gd
  echo "php7.0 been installed"

  sleep 1

  sudo apt-get install php7.0-curl -y
  
  echo "php7.0-curl has been installed"



  sudo apt-get install php7.0-gd -y
  
  echo "php7.0-gd has been installed"


  sudo apt-get install poppler-utils  -y
  
  echo "poppler-utils has been installed"

  sleep 1

  sudo apt-get install tesseract-ocr  -y
  
  echo "tesseract-ocr has been installed"

  sudo apt-get install imagemagick  -y
  
  echo "imagemagick has been installed"

  sleep 1
  sudo apt-get install libreoffice -y
  
  echo "libreoffice been installed"
   
  sleep 1

  sudo add-apt-repository ppa:webupd8team/java -y
  sudo apt-get update
  sudo apt-get install oracle-java8-installer -y 
  echo "java has been installed"

 sleep 2

 curl -sS https://getcomposer.org/installer | php
 sudo mv composer.phar /usr/local/bin/composer
 sudo chmod +x /usr/local/bin/composer
 echo "composer has been installed"
  
 echo "Python package installation"
sleep 2

sudo apt-get install python3.5 -y

sudo apt-get install python3-pip -y 
sudo pip3 install -U numpy 
sudo pip3 install -U nltk 
sleep 2
sudo pip3 install iepy 
sudo  pip3 install beautifulsoup4 
sleep 2
sudo a2enmod rewrite
sleep 1
echo "Required packages has been updated successfully"