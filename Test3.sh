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
sed -i 's/;cgi.fix_pathinfo=1/cgi.fix_pathinfo=0/g' /etc/php.ini
systemctl start php-fpm
systemctl enable php-fpm
touch /etc/nginx/conf.d/$MY_SITE.conf
cat << EOF > /etc/nginx/conf.d/$MY_SITE.conf
server {
   server_name $MY_DOMAIN;
   root /usr/share/nginx/html/$MY_SITE;

   location / {
       index index.html index.htm index.php;
   }

   location ~ \.php$ {
      include /etc/nginx/fastcgi_params;
      fastcgi_pass 127.0.0.1:9000;
      fastcgi_index index.php;
      fastcgi_param SCRIPT_FILENAME $document_root$fastcgi_script_name;
   }
}
EOF
mkdir /usr/share/nginx/html/$MY_SITE
echo "<?php phpinfo(); ?>" > /usr/share/nginx/html/$MY_SITE/index.php
systemctl restart nginx
systemctl restart php-fpm
