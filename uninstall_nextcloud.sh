#!/bin/bash

# Error Handling
set -euo pipefail

# Trap to catch errors and perform cleanup tasks
cleanup() {
    echo "An error occurred during cleanup."
    # Add cleanup tasks here if needed
}
trap 'cleanup' ERR

# Prompt the user to input database name
read -p "Enter the database name: " DB_NAME

# Prompt the user to input database user
read -p "Enter the database user: " DB_USER

# Prompt the user to input the Nextcloud installation directory
read -p "Enter the Nextcloud installation directory: " NEXTCLOUD_DIR

# Undo Apache configuration changes
undo_apache_config() {
    echo "Undoing Apache configuration changes..."
    if [ -f /etc/apache2/sites-available/nextcloud.conf ]; then
        sudo rm /etc/apache2/sites-available/nextcloud.conf
        sudo a2dissite nextcloud.conf
    else
        echo "Nextcloud site configuration not found. Skipping."
    fi
    if [ -f /etc/apache2/sites-enabled/default-ssl.conf ]; then
        sudo a2dissite default-ssl.conf
    fi
    if [ ! -f /etc/apache2/sites-enabled/000-default.conf ]; then
        sudo a2ensite 000-default.conf
    fi
    sudo systemctl restart apache2
}

# Undo MariaDB changes
undo_mariadb() {
    echo "Undoing MariaDB changes..."
    sudo mysql -u root -p <<EOF
DROP DATABASE IF EXISTS $DB_NAME;
DROP USER IF EXISTS '$DB_USER'@'localhost';
EOF
}

# Remove Nextcloud installation
remove_nextcloud() {
    echo "Removing Nextcloud installation..."
    sudo rm -rf "$NEXTCLOUD_DIR"
}

# Remove PHP configuration changes
remove_php_config() {
    echo "Removing PHP configuration changes..."
    PHP_VERSION=$(php -r 'echo PHP_MAJOR_VERSION.".".PHP_MINOR_VERSION;')
    sudo sed -i '/^memory_limit/s/.*/memory_limit = 128M/' /etc/php/"$PHP_VERSION"/apache2/php.ini
    sudo sed -i '/^upload_max_filesize/s/.*/upload_max_filesize = 2M/' /etc/php/"$PHP_VERSION"/apache2/php.ini
    sudo sed -i '/^post_max_size/s/.*/post_max_size = 8M/' /etc/php/"$PHP_VERSION"/apache2/php.ini
    sudo sed -i '/^max_input_time/s/.*/max_input_time = 60/' /etc/php/"$PHP_VERSION"/apache2/php.ini
    sudo sed -i '/^max_execution_time/s/.*/max_execution_time = 30/' /etc/php/"$PHP_VERSION"/apache2/php.ini
    sudo systemctl restart apache2
}

# Remove firewall rules
remove_firewall_rules() {
    echo "Removing firewall rules..."
    sudo ufw delete allow 80/tcp
    sudo ufw delete allow 443/tcp
    sudo ufw disable
}

# Undo additional security and performance tweaks
undo_security_performance() {
    echo "Undoing additional security and performance tweaks..."
    sudo sed -i '/^ServerTokens/s/.*/ServerTokens OS/' /etc/apache2/conf-available/security.conf
    sudo sed -i '/^ServerSignature/s/.*/ServerSignature On/' /etc/apache2/conf-available/security.conf
    sudo sed -i '/^TraceEnable/s/.*/TraceEnable On/' /etc/apache2/conf-available/security.conf
}

# Undo external disk configuration
undo_external_disk() {
    echo "Undoing external disk configuration..."
    # Add commands to unmount and remove external disk configuration
}

# Main function to undo all changes
main() {
    undo_apache_config
    undo_mariadb
    remove_nextcloud
    remove_php_config
    remove_firewall_rules
    undo_security_performance
    # Add more undo functions as needed
    echo "Undo process completed successfully."
}

# Execute the main function
main
