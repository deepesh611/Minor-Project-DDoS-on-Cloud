#!/bin/bash

# Check if the script is run as root
if [ "$(id -u)" -ne 0 ]; then
    echo "This script must be run as root. Use 'sudo' to run it."
    exit 1
fi

# Function to install Apache2
install_apache2() {
    echo "Updating package lists..."
    apt update -y

    echo "Installing Apache2..."
    apt install -y apache2

    echo "Apache2 installation completed!"
}

# Function to configure Apache2
configure_apache2() {
    local SERVER_NAME=$1  # ServerName parameter

    echo "Configuring Apache2..."

    # Create a new configuration file
    cat <<EOL > /etc/apache2/sites-available/000-default.conf
<VirtualHost *:80>
    ServerAdmin webmaster@localhost
    DocumentRoot /var/www/html

    ServerName $SERVER_NAME

    <Directory /var/www/html>
        Options Indexes FollowSymLinks
        AllowOverride None
        Require all granted
    </Directory>

    ErrorLog ${APACHE_LOG_DIR}/error.log
    CustomLog ${APACHE_LOG_DIR}/access.log combined
</VirtualHost>
EOL

    # Enable the Apache2 rewrite module
    a2enmod rewrite

    # Restart Apache2 to apply changes
    echo "Restarting Apache2..."
    systemctl restart apache2

    echo "Apache2 configuration completed!"
}

# Main script execution
if [ -z "$1" ]; then
    echo "Usage: $0 <server_name>"
    exit 1
fi

# Get the server name from the command line argument
SERVER_NAME="$1"

install_apache2
configure_apache2 "$SERVER_NAME"
