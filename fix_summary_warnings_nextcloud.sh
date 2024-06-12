#!/bin/bash

# Function to install smbclient and restart apache2
install_smbclient() {
    sudo apt install smbclient -y
    sudo systemctl restart apache2
}

# Function to set maintenance window start time in Nextcloud config
set_maintenance_window() {
    # Ask user for Nextcloud installation directory
    read -p "Enter the Nextcloud installation directory (e.g., /var/www/nextcloud): " nextcloud_dir

    # Check if config.php exists
    config_file="$nextcloud_dir/config/config.php"
    if [ ! -f "$config_file" ]; then
        echo "Config file $config_file not found. Exiting."
        exit 1
    fi

    # Check if maintenance_window_start is already set
    if grep -q "'maintenance_window_start'" "$config_file"; then
        # Update the existing maintenance_window_start value
        sudo sed -i "s/'maintenance_window_start' => [0-9]\+/'maintenance_window_start' => 1/" "$config_file"
    else
        # Add maintenance_window_start setting
        sudo sed -i "/);/i \ \ 'maintenance_window_start' => 1," "$config_file"
    fi
    echo "Maintenance window start time set to 01:00am UTC."
}

# Function to configure Apache for well-known URLs
configure_well_known() {
    # Check if nextcloud.conf exists
    nextcloud_conf="/etc/apache2/sites-available/nextcloud.conf"
    if [ ! -f "$nextcloud_conf" ]; then
        echo "Apache config file $nextcloud_conf not found. Exiting."
        exit 1
    fi

    # Ensure RewriteEngine directive is present only once and add Rewrite rules for well-known URLs
    if ! grep -q "RewriteEngine on" "$nextcloud_conf"; then
        sudo sed -i '/<VirtualHost/a\    RewriteEngine on' "$nextcloud_conf"
    fi
    
    if ! grep -q "RewriteRule ^\.well-known/carddav" "$nextcloud_conf"; then
        sudo sed -i '/RewriteEngine on/a\    RewriteRule ^\.well-known/carddav /remote.php/dav/ [R=301,L]' "$nextcloud_conf"
    fi
    
    if ! grep -q "RewriteRule ^\.well-known/caldav" "$nextcloud_conf"; then
        sudo sed -i '/RewriteEngine on/a\    RewriteRule ^\.well-known/caldav /remote.php/dav/ [R=301,L]' "$nextcloud_conf"
    fi

    # Enable mod_rewrite
    sudo a2enmod rewrite
    # Restart Apache
    sudo systemctl restart apache2
}

# Main script
echo "Select an option:"
echo "1. Install smbclient and restart apache2"
echo "2. Set maintenance window start time in Nextcloud config"
echo "3. Configure Apache for well-known URLs"
read -p "Enter your choice: " choice

case $choice in
    1) install_smbclient ;;
    2) set_maintenance_window ;;
    3) configure_well_known ;;
    *) echo "Invalid choice. Exiting." ;;
esac
