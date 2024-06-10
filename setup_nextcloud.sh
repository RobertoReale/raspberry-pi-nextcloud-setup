#!/bin/bash

# Define variables
read -p "Enter the database name (e.g., nextcloud): " DB_NAME
read -p "Enter the database user (e.g., nextclouduser): " DB_USER
read -s -p "Enter the database password (e.g., password): " DB_PASSWORD
read -p "Enter the Nextcloud installation directory (e.g., /var/www/nextcloud): " NEXTCLOUD_DIR
read -p "Enter the PHP memory limit (e.g., 512M): " MEMORY_LIMIT
read -p "Enter the PHP upload max filesize and the PHP post max size (e.g., 16G): " UPLOAD_MAX_FILESIZE
read -p "Enter the PHP max execution time and the PHP max input time (in seconds, e.g., 3600): " MAX_INPUT_TIME
read -p "Enter the upload chunk size in bytes (e.g., 20MB): " CHUNK_SIZE

# Update and upgrade the system
echo "Updating system..."
sudo apt update -y && sudo apt upgrade -y

# Install Apache, MariaDB, and PHP
echo "Installing Apache, MariaDB, and PHP..."
sudo apt install apache2 mariadb-server libapache2-mod-php php-gd php-mysql php-curl php-mbstring php-intl php-gmp php-bcmath php-xml php-imagick php-zip -y

# Enable and start Apache and MariaDB
sudo systemctl enable apache2
sudo systemctl enable mariadb
sudo systemctl start apache2
sudo systemctl start mariadb

# Secure MariaDB installation
echo "Securing MariaDB..."
sudo mysql_secure_installation

# Create database and user for Nextcloud
echo "Configuring MariaDB for Nextcloud..."
sudo mysql -u root -p <<EOF
CREATE USER '$DB_USER'@'localhost' IDENTIFIED BY '$DB_PASSWORD';
CREATE DATABASE $DB_NAME CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci;
GRANT ALL PRIVILEGES ON $DB_NAME.* TO '$DB_USER'@'localhost';
FLUSH PRIVILEGES;
EXIT;
EOF

# Download Nextcloud
echo "Downloading Nextcloud..."
wget https://download.nextcloud.com/server/releases/latest.tar.bz2

# Extract and move Nextcloud
echo "Extracting and moving Nextcloud..."
tar -xjvf latest.tar.bz2
sudo mv nextcloud $NEXTCLOUD_DIR

# Set permissions
echo "Setting permissions..."
sudo chown -R www-data:www-data $NEXTCLOUD_DIR
sudo chmod -R 755 $NEXTCLOUD_DIR

# Configure Apache
echo "Configuring Apache..."
sudo bash -c "cat > /etc/apache2/sites-available/nextcloud.conf <<EOF
Alias /nextcloud \"$NEXTCLOUD_DIR/\"

<Directory $NEXTCLOUD_DIR/>
  Require all granted
  AllowOverride All
  Options FollowSymLinks MultiViews

  <IfModule mod_dav.c>
    Dav off
  </IfModule>
</Directory>
EOF"

# Enable SSL and necessary modules
sudo a2ensite nextcloud.conf
sudo a2enmod rewrite headers env dir mime ssl
sudo a2enmod ssl
sudo a2ensite default-ssl

# Enable HTTPS redirection
sudo bash -c 'sed -i "/ErrorLog \${APACHE_LOG_DIR}\/error.log/i RewriteEngine On\nRewriteCond %{HTTPS} off\nRewriteRule ^(.*)$ https://%{HTTP_HOST}\$1 [R=301,L]\n" /etc/apache2/sites-available/000-default.conf'
sudo bash -c 'sed -i "/ErrorLog \${APACHE_LOG_DIR}\/error.log/i RewriteEngine On\nRewriteCond %{HTTPS} off\nRewriteRule ^(.*)$ https://%{HTTP_HOST}\$1 [R=301,L]\n" /etc/apache2/sites-available/nextcloud.conf'


# Disable the default Apache site
sudo a2dissite 000-default.conf

# Restart Apache
echo "Restarting Apache..."
sudo systemctl restart apache2

# Complete installation via web interface
echo "Installation complete. Please navigate to your Raspberry Pi's IP address followed by /nextcloud to complete the setup via the web interface."
read -p "Press ENTER to continue once setup is complete..."

# Set up cron job for Nextcloud
echo "Setting up cron job..."
sudo crontab -u www-data -e <<EOF
*/15 * * * * php -f $NEXTCLOUD_DIR/cron.php
EOF

# PHP configuration tweaks
echo "Tweaking PHP configuration for PHP $PHP_VERSION..."
sudo bash -c "cat >> /etc/php/$PHP_VERSION/apache2/php.ini <<EOF
memory_limit = $MEMORY_LIMIT
upload_max_filesize = $UPLOAD_MAX_FILESIZE
post_max_size = $UPLOAD_MAX_FILESIZE
max_input_time = $MAX_INPUT_TIME
max_execution_time = $MAX_INPUT_TIME
EOF"

# Adjust the upload chunk size using occ
sudo -u www-data php $NEXTCLOUD_DIR/occ config:system:set file_chunking.split_size --value=$CHUNK_SIZE

# Restart Apache to apply PHP changes
sudo systemctl restart apache2

# Configure firewall
echo "Configuring firewall..."
sudo apt install ufw -y
sudo ufw allow 80/tcp
sudo ufw allow 443/tcp
sudo ufw enable

# Additional Security and Performance Tweaks
echo "Applying additional security and performance tweaks..."

# Modify security.conf
sudo sed -i '/^ServerTokens/s/.*/ServerTokens Prod/' /etc/apache2/conf-available/security.conf
sudo sed -i '/^ServerSignature/s/.*/ServerSignature Off/' /etc/apache2/conf-available/security.conf
sudo sed -i '/^TraceEnable/s/.*/TraceEnable Off/' /etc/apache2/conf-available/security.conf

# Configure external disk
lsblk
read -p "Enter the external disk device (e.g. /dev/sda1): " external_disk
sudo mkfs.ext4 $external_disk
sudo mkdir /mnt/external_disk1
sudo mount $external_disk /mnt/external_disk1

# Set Permissions
sudo chown -R www-data:www-data /mnt/external_disk1
sudo chmod -R 755 /mnt/external_disk1

# Configure fstab for automatic mounting
sudo bash -c "echo '$external_disk /mnt/external_disk1 ext4 defaults 0 2' >> /etc/fstab"

echo "Configuration complete. Check that Nextcloud is working properly. Add the external drive to Nextcloud using the External Storage app."
