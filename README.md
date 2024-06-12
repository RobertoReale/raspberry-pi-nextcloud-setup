# raspberry-pi-nextcloud-setup:
This installation script automates the setup process for Nextcloud on a Raspberry Pi, including the installation of Apache, MariaDB, PHP, and the configuration of necessary settings. It streamlines the deployment of Nextcloud, a popular self-hosted cloud storage platform, making it accessible for personal or small-scale use cases.

Features:
- Automated Setup: The script automates the entire setup process, reducing manual configuration efforts.
- Error Handling: Incorporates error handling mechanisms to catch and handle errors gracefully during installation.
- Security Enhancements: Implements security best practices, such as securing MariaDB installation and configuring SSL for Apache.
- Customization: Allows users to customize various settings such as server IP address, database credentials, PHP configuration, and more.
- External Disk Support: Provides support for adding external storage disks to Nextcloud, expanding storage capacity.

Usage:
- Download the Script:

- Clone or download the installation script from the repository to your Raspberry Pi.
Make the Script Executable:
```
chmod +x setup_nextcloud.sh
```

- Run the Script:

Execute the script with sudo privileges:
```
sudo ./setup_nextcloud.sh
```

- Follow the Prompts:

The script will prompt you for various configurations, such as server IP address, database credentials, PHP settings, etc. Follow the prompts and provide the required information.
Complete Installation:

Once the script completes, navigate to your Raspberry Pi's IP address in a web browser to complete the Nextcloud setup via the web interface.

# Add External Storage Script for Nextcloud
This script simplifies the process of adding additional external storage disks to an existing Nextcloud instance. It automates the steps required to mount the disk, update /etc/fstab, set permissions, and notify the user to configure the new external storage within Nextcloud.

Features:
- Ease of Use: Provides a straightforward method to add external storage disks without manual intervention.
- Automated Mounting: Automates disk mounting and updates /etc/fstab for automatic mounting on system boot.
- Error Handling: Includes error handling mechanisms to handle failures gracefully during disk addition.
- Compatibility: Compatible with the installation script for Nextcloud on Raspberry Pi, seamlessly integrating with existing setups.

Usage:
- Download the Script:

- Clone or download the script from the repository to your Raspberry Pi.
Make the Script Executable:
```
chmod +x add_external_disk.sh
```

- Run the Script:

- Execute the script with sudo privileges:
```
sudo ./add_external_disk.sh
```

- Follow the Prompts:

The script will prompt you to enter the device for the new external disk and whether to format it.
Configure in Nextcloud:

After running the script, follow the instructions provided to add the new external storage in Nextcloud's settings.
By using these scripts, users can streamline the setup and management of their Nextcloud instances, enhancing storage capacity and accessibility with ease.

# Nextcloud Configuration Script
This Bash script provides a set of utilities to manage and configure a Nextcloud installation. It offers options to install essential software, set maintenance windows, and configure Apache for Nextcloud's well-known URLs.

Features:
- Install smbclient and restart Apache2:
Installs smbclient using apt.
Restarts the Apache2 service to apply changes.

- Set Maintenance Window Start Time:
Prompts the user for the Nextcloud installation directory.
Updates the config.php file to enable maintenance mode and set the maintenance window start time to 01:00 AM UTC.

- Configure Apache for Well-Known URLs:
Prompts the user for the Nextcloud installation directory.
Adds rewrite rules to the Apache configuration to properly redirect .well-known URLs for CardDAV and CalDAV.
Enables the mod_rewrite module in Apache.
Restarts the Apache2 service to apply changes.

- Configure PHP OPcache for Nextcloud:
- Adjusts the PHP OPcache settings to optimize Nextcloud performance.

Usage:
- Clone the repository:
  ```
  git clone https://github.com/yourusername/nextcloud-config-script.git
  cd nextcloud-config-script
  ```

- Run the script:
  ```
  ./nextcloud-config.sh
  ```

- Select an option:
  * Install smbclient and restart Apache2.
  * Set maintenance window start time in Nextcloud config.
  * Configure Apache for well-known URLs.
  * Configure PHP OPcache for Nextcloud

# Disclaimer
The installation script for Nextcloud on Raspberry Pi and the add external storage script provided herein are intended for educational and personal use only. While efforts have been made to ensure the scripts are accurate and reliable, they are provided "as is" without any warranty of any kind, express or implied.

Limitation of Liability
The authors and contributors of these scripts shall not be held liable for any damages or losses arising from the use or inability to use the scripts, including but not limited to direct, indirect, incidental, special, or consequential damages, or any loss of data, revenue, or profits, arising out of or in connection with the use or performance of these scripts.

Use at Your Own Risk
Users are advised to review and understand the scripts before executing them on their systems. It is recommended to backup any important data and configurations before running the scripts. The user assumes full responsibility for any risks associated with the use of these scripts.

Third-Party Dependencies
These scripts may utilize third-party tools or libraries. Users are responsible for ensuring compliance with the licenses and terms of use of any third-party software utilized by the scripts.

Modification and Distribution
Users are welcome to modify and distribute these scripts for personal or educational purposes. However, any redistribution should include this disclaimer and retain attribution to the original authors and contributors.

By using these scripts, you acknowledge that you have read, understood, and agree to the terms and conditions outlined in this disclaimer. If you do not agree with these terms, you should not use these scripts.

