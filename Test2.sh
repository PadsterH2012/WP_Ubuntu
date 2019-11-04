#!/bin/bash
## Server Setup
clear
echo "Please provide your domain name without the www. (e.g. mydomain.com)"
read -p "Type your domain name, then press [ENTER] : " MY_DOMAIN
#read -p "Type your mysql DB ip address, then press [ENTER] : " MY_DOMAIN
read -p "Type your mysql DB name, then press [ENTER] : " DB_NAME
read -p "Type your mysql Username, then press [ENTER] : " DB_USERNAME
#read -p "Type your mysql Password, then press [ENTER] : " DB_PASSWORD
sudo hostname $MY_DOMAIN
#############################################
sudo apt-get update && apt get upgrade -y
#############################################
sudo apt install open-vm-tools htop apache2 software-properties-common -y
##############################################
sudo debconf-set-selections <<< "postfix postfix/mailname string your.hostname.com"
sudo debconf-set-selections <<< "postfix postfix/main_mailer_type string 'Internet Site'"
sudo apt-get install -y postfix
##############################################
sudo apt install mariadb-server mariadb-client -y
sudo apt install expect -y
###########################################
sudo mysql -u root -e "use mysql;update user set plugin='' where User='root';flush privileges;\q"
#use mysql;
#sudo mysql -u root -e "update user set plugin='' where User='root';"
#update user set plugin='' where User='root';
#sudo mysql -u root -e "flush privileges;"
#flush privileges;
#sudo mysql -u root -e "\q"
#\q
##################################################
CURRENT_MYSQL_PASSWORD=''
NEW_MYSQL_PASSWORD=$(openssl rand -base64 29 | tr -d "=+/" | cut -c1-25)
SECURE_MYSQL=$(expect -c "
set timeout 3
spawn mysql_secure_installation
expect \"Enter current password for root (enter for none):\"
send \"$CURRENT_MYSQL_PASSWORD\r\"
expect \"root password?\"
send \"y\r\"
expect \"New password:\"
send \"$NEW_MYSQL_PASSWORD\r\"
expect \"Re-enter new password:\"
send \"$NEW_MYSQL_PASSWORD\r\"
expect \"Remove anonymous users?\"
send \"y\r\"
expect \"Disallow root login remotely?\"
send \"y\r\"
expect \"Remove test database and access to it?\"
send \"y\r\"
expect \"Reload privilege tables now?\"
send \"y\r\"
expect eof
")
echo "${SECURE_MYSQL}"
userpass=$(openssl rand -base64 29 | tr -d "=+/" | cut -c1-25)
echo "CREATE DATABASE $DB_NAME;" | mysql -u root -p$NEW_MYSQL_PASSWORD
echo "CREATE USER '$DB_USERNAME'@'localhost' IDENTIFIED BY '$userpass';" | mysql -u root -p$NEW_MYSQL_PASSWORD
echo "GRANT ALL PRIVILEGES ON $DB_NAME.* TO '$DB_USERNAME'@'localhost';" | mysql -u root -p$NEW_MYSQL_PASSWORD
echo "FLUSH PRIVILEGES;" | mysql -u root -p$NEW_MYSQL_PASSWORD
sudo apt purge expect -y
sudo apt autoremove -y
sudo apt autoclean -y
#####################################################
sudo add-apt-repository ppa:ondrej/php -y
sudo apt-get update
sudo apt install php7.3 -y
sudo apt install imagemagick php7.3-common php7.3-cli php7.3-bcmath php-imagick php7.3-mysql php7.3-bz2 php7.3-curl php7.3-gd php7.3-intl php7.3-json php7.3-mbstring php7.3-readline php7.3-xml php7.3-zip php7.3-fpm -y
#sudo apt install php php-gd php-imagick php-curl php-mysql -y
sudo a2dismod php7.2
sudo a2enmod php7.3
sudo service apache2 restart
#############################################
sudo wget -qO- http://www.webmin.com/jcameron-key.asc | sudo apt-key add
sudo add-apt-repository "deb http://download.webmin.com/download/repository sarge contrib"
sudo apt-get update && apt get upgrade -y
sudo apt install webmin -y
#############################################
sudo apt-get update && apt get upgrade -y
#############################################
#####################################################
cd /tmp && wget https://wordpress.org/latest.tar.gz
tar -xvf latest.tar.gz
sudo cp -R wordpress /var/www/html/


sudo mkdir /var/www/html/wordpress/wp-content/uploads

#sudo cp /var/www/html/wordpress/wp-config-sample.php /var/www/html/wordpress/wp-config.php

sudo chown www-data:www-data -R /var/www/html/*
sudo find . -type d -exec chmod 755 {} \;
sudo find . -type f -exec chmod 644 {} \;
sudo chmod 1777 /tmp
sudo service apache2 restart
sudo service mysql restart
######################################################
echo "###############################################"
echo
echo "Database Name: $DB_NAME"
echo
echo "Username: $DB_USERNAME"
echo "Password: $userpass"
echo
echo
echo "Your MySQL ROOT Password is: $NEW_MYSQL_PASSWORD"
echo
echo "###############################################"
