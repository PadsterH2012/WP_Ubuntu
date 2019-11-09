#!/bin/bash
## Centos Server Setup
# Pre Req - Install Curl - yum install curl
# Run as Root
#
clear
#echo "Please provide your domain name without the www. (e.g. mydomain.com)"
#read -p "Type your domain name, then press [ENTER] : " MY_DOMAIN
##read -p "Type your mysql DB ip address, then press [ENTER] : " MY_DOMAIN
#read -p "Type your mysql DB name, then press [ENTER] : " DB_NAME
#read -p "Type your mysql Username, then press [ENTER] : " DB_USERNAME
##read -p "Type your mysql Password, then press [ENTER] : " DB_PASSWORD
#sudo hostname $MY_DOMAIN
############################################# NGINX
cat << EOF > /etc/yum.repos.d/nginx.repo
[nginx-mainline]
name=nginx mainline repo
baseurl=http://nginx.org/packages/mainline/centos/8/x86_64/
gpgcheck=1
enabled=1
gpgkey=https://nginx.org/keys/nginx_signing.key
EOF
yum install -y nginx --disablerepo=* --enablerepo=nginx-mainline
systemctl start nginx
systemctl status nginx
firewall-cmd --permanent --add-service=http
firewall-cmd --reload
systemctl enable nginx
############################################# MARIADB
yum -y install mariadb mariadb-server
systemctl start mariadb
systemctl enable mariadb
############################################# PHP-FPM
yum -y install php-fpm php-mysqlnd php-cli
