#!/bin/bash

# Update the system
sudo apt update -y && sudo apt upgrade -y

# Install the necessary packages
sudo apt install -y apache2 mariadb-server libapache2-mod-php php-gd php-json php-mysql php-curl php-mbstring php-intl php-imagick php-xml php-zip php-apcu php-gmp php-bcmath openssl

# Enable and start Apache and MariaDB
sudo systemctl enable apache2
sudo systemctl enable mariadb
sudo systemctl start apache2
sudo systemctl start mariadb

sudo mysql_secure_installation
sudo mysql -u root -p -e "
CREATE DATABASE nextcloud;
CREATE USER 'nextclouduser'@'localhost' IDENTIFIED BY 'password';
GRANT ALL PRIVILEGES ON nextcloud.* TO 'nextclouduser'@'localhost';
FLUSH PRIVILEGES;
"

# Download and set up Nextcloud
wget https://download.nextcloud.com/server/releases/latest.tar.bz2
sudo tar -xjvf latest.tar.bz2
sudo cp -r nextcloud /var/www/

# Set permissions
sudo chown -R www-data:www-data /var/www/nextcloud/
sudo chmod -R 755 /var/www/nextcloud/

# Create Apache configuration file for Nextcloud
read -p "Enter the server IP address (e.g., 192.168.1.14): " server_ip
sudo bash -c "cat > /etc/apache2/sites-available/nextcloud.conf <<EOF
<VirtualHost *:80>
    DocumentRoot /var/www/nextcloud/
    ServerName $server_ip

    <Directory /var/www/nextcloud/>
        Require all granted
        AllowOverride All
        Options FollowSymLinks MultiViews

        <IfModule mod_dav.c>
            Dav off
        </IfModule>
    </Directory>

    ErrorLog \${APACHE_LOG_DIR}/nextcloud_error.log
    CustomLog \${APACHE_LOG_DIR}/nextcloud_access.log combined
</VirtualHost>
EOF"

# Configure Apache
sudo a2dissite 000-default.conf
sudo systemctl reload apache2
sudo a2ensite nextcloud.conf
sudo systemctl reload apache2
sudo a2enmod rewrite headers env dir mime setenvif ssl
sudo systemctl restart apache2

# Prompt to complete Nextcloud configuration via web interface
echo "ATTENTION: Complete the Nextcloud configuration via the web interface by going to http://serveripaddress before proceeding."
read -p "Press ENTER to continue once setup is complete..."

# Configure external disk
lsblk
read -p "Enter the external disk device (e.g. /dev/sda1): " external_disk
sudo mkfs.ext4 $external_disk
sudo mkdir /mnt/nextcloud
sudo mount $external_disk /mnt/nextcloud

# Configure fstab for automatic mounting
sudo bash -c "echo '$external_disk /mnt/nextcloud ext4 defaults 0 2' >> /etc/fstab"

# Move Nextcloud data to external disk
sudo mv /var/www/nextcloud/data /mnt/nextcloud/
sudo ln -s /mnt/nextcloud/data /var/www/nextcloud/data
sudo chown -R www-data:www-data /mnt/nextcloud/data

# Enable SSL
sudo mkdir -p /etc/apache2/ssl
sudo openssl req -x509 -nodes -days 365 -newkey rsa:4096 -keyout /etc/apache2/ssl/apache.key -out /etc/apache2/ssl/apache.crt
sudo a2enmod ssl
sudo systemctl restart apache2

# Configure SSL for Apache
sudo bash -c 'sed -i "s|DocumentRoot /var/www/html|DocumentRoot /var/www/nextcloud|g" /etc/apache2/sites-available/default-ssl.conf'
sudo bash -c 'sed -i "s|SSLCertificateFile      /etc/ssl/certs/ssl-cert-snakeoil.pem|SSLCertificateFile /etc/apache2/ssl/apache.crt|g" /etc/apache2/sites-available/default-ssl.conf'
sudo bash -c 'sed -i "s|SSLCertificateKeyFile   /etc/ssl/private/ssl-cert-snakeoil.key|SSLCertificateKeyFile /etc/apache2/ssl/apache.key|g" /etc/apache2/sites-available/default-ssl.conf'

sudo a2ensite default-ssl.conf
sudo systemctl restart apache2

# Enable HTTPS redirection
sudo bash -c 'sed -i "/ErrorLog \${APACHE_LOG_DIR}\/error.log/i RewriteEngine On\nRewriteCond %{HTTPS} off\nRewriteRule ^(.*)$ https://%{HTTP_HOST}\$1 [R=301,L]\n" /etc/apache2/sites-available/000-default.conf'

sudo a2enmod rewrite
sudo systemctl restart apache2

# Configure cron for Nextcloud
sudo bash -c 'echo "*/15 * * * * php -f /var/www/nextcloud/cron.php" >> /var/spool/cron/crontabs/www-data'

# Edit the php.ini file to increase the memory_limit
PHP_VERSION=$(php -r "echo PHP_MAJOR_VERSION.'.'.PHP_MINOR_VERSION;")
PHP_INI="/etc/php/$PHP_VERSION/apache2/php.ini"

sudo sed -i 's/memory_limit = .*/memory_limit = 512M/' $PHP_INI
sudo systemctl restart apache2

echo "Configuration complete. Check that Nextcloud is working properly. Add the external drive to Nextcloud using the External Storage app."
