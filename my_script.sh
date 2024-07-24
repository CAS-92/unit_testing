#!/bin/bash

# Define your static IP address from an environment variable
STATIC_IP="${SSH_HOST}"  # Ensure this environment variable is set in your CI/CD pipeline

# Check if STATIC_IP is set
if [ -z "$STATIC_IP" ]; then
  echo "Error: SSH_HOST environment variable is not set."
  exit 1
fi

# Update package index
sudo apt update -q

# Install Nginx
sudo apt install -y -q nginx

# Start and enable Nginx
sudo systemctl start nginx
sudo systemctl enable nginx

# Preconfigure MySQL installation using a temporary file
echo "mysql-server mysql-server/root_password password root" | sudo debconf-set-selections
echo "mysql-server mysql-server/root_password_again password root" | sudo debconf-set-selections

# Install MySQL
sudo apt install -y -q mysql-server

# Secure MySQL installation
sudo mysql -u root -proot << EOF
ALTER USER 'root'@'localhost' IDENTIFIED WITH mysql_native_password BY 'root';
DELETE FROM mysql.user WHERE User='';
DROP DATABASE IF EXISTS test;
DELETE FROM mysql.db WHERE Db='test' OR Db='test_%';
FLUSH PRIVILEGES;
EOF

# Install PHP
sudo apt install -y -q php-fpm php-mysql

# Configure Nginx to use PHP processor
cat << EOF | sudo tee /etc/nginx/sites-available/default
server {
    listen $STATIC_IP:80 default_server;
    listen [::]:80 default_server;

    root /var/www/html;
    index index.php index.html index.htm index.nginx-debian.html;

    server_name $STATIC_IP;

    location / {
        try_files \$uri \$uri/ =404;
    }

    location ~ \.php$ {
        include snippets/fastcgi-php.conf;
        fastcgi_pass unix:/var/run/php/php7.4-fpm.sock;
    }

    location ~ /\.ht {
        deny all;
    }
}
EOF

# Test Nginx configuration and restart the service
sudo nginx -t
sudo systemctl restart nginx

# Allow Nginx through the firewall
sudo ufw allow 'Nginx Full'

# Verify installation
echo "<?php phpinfo(); ?>" | sudo tee /var/www/html/info.php

echo "LEMP stack installation complete. You can verify PHP by visiting http://$STATIC_IP/info.php"

