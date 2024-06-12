#!/bin/bash

# Error Handling
set -euo pipefail

# Trap to catch errors and perform cleanup tasks
cleanup() {
    echo "An error occurred. Cleaning up..."
    # Add cleanup tasks here if needed
}
trap 'cleanup' ERR

# Validate input function
validate_input() {
    if [[ ! $1 =~ ^[0-9]+$ ]]; then
        echo "Invalid input. Please enter a valid number."
        exit 1
    fi
}

# Function to prompt for inputs and validate them
prompt_and_validate() {
    local prompt_message=$1
    local var_name=$2
    local hide_input=${3:-false}
    if [[ $hide_input == "true" ]]; then
        read -s -p "$prompt_message" $var_name
        echo
    else
        read -p "$prompt_message" $var_name
    fi
    if [[ -z ${!var_name} ]]; then
        echo "Invalid input. Please provide a value."
        exit 1
    fi
}

# Define variables
prompt_and_validate "Enter the server IP address (e.g., 192.168.1.14): " SERVER_IP
prompt_and_validate "Enter the database name (e.g., nextcloud): " DB_NAME
prompt_and_validate "Enter the database user (e.g., nextclouduser): " DB_USER
prompt_and_validate "Enter the database password (e.g., password): " DB_PASSWORD true
echo
prompt_and_validate "Enter the Nextcloud installation directory (e.g., /var/www/nextcloud): " NEXTCLOUD_DIR
prompt_and_validate "Enter the PHP memory limit (e.g., 512M): " MEMORY_LIMIT
prompt_and_validate "Enter the PHP upload max filesize and the PHP post max size (e.g., 16G): " UPLOAD_MAX_FILESIZE
prompt_and_validate "Enter the PHP max execution time and the PHP max input time (in seconds, e.g., 3600): " MAX_INPUT_TIME
prompt_and_validate "Enter the upload chunk size in bytes (e.g., 20MB): " CHUNK_SIZE

# Update and upgrade the system
echo "Updating system..."
sudo apt update -y && sudo apt upgrade -y

# Install Apache, MariaDB, and PHP
echo "Installing Apache, MariaDB, and PHP..."
sudo apt install apache2 mariadb-server libapache2-mod-php php-gd php-mysql php-curl php-mbstring php-intl php-gmp php-bcmath php-xml php-imagick php-zip wget ufw -y

# Enable and start Apache and MariaDB
echo "Enabling and starting Apache and MariaDB..."
sudo systemctl enable apache2
sudo systemctl enable mariadb
sudo systemctl start apache2
sudo systemctl start mariadb

# Secure MariaDB installation
echo "Securing MariaDB..."
sudo mysql_secure_installation

# Create database and user for Nextcloud if not exists
echo "Configuring MariaDB for Nextcloud..."
sudo mysql -u root -p"$DB_PASSWORD" <<EOF
CREATE DATABASE IF NOT EXISTS $DB_NAME CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci;
CREATE USER IF NOT EXISTS '$DB_USER'@'localhost' IDENTIFIED BY '$DB_PASSWORD';
GRANT ALL PRIVILEGES ON $DB_NAME.* TO '$DB_USER'@'localhost';
FLUSH PRIVILEGES;
EOF

# Download Nextcloud
echo "Downloading Nextcloud..."
wget https://download.nextcloud.com/server/releases/latest.tar.bz2

# Check if download succeeded
if [ $? -ne 0 ]; then
    echo "Failed to download Nextcloud. Exiting."
    exit 1
fi

# Extract and move Nextcloud
echo "Extracting and moving Nextcloud..."
sudo tar -xjvf latest.tar.bz2
sudo mv nextcloud "$NEXTCLOUD_DIR"

# Set permissions
echo "Setting permissions..."
sudo chown -R www-data:www-data "$NEXTCLOUD_DIR"
sudo chmod -R 755 "$NEXTCLOUD_DIR"

# Enable necessary Apache modules for SSL
echo "Enabling necessary Apache modules..."
sudo a2enmod ssl
sudo a2enmod headers

# Create Apache configuration for Nextcloud with SSL
echo "Configuring Apache for Nextcloud..."
sudo bash -c "cat > /etc/apache2/sites-available/nextcloud.conf <<EOF
<VirtualHost *:80>
  ServerName $SERVER_IP
  Redirect permanent / https://$SERVER_IP/
</VirtualHost>

<VirtualHost *:443>
  DocumentRoot $NEXTCLOUD_DIR/
  ServerName $SERVER_IP

  <Directory $NEXTCLOUD_DIR/>
    Require all granted
    AllowOverride All
    Options FollowSymLinks MultiViews

    <IfModule mod_dav.c>
      Dav off
    </IfModule>
  </Directory>

  SSLEngine on
  SSLCertificateFile /etc/ssl/certs/ssl-cert-snakeoil.pem
  SSLCertificateKeyFile /etc/ssl/private/ssl-cert-snakeoil.key

  <IfModule mod_headers.c>
    Header always set Strict-Transport-Security "max-age=15552000; includeSubDomains"
  </IfModule>
</VirtualHost>
EOF"

# Enable the Nextcloud and SSL site and disable the default site
sudo a2ensite nextcloud.conf
sudo a2ensite default-ssl.conf
sudo a2dissite 000-default.conf

# Complete installation via web interface
echo "Installation complete. Please navigate to your Raspberry Pi's IP address (http://$SERVER_IP) to complete the setup via the web interface."
read -p "Press ENTER to continue once setup is complete..."

# Set up cron job for Nextcloud
echo "Setting up cron job..."
(crontab -u www-data -l; echo "*/15 * * * * php -f $NEXTCLOUD_DIR/cron.php") | crontab -u www-data -

# PHP configuration tweaks
echo "Tweaking PHP configuration..."
PHP_VERSION=$(php -r 'echo PHP_MAJOR_VERSION.".".PHP_MINOR_VERSION;')
sudo bash -c "cat >> /etc/php/$PHP_VERSION/apache2/php.ini <<EOF
memory_limit = $MEMORY_LIMIT
upload_max_filesize = $UPLOAD_MAX_FILESIZE
post_max_size = $UPLOAD_MAX_FILESIZE
max_input_time = $MAX_INPUT_TIME
max_execution_time = $MAX_INPUT_TIME
EOF"

# Adjust the upload chunk size using occ
sudo -u www-data php "$NEXTCLOUD_DIR/occ" config:system:set file_chunking.split_size --value=$CHUNK_SIZE

# Restart Apache to apply PHP changes
sudo systemctl restart apache2

# Configure firewall if not enabled
echo "Configuring firewall..."
sudo ufw status | grep -q inactive && sudo ufw enable
sudo ufw allow 80/tcp
sudo ufw allow 443/tcp

# Additional Security and Performance Tweaks
echo "Applying additional security and performance tweaks..."

# Modify security.conf
sudo sed -i '/^ServerTokens/s/.*/ServerTokens Prod/' /etc/apache2/conf-available/security.conf
sudo sed -i '/^ServerSignature/s/.*/ServerSignature Off/' /etc/apache2/conf-available/security.conf
sudo sed -i '/^TraceEnable/s/.*/TraceEnable Off/' /etc/apache2/conf-available/security.conf

# Function to configure external disk
configure_external_disk() {
    local disk=$1
    local format=$2
    if [ "$format" = "yes" ]; then
        sudo mkfs.ext4 "$disk" || { echo "Failed to format disk $disk"; exit 1; }
    fi
    local mount_point="/mnt/external_disk$(echo $disk | tr -dc '0-9')"
    sudo mkdir -p "$mount_point" || { echo "Failed to create mount point $mount_point"; exit 1; }
    sudo mount "$disk" "$mount_point" || { echo "Failed to mount disk $disk"; exit 1; }
    sudo chown -R www-data:www-data "$mount_point" || { echo "Failed to set ownership for $mount_point"; exit 1; }
    sudo chmod -R 755 "$mount_point" || { echo "Failed to set permissions for $mount_point"; exit 1; }
    if ! grep -q "$disk $mount_point ext4 defaults 0 2" /etc/fstab; then
        sudo bash -c "echo '$disk $mount_point ext4 defaults 0 2' >> /etc/fstab" || { echo "Failed to update /etc/fstab"; exit 1; }
    fi
}

# Prompt user for number of external disks
read -p "Enter the number of external disks: " num_disks
validate_input "$num_disks"

# Configure external disks
for ((i=1; i<=$num_disks; i++)); do
    read -p "Enter the device for external disk $i (e.g. /dev/sda1): " disk
    read -p "Do you want to format disk $disk? (yes/no): " format
    configure_external_disk "$disk" "$format" || { echo "Failed to configure disk $disk"; exit 1; }

    # Set permissions for each external disk
    sudo chown -R www-data:www-data "/mnt/external_disk$(echo $disk | tr -dc '0-9')" || { echo "Failed to set ownership for /mnt/external_disk$(echo $disk | tr -dc '0-9')"; exit 1; }
    sudo chmod -R 755 "/mnt/external_disk$(echo $disk | tr -dc '0-9')" || { echo "Failed to set permissions for /mnt/external_disk$(echo $disk | tr -dc '0-9')"; exit 1; }
done

echo "External disk configuration complete."

echo "Configuration complete. Check that Nextcloud is working properly. Add the external drive to Nextcloud using the External Storage app."
