#!/bin/bash

# Aggiorna il sistema
sudo apt update -y && sudo apt upgrade -y

# Installa i pacchetti necessari
sudo apt install -y apache2 mariadb-server libapache2-mod-php php-gd php-json php-mysql php-curl php-mbstring php-intl php-imagick php-xml php-zip php-apcu php-gmp php-bcmath openssl

# Abilita e avvia Apache e MariaDB
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

# Scarica e configura Nextcloud
wget https://download.nextcloud.com/server/releases/latest.tar.bz2
sudo tar -xjvf latest.tar.bz2
sudo cp -r nextcloud /var/www/

# Imposta i permessi
sudo chown -R www-data:www-data /var/www/nextcloud/
sudo chmod -R 755 /var/www/nextcloud/

# Crea il file di configurazione di Apache per Nextcloud
sudo bash -c 'cat > /etc/apache2/sites-available/nextcloud.conf <<EOF
<VirtualHost *:80>
    DocumentRoot /var/www/nextcloud/
    ServerName 192.168.1.14

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
EOF'

# Configura Apache
sudo a2dissite 000-default.conf
sudo systemctl reload apache2
sudo a2ensite nextcloud.conf
sudo systemctl reload apache2
sudo a2enmod rewrite headers env dir mime setenvif ssl
sudo systemctl restart apache2

# Prompt per completare la configurazione di Nextcloud via interfaccia web
echo "ATTENZIONE: Completa la configurazione di Nextcloud tramite l'interfaccia web andando su http://indirizzoipdelserver prima di procedere."
read -p "Premi INVIO per continuare una volta completata la configurazione..."

# Configura il disco esterno
lsblk
read -p "Inserisci il dispositivo del disco esterno (es. /dev/sda1): " external_disk
sudo mkfs.ext4 $external_disk
sudo mkdir /mnt/nextcloud
sudo mount $external_disk /mnt/nextcloud

# Configura fstab per il montaggio automatico
sudo bash -c "echo '$external_disk /mnt/nextcloud ext4 defaults 0 2' >> /etc/fstab"

# Sposta i dati di Nextcloud sul disco esterno
sudo mv /var/www/nextcloud/data /mnt/nextcloud/
sudo ln -s /mnt/nextcloud/data /var/www/nextcloud/data
sudo chown -R www-data:www-data /mnt/nextcloud/data

# Abilita SSL
sudo mkdir -p /etc/apache2/ssl
sudo openssl req -x509 -nodes -days 365 -newkey rsa:4096 -keyout /etc/apache2/ssl/apache.key -out /etc/apache2/ssl/apache.crt
sudo a2enmod ssl
sudo systemctl restart apache2

# Configura SSL per Apache
sudo bash -c 'sed -i "s|DocumentRoot /var/www/html|DocumentRoot /var/www/nextcloud|g" /etc/apache2/sites-available/default-ssl.conf'
sudo bash -c 'sed -i "s|SSLCertificateFile      /etc/ssl/certs/ssl-cert-snakeoil.pem|SSLCertificateFile /etc/apache2/ssl/apache.crt|g" /etc/apache2/sites-available/default-ssl.conf'
sudo bash -c 'sed -i "s|SSLCertificateKeyFile   /etc/ssl/private/ssl-cert-snakeoil.key|SSLCertificateKeyFile /etc/apache2/ssl/apache.key|g" /etc/apache2/sites-available/default-ssl.conf'

sudo a2ensite default-ssl.conf
sudo systemctl restart apache2

# Abilita il reindirizzamento HTTPS
sudo bash -c 'sed -i "/ErrorLog \${APACHE_LOG_DIR}\/error.log/i RewriteEngine On\nRewriteCond %{HTTPS} off\nRewriteRule ^(.*)$ https://%{HTTP_HOST}\$1 [R=301,L]\n" /etc/apache2/sites-available/000-default.conf'

sudo a2enmod rewrite
sudo systemctl restart apache2

# Configura cron per Nextcloud
sudo bash -c 'echo "*/15 * * * * php -f /var/www/nextcloud/cron.php" >> /var/spool/cron/crontabs/www-data'

# Modifica il file php.ini per aumentare il memory_limit
PHP_VERSION=$(php -r "echo PHP_MAJOR_VERSION.'.'.PHP_MINOR_VERSION;")
PHP_INI="/etc/php/$PHP_VERSION/apache2/php.ini"

sudo sed -i 's/memory_limit = .*/memory_limit = 512M/' $PHP_INI
sudo systemctl restart apache2

echo "Configurazione completata. Verifica che Nextcloud funzioni correttamente. Aggiungi su Nextcloud il disco esterno usando l'app Archiviazione esterna."