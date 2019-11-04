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
sudo apt install open-vm-tools htop nginx -y
echo "Installing PHP7.3"
sudo apt install php7.3-fpm php7.3-mysql php7.3-mcrypt php-mbstring php-gettext php-curl php7.3-gd -y
