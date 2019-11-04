#!/bin/bash
clear
echo "Lets Get WordPress Installed !!!"
echo "Please provide your domain name without the www. (e.g. mydomain.com)"
read -p "Type your domain name, then press [ENTER] : " MY_DOMAIN
apt update -y
apt upgrade -y
echo "Installing nginx"
apt install nginx -y
echo "Installing PHP7.3"
apt install php7.3-fpm php7.3-mysql php7.3-mcrypt php-mbstring php-gettext php-curl php7.3-gd -y
