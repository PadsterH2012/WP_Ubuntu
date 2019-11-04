#!/bin/bash
## Server Setup
clear
echo "Please provide your domain name without the www. (e.g. mydomain.com)"
read -p "Type your domain name, then press [ENTER] : " MY_DOMAIN
#read -p "Type your mysql DB ip address, then press [ENTER] : " MY_DOMAIN
read -p "Type your mysql DB name, then press [ENTER] : " DB_NAME
read -p "Type your mysql Username, then press [ENTER] : " DB_USERNAME
#read -p "Type your mysql Password, then press [ENTER] : " DB_PASSWORD
#############################################
sudo apt-get update && apt get upgrade -y
sudo apt install apache2 -y
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
sudo apt install php php-mysql -y
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
