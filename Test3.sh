#!/bin/bash
## Centos Server Setup
# Pre Req - Install Curl - yum install curl
# Run as Root
#
clear
echo "Please provide your domain name without the www. (e.g. mydomain.com)"
read -p "Type your domain name, then press [ENTER] : " MY_DOMAIN
read -p "Type your site name, then press [ENTER] : " MY_SITE
##read -p "Type your mysql DB ip address, then press [ENTER] : " MY_DOMAIN
#read -p "Type your mysql DB name, then press [ENTER] : " DB_NAME
#read -p "Type your mysql Username, then press [ENTER] : " DB_USERNAME
##read -p "Type your mysql Password, then press [ENTER] : " DB_PASSWORD
hostname $MY_DOMAIN
############################################# NGINX
yum -y install nginx
#cat << EOF > /etc/yum.repos.d/nginx.repo
#[nginx-mainline]
#name=nginx mainline repo
#baseurl=http://nginx.org/packages/mainline/centos/8/x86_64/
#gpgcheck=1
#enabled=1
#gpgkey=https://nginx.org/keys/nginx_signing.key
#EOF
#yum install -y nginx --disablerepo=* --enablerepo=nginx-mainline
systemctl start nginx
systemctl status nginx
firewall-cmd --permanent --zone=public --add-service=http
firewall-cmd --permanent --zone=public --add-service=https
systemctl reload firewalld
chown nginx:nginx /usr/share/nginx/html -R
systemctl enable nginx
############################################# MARIADB
yum -y install mariadb mariadb-server
systemctl start mariadb
systemctl enable mariadb
############################################# PHP-FPM
yum -y install php php-mysqlnd php-fpm php-opcache php-gd php-xml php-mbstring php-cli
sed -i 's/;cgi.fix_pathinfo=1/cgi.fix_pathinfo=0/g' /etc/php.ini
sed -i 's/user = apache/user = nginx/g' /etc/php-fpm.d/www.conf
sed -i 's/group = apache/group = nginx/g' /etc/php-fpm.d/www.conf
systemctl start php-fpm
systemctl enable php-fpm
echo "<?php phpinfo(); ?>" > /usr/share/nginx/html/info.php
systemctl restart nginx
systemctl restart php-fpm
