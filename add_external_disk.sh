add_external_disk() {
    read -p "Enter the device for the new external disk (e.g., /dev/sdc1): " disk
    read -p "Do you want to format disk $disk? (yes/no): " format
    local disk_number=$(ls /mnt | grep -oP 'external_disk\K[0-9]+' | sort -n | tail -1)
    local new_disk_number=$((disk_number + 1))
    local mount_point="/mnt/external_disk$new_disk_number"
    
    if [ "$format" = "yes" ]; then
        sudo mkfs.ext4 "$disk" || { echo "Failed to format disk $disk"; exit 1; }
    fi
    
    sudo mkdir -p "$mount_point" || { echo "Failed to create mount point $mount_point"; exit 1; }
    sudo mount "$disk" "$mount_point" || { echo "Failed to mount disk $disk"; exit 1; }
    sudo chown -R www-data:www-data "$mount_point" || { echo "Failed to set ownership for $mount_point"; exit 1; }
    sudo chmod -R 755 "$mount_point" || { echo "Failed to set permissions for $mount_point"; exit 1; }
    
    if ! grep -q "$disk $mount_point ext4 defaults 0 2" /etc/fstab; then
        sudo bash -c "echo '$disk $mount_point ext4 defaults 0 2' >> /etc/fstab" || { echo "Failed to update /etc/fstab"; exit 1; }
        sudo systemctl daemon-reload || { echo "Failed to reload systemd daemon"; exit 1; }
    fi
    
    echo "External disk added at $mount_point"
    echo "Please add this new external storage in Nextcloud's external storage settings."
}

add_external_disk
