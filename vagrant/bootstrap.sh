#/bin/bash

# -------------------------------------------
# Yum Update
# -------------------------------------------
yum update -y


# -------------------------------------------
# Disable SELinux
# -------------------------------------------
sed -i 's/SELINUX=.*/SELINUX=disabled/' /etc/sysconfig/selinux
setenforce 0 


# -------------------------------------------
# Basics
# -------------------------------------------
# Basic Tools
yum install -y net-tools wget vim git mlocate sendmail gcc gcc-c++ deltarpm

# Vim Config
VIM_CONFIG=$(cat <<EOF
set nu
set ts=4
syntax on
colorscheme ron
EOF
)
echo "$VIM_CONFIG" > /root/.vimrc
echo "$VIM_CONFIG" > /home/vagrant/.vimrc

# Zsh
yum install -y zsh
wget --no-check-certificate http://install.ohmyz.sh -O - | sh
chsh -s /bin/zsh
chsh -s /bin/zsh vagrant


# -------------------------------------------
# Get custom repos
# -------------------------------------------

# EPEL
yum install -y epel-release

# Remi
wget http://rpms.famillecollet.com/enterprise/remi-release-7.rpm && rpm -i remi-release-7.rpm
yum clean dbcache
rm ./remi-release-7.rpm
# Enables PHP56 repo of remi only
sed -i '18,27s/enabled=0/enabled=1/' /etc/yum.repos.d/remi.repo
sed -i '1,9s/enabled=0/enabled=1/' /etc/yum.repos.d/remi.repo

# MariaDB
# Remove mariadb-libs from default packages
yum remove -y mariadb*

# Add MariaDB repo
MARIA_REPO=$(cat <<EOF
# MariaDB 10.1.1 CentOS repository list - created 2014-10-24 14:32 UTC
# http://mariadb.org/mariadb/repositories/
[mariadb]
name = MariaDB
baseurl = http://yum.mariadb.org/10.1.1/centos7-amd64/
gpgkey=https://yum.mariadb.org/RPM-GPG-KEY-MariaDB
gpgcheck=1
EOF
)
echo "$MARIA_REPO" > /etc/yum.repos.d/MariaDB.repo


# -------------------------------------------
# LAMP Stack
# -------------------------------------------

# Apache
yum install -y httpd httpd-devel httpd-tools

# Use event instead of prefork
sed -i 's/LoadModule mpm_prefork/#LoadModule mpm_prefork/' /etc/httpd/conf.modules.d/00-mpm.conf
sed -i 's/#LoadModule mpm_event/LoadModule mpm_event/' /etc/httpd/conf.modules.d/00-mpm.conf

# MariaDB
yum install -y MariaDB MariaDB-server MariaDB-devel

# PHP
yum install -y php56-php php56-php-cli php56-php-fpm php56-php-bcmath php56-php-devel php56-php-gd php56-php-intl php56-php-xmlrpc php56-php-pdo  php56-php-mysqlnd php56-php-mbstring php56-php-ldap php56-php-mcrypt php56-php-pecl-xdebug php56-php-oauth php56-php-xmlrpc

# Autostart 
systemctl enable httpd  
systemctl enable mysql
systemctl enable php56-php-fpm
systemctl start httpd
systemctl start mysql
systemctl start php56-php-fpm


# -------------------------------------------
# Frontend Tools
# -------------------------------------------

# Ruby
yum install -y ruby ruby-devel rubygems
gem install json_pure

# SASS
gem install sass:3.2.14 compass:0.12.6 compass-blueprint

# LESS
yum install -y less therubyracer
gem install therubyracer less

# NPM
yum install -y npm


# -------------------------------------------
# Directory Setup for Magento
# -------------------------------------------
if [ ! -d "/www" ]; then
	mkdir /www
	if [ ! -d "/www/magento" ]; then
		mkdir /www/magento
		mkdir /www/magento/starter
		mkdir /www/magento/starter/www
		mkdir /www/magento/starter/logs
	fi
fi

chown vagrant:vagrant -R /www

# -------------------------------------------
# Virtual Host
# -------------------------------------------
VHOST_CONFIG=$(cat <<EOF
<VirtualHost *:80>
	DocumentRoot /www/magento/starter/www
	ServerName magento.dev
	ServerAlias www.magento.dev
	UseCanonicalName On

	<Directory "/www/magento/starter/www">
		Require all granted
		AllowOverride All
		Options All
	</Directory>

	ErrorLog /www/magento/starter/logs/error_log
	CustomLog /www/magento/starter/logs/access_log combined

	DirectoryIndex /index.php

	ProxyPass /skin !
	ProxyPass /media !
	ProxyPass /js !
	ProxyPass /robots.txt !
	ProxyPass /sitemap.xml !
	ProxyPassMatch ^(.*\.js)$ !
	ProxyPassMatch ^(.*\.(css|sass|scss|less))$ !
	ProxyPassMatch ^(.*\.(png|gif|jpg|jpeg|svg|ico))$ !
	ProxyPassMatch ^(.*\.(woff|ofm|eot|ttf))$ !
	ProxyPassMatch ^(.*\.csv)$ !
	ProxyPassMatch ^/(.*\.php(/.*)?)$ fcgi://127.0.0.1:9000/www/magento/starter/www/$1
</VirtualHost>
EOF
)
echo "$VHOST_CONFIG" > /etc/httpd/conf.d/magento-starter.conf


# -------------------------------------------
# PHP Setup
# -------------------------------------------

# Make the default fpm pool run as vagrant user for ease of use:q
sed -i 's/user = .*/user = vagrant/' /opt/remi/php56/root/etc/php-fpm.d/www.conf
sed -i 's/group = .*/group = vagrant/' /opt/remi/php56/root/etc/php-fpm.d/www.conf

# Set some higher limits in php.ini
sed -i 's/max_execution_time = .*/max_execution_time = 600/' /opt/remi/php56/root/etc/php.ini
sed -i 's/max_input_time = .*/max_input_time = 300/' /opt/remi/php56/root/etc/php.ini
sed -i 's/memory_limit = .*/memory_limit = 256M/' /opt/remi/php56/root/etc/php.ini
sed -i 's/display_errors = Off/display_errors = On/' /opt/remi/php56/root/etc/php.ini
sed -i 's/post_max_size = .*/post_max_size = 64M/' /opt/remi/php56/root/etc/php.ini
sed -i 's/upload_max_filesize = .*/upload_max_filesize = 64M/' /opt/remi/php56/root/etc/php.ini
sed -i 's/max_file_uploads = .*/max_file_uploads = 100/' /opt/remi/php56/root/etc/php.ini
sed -i 's/;date\.timezone =/date.timezone = Australia\/Sydney/' /opt/remi/php56/root/etc/php.ini

# Restart PHP-FPM
service php56-php-fpm restart


# -------------------------------------------
# MySQL Setup
# -------------------------------------------
mysql -e "DROP DATABASE IF EXISTS magento_starter"
mysql -e "CREATE DATABASE IF NOT EXISTS magento_starter"
mysql -e "GRANT ALL PRIVILEGES ON magento_starter.* TO 'magento_starter'@'localhost' IDENTIFIED BY 'password'"
mysql -e "FLUSH PRIVILEGES"


# -------------------------------------------
# Magento Setup
# -------------------------------------------

# Grab files
if [ -f "/vagrant/source/magento-1.9.0.1.tar.bz2" ]; then
	echo "/vagrant/source/magento-1.9.0.1.tar.bz2 found. Start copy..."
	tar -xvf /vagrant/source/magento-1.9.0.1.tar.bz2 -C /vagrant/source/magento

	echo "moving files to /www/magento/starter/www ..."
	mv /vagrant/source/magento/{*,.*} /www/magento/starter/www

	rm -rf /vagrant/source/magento
	echo "Done"
else
	echo "/vagrant/source/magento-1.9.0.1.tar.bz2 not found"
fi

# Ensure user ownership is correct
chown vagrant:vagrant -R /www

# Install
# Run installer
if [ ! -f "/www/magento/starter/www/app/etc/local.xml" ]; then
cd /www/magento/starter/www
php56 -f install.php -- --license_agreement_accepted yes \
--locale en_US --timezone "Australia/Sydney" --default_currency AUD \
--db_host localhost --db_name magento_starter --db_user magento_starter --db_pass password \
--url "http://127.0.0.1/" --use_rewrites yes \
--use_secure no --secure_base_url "http://127.0.0.1/" --use_secure_admin no \
--skip_url_validation yes \
--admin_lastname Admin --admin_firstname Admin --admin_email "admin@example.com" \
--admin_username admin --admin_password password
fi

