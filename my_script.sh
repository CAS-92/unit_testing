#!/bin/bash

# Define your static IP address
STATIC_IP="YOUR_STATIC_IP"

# Update package index
sudo apt update

# Install Nginx
sudo apt install -y nginx

# Start and enable Nginx
sudo systemctl start nginx
sudo systemctl enable nginx

# Install MySQL
sudo apt install -y mysql-server

# Run MySQL secure installation
sudo mysql_secure_installation

# Install PHP
sudo apt install -y php-fpm php-mysql

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
