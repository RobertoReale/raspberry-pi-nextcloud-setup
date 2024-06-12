#!/bin/bash

validate_disk() {
    if ! [[ "$1" =~ ^/dev/[a-z]+[0-9]+$ ]]; then
        echo "Invalid disk input. Please enter a valid disk device (e.g., /dev/sda1)."
        exit 1
    fi
}

validate_format() {
    if [[ "$1" != "yes" && "$1" != "no" ]]; then
        echo "Invalid format input. Please enter 'yes' or 'no'."
        exit 1
    fi
}

configure_external_disk() {
    local disk=$1
    local format=$2
    local mount_point="/mnt/external_disk_$3"

    if [ "$format" = "yes" ]; then
        sudo mkfs.ext4 "$disk" || { echo "Failed to format disk $disk"; exit 1; }
    fi

    sudo mkdir -p "$mount_point" || { echo "Failed to create mount point $mount_point"; exit 1; }
    sudo mount "$disk" "$mount_point" || { echo "Failed to mount disk $disk"; exit 1; }
    sudo chown -R www-data:www-data "$mount_point" || { echo "Failed to set ownership for $mount_point"; exit 1; }
    sudo chmod -R 755 "$mount_point" || { echo "Failed to set permissions for $mount_point"; exit 1; }

    if ! grep -q "$disk $mount_point ext4 defaults 0 2" /etc/fstab; then
        echo "$disk $mount_point ext4 defaults 0 2" | sudo tee -a /etc/fstab || { echo "Failed to update /etc/fstab"; exit 1; }
        sudo systemctl daemon-reload || { echo "Failed to reload systemd daemon"; exit 1; }
    fi
}

# Find the next available mount point number
next_mount_point_number() {
    local last_mount_point=$(ls /mnt | grep '^external_disk_' | sed 's/^external_disk_//' | sort -n | tail -n 1)
    if [[ -z "$last_mount_point" ]]; then
        echo 1
    else
        echo $((last_mount_point + 1))
    fi
}

# Prompt user for the disk details
lsblk
read -p "Enter the device for the new external disk (e.g., /dev/sda1): " disk
validate_disk "$disk"
read -p "Do you want to format disk $disk? (yes/no): " format
validate_format "$format"

# Get the next mount point number
mount_point_number=$(next_mount_point_number)

# Configure the external disk
configure_external_disk "$disk" "$format" "$mount_point_number" || { echo "Failed to configure disk $disk"; exit 1; }

echo "External disk configuration complete."
