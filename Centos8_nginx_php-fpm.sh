#!/bin/bash
## Centos Server Setup
# Pre Req - Install Curl - yum install curl
# Run as Root
#
clear
#echo "Please provide your domain name without the www. (e.g. mydomain.com)"
#read -p "Type your domain name, then press [ENTER] : " MY_DOMAIN
MY_DOMAIN="test.com"
#read -p "Type your site name, then press [ENTER] : " MY_SITE
MY_SITE="test"
##read -p "Type your mysql DB ip address, then press [ENTER] : " MY_DOMAIN
#read -p "Type your mysql DB name, then press [ENTER] : " DB_NAME
DB_NAME="testdb"
#read -p "Type your mysql Username, then press [ENTER] : " DB_USERNAME
DB_USERNAME="testdbuser"
#read -p "Type your mysql Password, then press [ENTER] : " DB_PASSWORD
hostname $MY_DOMAIN
############################################# NGINX
#yum -y install nginx
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
#firewall-cmd --permanent --add-service=https
#systemctl reload firewalld
#chown nginx:nginx /usr/share/nginx/html -R
#systemctl enable nginx
############################################# MARIADB
yum -y install mariadb mariadb-server expect
systemctl start mariadb
systemctl enable mariadb
#mysql_secure_installation
userpass=$(openssl rand -base64 29 | tr -d "=+/" | cut -c1-25)
mysqlrootpassword=$(openssl rand -base64 29 | tr -d "=+/" | cut -c1-25)
MYSQL=""
SECURE_MYSQL=$(expect -c "
set timeout 10
spawn mysql_secure_installation
#expect \"Enter current password for root (enter for none):\"
send \"$MYSQL\r\"
#expect \Set root password? [Y/n]\"
send \"Y\r\"
#expect \New password:\"
send \"$mysqlrootpassword\r\"
#expect \Re-enter new password:\"
send \"$mysqlrootpassword\r\"
#expect \"Remove anonymous users?\"
send \"y\r\"
#expect \"Disallow root login remotely?\"
send \"y\r\"
#expect \"Remove test database and access to it?\"
send \"y\r\"
#expect \"Reload privilege tables now?\"
send \"y\r\"
expect eof
")

echo "$SECURE_MYSQL"
echo $mysqlrootpassword
echo "CREATE DATABASE $DB_NAME;" | mysql -u root -p$mysqlrootpassword
echo "CREATE USER '$DB_USERNAME'@'localhost' IDENTIFIED BY '$userpass';" | mysql -u root -p$mysqlrootpassword
echo "GRANT ALL PRIVILEGES ON $DB_NAME.* TO '$DB_USERNAME'@'localhost';" | mysql -u root -p$mysqlrootpassword
echo "FLUSH PRIVILEGES;" | mysql -u root -p$mysqlrootpassword
############################################# PHP-FPM
yum -y install php-fpm php-mysqlnd php-cli
sed -i 's/;cgi.fix_pathinfo=1/cgi.fix_pathinfo=0/g' /etc/php.ini
sed -i 's/listen = \/run\/php-fpm\/www.sock/listen = 127.0.0.1:9000/g' /etc/php.ini
sed -i 's/user = apache/user = nginx/g' /etc/php-fpm.d/www.conf
sed -i 's/group = apache/group = nginx/g' /etc/php-fpm.d/www.conf
systemctl start php-fpm
systemctl enable php-fpm
#cat > /etc/nginx/conf.d/$MY_SITE.conf <<EOF
#server {
#   server_name $MY_SITE;
#   root /usr/share/nginx/html/$MY_SITE;
#
#
#   location / {
#       index index.html index.htm index.php;
#   }
#
#   location ~ \.php$ {
#      include /etc/nginx/fastcgi_params;
#      fastcgi_pass 127.0.0.1:9000;
#      fastcgi_index index.php;
#      fastcgi_param SCRIPT_FILENAME $document_root$fastcgi_script_name;
#   }
#}
#EOF
echo "<?php phpinfo(); ?>" > /usr/share/nginx/html/$MY_SITE/index.php
systemctl restart nginx
systemctl restart php-fpm
LOCAL_IP=$(ip -f inet -o addr show ens160|cut -d\  -f 7 | cut -d/ -f 1)
hostname $MY_DOMAIN
echo " $LOCAL_IP  $MY_DOMAIN" >> /etc/hosts
##################################################
touch /etc/nginx/conf.d/$MY_SITE.conf
cat > /etc/nginx/conf.d/$MY_SITE.conf <<EOF
server {
	listen 80; 
	server_name $MY_DOMAIN;

	root /sites/$MY_SITE/public_html/;

	index index.html index.php;

	access_log /sites/$MY_SITE/logs/access.log;
	error_log /sites/$MY_SITE/logs/error.log;

	# Don't allow pages to be rendered in an iframe on external domains.
	add_header X-Frame-Options "SAMEORIGIN";

	# MIME sniffing prevention
	add_header X-Content-Type-Options "nosniff";

	# Enable cross-site scripting filter in supported browsers.
	add_header X-Xss-Protection "1; mode=block";

	# Prevent access to hidden files
	location ~* /\.(?!well-known\/) {
		deny all;
	}

	# Prevent access to certain file extensions
	location ~\.(ini|log|conf)$ {
		deny all;
	}
        
        # Enable WordPress Permananent Links
	location / {
		try_files $uri $uri/ /index.php?$args;
	}

	location ~ \.php$ {
        include /etc/nginx/fastcgi_params;
        fastcgi_pass 127.0.0.1:9000;
        fastcgi_index index.php;
        fastcgi_param SCRIPT_FILENAME $document_root$fastcgi_script_name;
	}

}
EOF
mkdir -p /sites/$MY_SITE/public_html/
mkdir -p /sites/$MY_SITE/logs/
nginx -t
##################################################
echo
echo
echo
echo
echo "###############################################"
echo
echo "Database Name: $DB_NAME"
echo
echo "Username: $DB_USERNAME"
echo "Password: $userpass"
echo
echo "IP Address: $LOCAL_IP"
echo
echo "Your MySQL ROOT Password is: $mysqlrootpassword"
echo
echo "###############################################"
