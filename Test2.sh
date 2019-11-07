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
#sudo debconf-set-selections <<< "postfix postfix/mailname string $MY_DOMAIN"
#sudo debconf-set-selections <<< "postfix postfix/main_mailer_type string 'Satellite system'"
sudo cat > /var/cache/debconf/postfix.preseed <<EOF
postfix postfix/chattr  boolean false
postfix postfix/destinations    string  
postfix postfix/mailbox_limit   string  0
postfix postfix/mailname    string  $MY_DOMAIN
postfix postfix/main_mailer_type select Satellite system
postfix postfix/relayhost string 10.0.0.10
postfix postfix/mynetworks  string  127.0.0.0/8 [::ffff:127.0.0.0]/104 [::1]/128
postfix postfix/protocols   select  ipv4
postfix postfix/recipient_delim string  +
postfix postfix/root_address    string  $SERVER_EMAIL
EOF

sudo cat > /etc/postfix/main.cf <<EOF
# See /usr/share/postfix/main.cf.dist for a commented, more complete version
# Debian specific:  Specifying a file name will cause the first
# line of that file to be used as the name.  The Debian default
# is /etc/mailname.
#myorigin = /etc/mailname
smtpd_banner = $myhostname ESMTP $mail_name (Ubuntu)
biff = no
# appending .domain is the MUA's job.
append_dot_mydomain = no
# Uncomment the next line to generate "delayed mail" warnings
#delay_warning_time = 4h
readme_directory = no
# TLS parameters
smtpd_tls_cert_file=/etc/ssl/certs/$MY_DOMAIN.pem
smtpd_tls_key_file=/etc/ssl/private/$MY_DOMAIN.key
smtpd_use_tls=yes
smtpd_tls_session_cache_database = btree:${data_directory}/smtpd_scache
smtp_tls_session_cache_database = btree:${data_directory}/smtp_scache
# See /usr/share/doc/postfix/TLS_README.gz in the postfix-doc package for
# information on enabling SSL in the smtp client.
myhostname = $MY_DOMAIN
alias_maps = hash:/etc/aliases
alias_database = hash:/etc/aliases
myorigin = /etc/mailname
mydestination = 
relayhost = 10.0.0.10
mynetworks = 127.0.0.0/8 [::ffff:127.0.0.0]/104 [::1]/128
mailbox_size_limit = 0
recipient_delimiter = +
inet_interfaces = loopback-only
inet_protocols = ipv4
myorigin = /etc/mailname
mynetworks_style = subnet
smtpd_sasl_auth_enable = yes
smtp_sasl_auth_enable = yes
smtp_sasl_password_maps = hash:/etc/postfix/smtp_sasl_password_map
smtp_sasl_security_options = noanonymous
smtpd_relay_restrictions = permit_mynetworks permit_sasl_authenticated defer_unauth_destination
EOF
sudo debconf-set-selections /var/cache/debconf/postfix.preseed
sudo apt-get -q -y -o DPkg::Options::=--force-confold install postfix
#sudo apt-get install -y postfix
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
sudo add-apt-repository ppa:ondrej/apache2 -y
sudo apt-get update
sudo apt install php7.3 -y
sudo apt install imagemagick php7.3-common php7.3-cli php7.3-bcmath php-imagick php7.3-mysql php7.3-bz2 php7.3-curl php7.3-gd php7.3-intl php7.3-json php7.3-mbstring php7.3-readline php7.3-xml php7.3-zip php7.3-fpm -y
#sudo apt install php php-gd php-imagick php-curl php-mysql -y
sudo a2dismod php7.2
sudo a2enmod php7.3
#############################################
sudo perl -pi -e "s/max_execution_time = 30/max_execution_time = 6000/g" /etc/php/7.3/cli/php.ini
sudo perl -pi -e "s/memory_limit = -1/memory_limit = 512M/g" /etc/php/7.3/cli/php.ini
sudo perl -pi -e "s/upload_max_filesize = .*/upload_max_filesize = 1024M/g" /etc/php/7.3/cli/php.ini
sudo perl -pi -e "s/;max_input_vars = 1000/max_input_vars = 2000/g" /etc/php/7.3/cli/php.ini
##
sudo perl -pi -e "s/max_execution_time = 30/max_execution_time = 6000/g" /etc/php/7.3/apache2/php.ini
sudo perl -pi -e "s/memory_limit = -1/memory_limit = 512M/g" /etc/php/7.3/apache2/php.ini
sudo perl -pi -e "s/upload_max_filesize = .*/upload_max_filesize = 1024M/g" /etc/php/7.3/apache2/php.ini
sudo perl -pi -e "s/;max_input_vars = 1000/max_input_vars = 2000/g" /etc/php/7.3/apache2/php.ini
#############################################
echo -n "[In progress] Detect PHP version ..."
VER_PHP="$(command php --version 2>'/dev/null' \
    | command head -n 1 \
    | command cut --characters=5-7)"
sleep 3s
echo -e "\r\e[0;32m[OK]\e[0m Detect PHP version  : $VER_PHP   "
sudo wget http://downloads3.ioncube.com/loader_downloads/ioncube_loaders_lin_x86-64.tar.gz
sudo tar xzf ioncube_loaders_lin_x86-64.tar.gz -C /usr/local
echo -n "[In progress] Add IonCube to PHP ..."
# echo "zend_extension=/usr/local/ioncube/ioncube_loader_lin_${VER_PHP}.so" > /etc/php5/conf.d/ioncube.ini
sudo sed -i "1izend_extension=/usr/local/ioncube/ioncube_loader_lin_${VER_PHP}.so" /etc/php/7.3/cli/php.ini
sudo sed -i "1izend_extension=/usr/local/ioncube/ioncube_loader_lin_${VER_PHP}.so" /etc/php/7.3/apache2/php.ini
sudo rm ioncube_loaders_lin_x86-64.tar.gz
sleep 3s
echo -e "\r\e[0;32m[OK]\e[0m Add IonCube to PHP"
#############################################

sudo openssl req -new -newkey rsa:4096 -days 365 -nodes -x509 \
   -subj "/C=GB/ST=Hampshire/L=Ragthorn/O=ITDept/CN=$MY_DOMAIN" \
    -keyout $MY_DOMAIN.key  -out $MY_DOMAIN.crt
sudo cat $MY_DOMAIN.crt $MY_DOMAIN.key > $MY_DOMAIN.pem
sudo mv $MY_DOMAIN.pem /etc/ssl/certs/
sudo mv $MY_DOMAIN.* /etc/ssl/private/

#############################################
sudo service apache2 restart
#############################################
sudo wget -qO- http://www.webmin.com/jcameron-key.asc | sudo apt-key add
sudo add-apt-repository "deb http://download.webmin.com/download/repository sarge contrib"
sudo apt-get update && apt get upgrade -y
sudo apt install webmin -y
#sudo perl -pi -e "s/max_execution_time = 30/max_execution_time = 6000/g" /etc/webmin/phpini/config
#sudo perl -pi -e "s/memory_limit = -1/memory_limit = 512M/g" /etc/webmin/phpini/config
sudo perl -pi -e "s/php5/php\/7.3/g" /etc/webmin/phpini/config
#############################################
sudo apt-get update && apt get upgrade -y
#############################################
sudo cp /etc/apache2/sites-available/000-default.conf /etc/apache2/sites-available/wordpress.conf
sudo cp /etc/apache2/sites-available/default-ssl.conf /etc/apache2/sites-available/default-ssl.conf.bak
sudo sed -i '/^/d' /etc/apache2/sites-available/wordpress.conf
echo "ServerName localhost

<VirtualHost *:80>
    UseCanonicalName Off
    ServerAdmin  webmaster@localhost
    DocumentRoot /var/www/wordpress
</VirtualHost>

<VirtualHost *:443>
    SSLEngine on
    SSLCertificateFile /etc/apache2/ssl/private/$MY_DOMAIN.crt
    SSLCertificateKeyFile /etc/apache2/ssl/private/$MY_DOMAIN.key
    ServerAdmin  webmaster@localhost
    DocumentRoot /var/www/wordpress
</VirtualHost>

<Directory /var/www/wordpress>
    Options +FollowSymLinks
    Options -Indexes
    AllowOverride All
    order allow,deny
    allow from all
</Directory>" | sudo tee /etc/apache2/sites-available/wordpress.conf

#MY_DOMAIN="ct3.collectiontwenty.com"
SSLCertificateFile="/etc/ssl/certs/$MY_DOMAIN.pem"

echo "
<IfModule mod_ssl.c>

# Pseudo Random Number Generator (PRNG):
# Configure one or more sources to seed the PRNG of the SSL library.
# The seed data should be of good random quality.
# WARNING! On some platforms /dev/random blocks if not enough entropy
# is available. This means you then cannot use the /dev/random device
# because it would lead to very long connection times (as long as
# it requires to make more entropy available). But usually those
# platforms additionally provide a /dev/urandom device which doesn't
# block. So, if available, use this one instead. Read the mod_ssl User
# Manual for more details.
#
SSLRandomSeed startup builtin
SSLRandomSeed startup file:/dev/urandom 512
SSLRandomSeed connect builtin
SSLRandomSeed connect file:/dev/urandom 512

##
##  SSL Global Context
##
##  All SSL configuration in this context applies both to
##  the main server and all SSL-enabled virtual hosts.
##

#
#   Some MIME-types for downloading Certificates and CRLs
#
AddType application/x-x509-ca-cert .crt
AddType application/x-pkcs7-crl .crl

#   Pass Phrase Dialog:
#   Configure the pass phrase gathering process.
#   The filtering dialog program (builtin is a internal
#   terminal dialog) has to provide the pass phrase on stdout.
SSLPassPhraseDialog builtin

#   Inter-Process Session Cache:
#   Configure the SSL Session Cache: First the mechanism 
#   to use and second the expiring timeout (in seconds).
#   (The mechanism dbm has known memory leaks and should not be used).
#SSLSessionCache    dbm:${APACHE_RUN_DIR}/ssl_scache
SSLSessionCache shmcb:${APACHE_RUN_DIR}/ssl_scache(512000)
SSLSessionCacheTimeout  300

#   Semaphore:
#   Configure the path to the mutual exclusion semaphore the
#   SSL engine uses internally for inter-process synchronization. 
#   (Disabled by default, the global Mutex directive consolidates by default
#   this)
#Mutex file:${APACHE_LOCK_DIR}/ssl_mutex ssl-cache


#   SSL Cipher Suite:
#   List the ciphers that the client is permitted to negotiate. See the
#   ciphers(1) man page from the openssl package for list of all available
#   options.
#   Enable only secure ciphers:
SSLCipherSuite ECDHE-ECDSA-AES128-GCM-SHA256:ECDHE-ECDSA-AES256-GCM-SHA384:ECDHE-ECDSA-AES128-SHA:ECDHE-ECDSA-AES256-SHA:ECDHE-ECDSA-AES128-SHA256:ECDHE-ECDSA-AES256-SHA384:ECDHE-RSA-AES128-GCM-SHA256:ECDHE-RSA-AES256-GCM-SHA384:ECDHE-RSA-AES128-SHA:ECDHE-RSA-AES256-SHA:ECDHE-RSA-AES128-SHA256:ECDHE-RSA-AES256-SHA384:DHE-RSA-AES128-GCM-SHA256:DHE-RSA-AES256-GCM-SHA384:DHE-RSA-AES128-SHA:DHE-RSA-AES256-SHA:DHE-RSA-AES128-SHA256:DHE-RSA-AES256-SHA256

# SSL server cipher order preference:
# Use server priorities for cipher algorithm choice.
# Clients may prefer lower grade encryption.  You should enable this
# option if you want to enforce stronger encryption, and can afford
# the CPU cost, and did not override SSLCipherSuite in a way that puts
# insecure ciphers first.
# Default: Off
SSLHonorCipherOrder on

#   The protocols to enable.
#   Available values: all, SSLv3, TLSv1, TLSv1.1, TLSv1.2
#   SSL v2  is no longer supported
SSLProtocol all -SSLv3

#   Allow insecure renegotiation with clients which do not yet support the
#   secure renegotiation protocol. Default: Off
#SSLInsecureRenegotiation on

#   Whether to forbid non-SNI clients to access name based virtual hosts.
#   Default: Off
#SSLStrictSNIVHostCheck On

#   Disable ssl compression
SSLCompression off
#   Default certificate file
SSLCertificateFile $SSLCertificateFile
</IfModule>
# vim: syntax=apache ts=4 sw=4 sts=4 sr noet
" | sudo tee /etc/apache2/mods-available/ssl.conf
    

sudo rm /etc/apache2/sites-enabled/000-default.conf
sudo a2enmod ssl
sudo a2ensite wordpress.conf
#sudo a2ensite default-ssl.conf
sudo systemctl reload apache2
#####################################################
cd /tmp && wget https://wordpress.org/latest.tar.gz
tar -xvf latest.tar.gz
sudo cp -R wordpress /var/www/


sudo mkdir /var/www/wordpress/wp-content/uploads


sudo chown www-data:www-data -R /var/www/wordpress
sudo find /var/www/wordpress/ -type d -exec chmod 755 {} \;
sudo find /var/www/wordpress/ -type f -exec chmod 644 {} \;
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
