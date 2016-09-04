#!/bin/bash

#############
# Note: I did not create the majority of this file. It was pieced together by 
#		various developers over a period of time. I simply modified it to spin
#		up a LAMP stack quickly.

apache_config_file="/etc/apache2/envvars"
apache_vhost_file="/etc/apache2/sites-available/vagrant_vhost.conf"
php_config_file="/etc/php5/apache2/php.ini"
xdebug_config_file="/etc/php5/mods-available/xdebug.ini"
mysql_config_file="/etc/mysql/my.cnf"
default_apache_index="/var/www/html/index.html"

# This function is called at the very bottom of the file
main() {
	update_setup

	if [[ -e /var/lock/vagrant-provision ]]; then
	    cat 1>&2 << EOD
################################################################################
# To re-run full provisioning, delete /var/lock/vagrant-provision and run
#
#    $ vagrant provision
#
# From the host machine
################################################################################
EOD
	    exit
	fi

	network_setup
	tools_setup
	apache_setup
	mysql_setup
	phpmyadmin_setup
	php_setup
	
	# Install composer in the live code dir.
	curl -sS https://getcomposer.org/installer | php -- --install-dir=/vagrant/html
	
	# Add the /home/.aws/credentials file 
	mkdir /home/.aws
	cat << EOF > /home/.aws/credentials
[ses]
aws_access_key_id = AWS_SES_ACCESS_KEY_ID
aws_secret_access_key = AWS_SECRET_ACCESS_KEY
region = us-east-1

[s3]
aws_access_key_id = AWS_S3_ACCESS_KEY_ID
aws_secret_access_key = AWS_S3_SECRET_ACCESS_KEY
EOF

	touch /var/lock/vagrant-provision
}

update_setup() {
	# Update the server
	apt-get -y update
	apt-get -y upgrade
}

network_setup() {
	IPADDR=$(/sbin/ifconfig eth0 | awk '/inet / { print $2 }' | sed 's/addr://')
	sed -i "s/^${IPADDR}.*//" /etc/hosts
	echo ${IPADDR} ubuntu.localhost >> /etc/hosts			# Just to quiet down some error messages
}

tools_setup() {
	# Install simple tools. More to come later.
	apt-get -y install build-essential binutils-doc git
}

apache_setup() {
	# Install Apache
	apt-get -y install apache2

	sed -i "s/^\(.*\)www-data/\1vagrant/g" ${apache_config_file}
	
	# Change ownership to vagrant.
	chown -R vagrant:vagrant /var/log/apache2

	# Changes your working apache directory to /vagrant/html and enables the rewrite mod. 
	cat << EOF > ${apache_vhost_file}
<VirtualHost *:80>
        ServerAdmin webmaster@localhost
        DocumentRoot /vagrant/html
        LogLevel debug

        ErrorLog /var/log/apache2/error.log
        CustomLog /var/log/apache2/access.log combined

        <Directory /vagrant/html>
            AllowOverride All
            Require all granted
        </Directory>
</VirtualHost>
EOF

	# Disable old config; enable new config.
	a2dissite 000-default
	a2ensite vagrant_vhost

	# Mod rewrite. Important for pretty (vanity) URL's
	a2enmod rewrite

	service apache2 reload
	update-rc.d apache2 enable
}

php_setup() {
	# Added curl, libcurl3 and libcurl3-dev, mysql, sqlite and xdebug
	apt-get -y install curl libcurl3 libcurl3-dev php5 php5-curl php5-mysql php5-sqlite php5-xdebug

	sed -i "s/display_startup_errors = Off/display_startup_errors = On/g" ${php_config_file}
	sed -i "s/display_errors = Off/display_errors = On/g" ${php_config_file}

	# Setup xdebug. Edit the remote_host as needed.
	cat << EOF > ${xdebug_config_file}
zend_extension=xdebug.so
xdebug.remote_enable=1
xdebug.remote_connect_back=1
xdebug.remote_port=9000
xdebug.remote_host=10.0.2.2
EOF
	service apache2 reload
	
	# A lil python. mhm. 
	apt-get update && apt-get -y install python-software-properties
	
	# PHP 5.6. 
	add-apt-repository ppa:ondrej/php5-5.6
	apt-get update && apt-get upgrade
	apt-get -y install php5
	
	# Enable the PHPmcrypt library.
	php5enmod mcrypt
	
	service apache2 reload
}

mysql_setup() {
	# Install MySQL
	# Your default user is "root"
	# Your default password is "root"
	echo -e "\n--- Install MySQL specific packages and settings ---\n"
	echo "mysql-server mysql-server/root_password password root" | debconf-set-selections
	echo "mysql-server mysql-server/root_password_again password root" | debconf-set-selections
	
	# MySQL 5.6
	apt-get -y install mysql-server-5.6
	
	sed -i "s/bind-address\s*=\s*127.0.0.1/bind-address = 0.0.0.0/" ${mysql_config_file}

	# Allow root access from any host
	echo "GRANT ALL PRIVILEGES ON *.* TO 'root'@'%' IDENTIFIED BY 'root' WITH GRANT OPTION" | mysql -u root --password=root
	echo "GRANT PROXY ON ''@'' TO 'root'@'%' WITH GRANT OPTION" | mysql -u root --password=root

	# Look for any .sql files in the /vagrant/sql-setup directory. Files are loaded in alphabetical order.
	if [ -d "/vagrant/sql-setup" ]; then
		echo "Executing all SQL files in /vagrant/provision-sql folder ..."
		echo "-------------------------------------"
		for sql_file in /vagrant/provision-sql/*.sql
		do
			echo "EXECUTING $sql_file..."
	  		time mysql -u root --password=root < $sql_file
	  		echo "FINISHED $sql_file"
	  		echo ""
		done
	fi

	service mysql restart
	update-rc.d apache2 enable
	
}

phpmyadmin_setup() {
	# install phpmyadmin and give password(s) to installer
	# for simplicity I'm using the same password for mysql and phpmyadmin
	echo "phpmyadmin phpmyadmin/dbconfig-install boolean true" | debconf-set-selections
	echo "phpmyadmin phpmyadmin/app-password-confirm password root" | debconf-set-selections
	echo "phpmyadmin phpmyadmin/mysql/admin-pass password root" | debconf-set-selections
	echo "phpmyadmin phpmyadmin/mysql/app-pass password root" | debconf-set-selections
	echo "phpmyadmin phpmyadmin/reconfigure-webserver multiselect apache2" | debconf-set-selections
	echo "phpmyadmin phpmyadmin/reconfigure-webserver multiselect apache2" | debconf-set-selections
	apt-get -y install phpmyadmin
	
	service apache2 restart
}

main
exit 0
