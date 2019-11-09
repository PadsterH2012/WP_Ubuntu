#!/bin/bash
## Centos Server Setup
# Pre Req - Install Curl - yum install curl
# Run as Root
#
clear
echo "Please provide your domain name without the www. (e.g. mydomain.com)"
read -p "Type your domain name, then press [ENTER] : " MY_DOMAIN
#read -p "Type your mysql DB ip address, then press [ENTER] : " MY_DOMAIN
read -p "Type your mysql DB name, then press [ENTER] : " DB_NAME
read -p "Type your mysql Username, then press [ENTER] : " DB_USERNAME
#read -p "Type your mysql Password, then press [ENTER] : " DB_PASSWORD
sudo hostname $MY_DOMAIN
#############################################
yum -y install http://rpms.remirepo.net/enterprise/remi-release-7.rpm
yum -y update
yum -y install yum-utils
yum-config-manager --disable remi-php54
yum-config-manager --enable remi-php73
yum -y install wget expect nano nginx mariadb mariadb-server php php-mysqlnd php-fpm php-opcache php-gd php-xml php-mbstring

#############################################
systemctl start nginx
systemctl enable nginx
systemctl status nginx
firewall-cmd --permanent --zone=public --add-service=http
firewall-cmd --permanent --zone=public --add-service=https
systemctl reload firewalld
chown nginx:nginx /usr/share/nginx/html -R
#############################################
systemctl start mariadb
systemctl enable mariadb
systemctl status mariadb
mysql_secure_installation
#############################################
systemctl start php-fpm
systemctl enable php-fpm
systemctl status php-fpm
