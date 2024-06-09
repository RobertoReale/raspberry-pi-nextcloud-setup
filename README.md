# raspberry-pi-nextcloud-setup
This repository contains a Bash script for setting up Nextcloud on a Raspberry Pi. Nextcloud is a self-hosted file sharing and collaboration platform that allows you to store your data, access it from anywhere, and collaborate with others. This script automates the installation process, including the setup of Apache, MariaDB, PHP, SSL, and configuration of Nextcloud itself.

Features:
- Automated installation of Nextcloud on Raspberry Pi.
- Configuration of Apache, MariaDB, and PHP.
- SSL setup for secure connections.
- Integration with external storage devices.
- Cron job configuration for Nextcloud maintenance tasks.
- Memory limit optimization for improved performance.


Usage:
- Clone this repository to your Raspberry Pi.
- Make the script executable (chmod +x nextcloud_setup.sh).
- Run the script (./nextcloud_setup.sh) and follow the prompts.
- Access Nextcloud via the provided IP address and complete the setup via the web interface.
- Contributions:
- Contributions and suggestions are welcome! Feel free to fork this repository, make changes, and submit a pull request.

# Add external storage
If you want to add another external drive to Nextcloud in the future, you need to follow these steps:

### 1. Prepare the External Drive

1. **Connect the External Drive:**
   - Plug your new external drive into a USB port on your Raspberry Pi.

2. **Format the Drive:**
   - Determine the device name of your new drive by running:
     ```
     lsblk
     ```
   - Identify your new drive (e.g., `/dev/sdb` or `/dev/sdc1`) and format it with a suitable filesystem (e.g., ext4):
     ```
     sudo mkfs.ext4 /dev/sdb1
     ```

### 2. Mount the External Drive

1. **Create a Mount Point:**
   - Create a directory where you want to mount the new drive:
     ```
     sudo mkdir /mnt/new_nextcloud/data
     ```

2. **Mount the Drive:**
   - Mount the drive to this directory. Select the correct drive (e.g., `/dev/sdb1`):
     ```
     sudo mount /dev/sdb1 /mnt/new_nextcloud/data
     ```

3. **Ensure Automatic Mounting:**
   - Edit the `/etc/fstab` file to make sure the new drive mounts automatically at boot:
     ```
     sudo nano /etc/fstab
     ```
   - Add the following line (adjust for the correct device and mount point). Select the correct drive (e.g., `/dev/sdb1`):
     ```
     /dev/sdb1 /mnt/new_nextcloud/data ext4 defaults 0 2
     ```
   - Save and close the file.

### 3. Add the External Drive to Nextcloud

1. **Change Permissions:**
   - Set the correct ownership for the new data directory:
     ```
     sudo chown -R www-data:www-data /mnt/new_nextcloud/data
     ```

2. **Add the New External Storage in Nextcloud:**
   - Log in to Nextcloud as an admin.
   - Go to `Settings` (click on your profile picture in the top right corner, then click `Settings`).
   - Scroll down to `Admin` section and click on `External storage`.
   - In the `External storage` section, configure the new external storage:
     - **Folder name**: Give a name for the new external storage.
     - **External storage**: Select `Local`.
     - **Configuration**: Enter the path to the new mount point (e.g., `/mnt/new_nextcloud/data`).
     - **Authentication**: Leave it blank.
     - **Available for**: Select which users or groups can access this external storage.

3. **Save the Configuration:**
   - Click on the check mark to save the configuration.
   - You should now see the new external storage in your Nextcloud files.

### 4. Verify the Setup

1. **Check Mount Points:**
   - Verify that both the old and new external drives are mounted correctly:
     ```
     df -h
     ```

2. **Test Access:**
   - Log in to Nextcloud and ensure you can access files on both the original and new external storage.

# DISCLAIMER:
This script is provided as-is and may require customization based on your specific setup. Use at your own risk.
There are some points that may require attention:

1. **MySQL Security**: After running `mysql_secure_installation`, it would be a good idea to check if remote access to MySQL is disabled, especially if this server is not intended to be accessible from the external network.

2. **SSL Configuration**: Using self-generated certificates may be acceptable for a test environment, but for a production environment it is best to obtain a signed certificate from a trusted Certification Authority (CA).

3. **Auto-mount external disk**: Make sure the external disk is mounted correctly when the system boots. You may want to check the mount options in the `/etc/fstab` file to ensure they are appropriate for your specific use case.

4. **Cron Job for Nextcloud**: The cron job execution frequency (every 15 minutes) may be suitable for many installations, but may need to be adjusted based on the specific needs of your environment.

5. **Error Control**: Be sure to include error handling in your code, especially in system operations and MySQL commands, to ensure that any problems are handled appropriately.

6. **Backup and Recovery**: Make sure you have a backup and recovery plan in place, especially before making significant changes to your system such as installing and configuring new services.

Always remember to run your code in a test environment before deploying it to a production environment and take necessary precautions to ensure system security and reliability.
