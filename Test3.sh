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
yum -y update
#############################################
wget dl.fedoraproject.org/pub/epel/7/x86_64/Packages/e/epel-release-7-11.noarch.rpm
rpm -ihv epel-release-7-11.noarch.rpm 
yum install htop

