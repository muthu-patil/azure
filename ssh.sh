 #!/bin/bash
 cd /tmp
 wget https://raw.githubusercontent.com/Azure/WALinuxAgent/WALinuxAgent-2.0.18/waagent  
 sudo chmod +x waagent
 sudo cp waagent /usr/sbin/waagent
 sudo /usr/sbin/waagent -install -verbose
 sudo service walinuxagent restart 
