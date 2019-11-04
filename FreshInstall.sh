#!/bin/bash
# Server Setup
# Misc Install
# PHP 7.3 Install
# Apache Install
# WP Install
#
#
## Server Setup
clear
echo "Please provide your domain name without the www. (e.g. mydomain.com)"
read -p "Type your domain name, then press [ENTER] : " MY_DOMAIN
## Misc Install
sudo apt update -y
sudo apt upgrade -y
echo "Installing Misc Items"
sudo apt install open-vm-tools htop apache2 software-properties-common -y
echo "Installing PHP7.3"
sudo add-apt-repository ppa:ondrej/php
sudo apt update -y
sudo apt install php7.3 php7.3-fpm php7.3-mysql php7.1-mcrypt php-mbstring php-gettext php-curl php7.3-gd -y
sudo phpenmod mcrypt
sudo phpenmod mbstring
sudo perl -pi -e "s/;cgi.fix_pathinfo=1/cgi.fix_pathinfo=0/g" /etc/php/7.3/fpm/php.ini
sudo perl -pi -e "s/domain.com/$MY_DOMAIN/g" /etc/apache2/sites-available/default
sudo perl -pi -e "s/www.domain.com/www.$MY_DOMAIN/g" /etc/apache2/sites-available/default
sudo apt install mariadb-client mariadb-server -y
sudo apt install expect -y
CURRENT_MYSQL_PASSWORD=''
NEW_MYSQL_PASSWORD=$(openssl rand -base64 29 | tr -d "=+/" | cut -c1-25)
SECURE_MYSQL=$(expect -c "
set timeout 3
sudo spawn mysql_secure_installation
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
# Create WordPress MySQL database
dbname="wpdbse"
dbuser="wpuser"
userpass=$(openssl rand -base64 29 | tr -d "=+/" | cut -c1-25)
echo "CREATE DATABASE $dbname;" | mysql -u root -p$NEW_MYSQL_PASSWORD
echo "CREATE USER '$dbuser'@'localhost' IDENTIFIED BY '$userpass';" | mysql -u root -p$NEW_MYSQL_PASSWORD
echo "GRANT ALL PRIVILEGES ON $dbname.* TO '$dbuser'@'localhost';" | mysql -u root -p$NEW_MYSQL_PASSWORD
echo "FLUSH PRIVILEGES;" | mysql -u root -p$NEW_MYSQL_PASSWORD
sudo apt purge expect -y
sudo apt autoremove -y
sudo apt autoclean -y
sudo wget https://wordpress.org/latest.tar.gz
sudo tar xzvf latest.tar.gz
sudo cp ./wordpress/wp-config-sample.php ./wordpress/wp-config.php
sudo touch ./wordpress/.htaccess
sudo chmod 660 ./wordpress/.htaccess
sudo mkdir ./wordpress/wp-content/upgrade
sudo cp -a ./wordpress/. /var/www/html
sudo chown -R www-data /var/www/html
sudo find /var/www/html -type d -exec chmod g+s {} \;
sudo chmod g+w /var/www/html/wp-content
sudo chmod -R g+w /var/www/html/wp-content/themes
sudo chmod -R g+w /var/www/html/wp-content/plugins
sudo perl -pi -e "s/database_name_here/$dbname/g" /var/www/html/wp-config.php
sudo perl -pi -e "s/username_here/$dbuser/g" /var/www/html/wp-config.php
sudo perl -pi -e "s/password_here/$userpass/g" /var/www/html/wp-config.php
sudo service nginx restart
sudo service php7.3-fpm restart
sudo service mysql restart
echo "You are almost done. Replace the Secret Key in the wp-config.php with:"
echo
echo
curl -s https://api.wordpress.org/secret-key/1.1/salt/
echo
echo
echo "Use: nano /var/www/html/wp-config.php"
echo "... to edit the file!"
echo
echo "Then visit your website IP or Domain name to complete the WordPress Installation."
echo
read -p "Press [ENTER] to display your WordPress MySQL database details!"
echo "Database Name: $dbname"
echo "Username: $dbuser"
echo "Password: $userpass"
echo "Your MySQL ROOT Password is: $NEW_MYSQL_PASSWORD"
