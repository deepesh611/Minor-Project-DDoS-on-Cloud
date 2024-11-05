#!/bin/bash

# Check if the script is run as root
if [ "$(id -u)" -ne 0 ]; then
    echo "This script must be run as root. Use 'sudo' to run it."
    exit 1
fi

# Function to install Keepalived
install_keepalived() {
    echo "Updating package lists..."
    apt update -y

    echo "Installing Keepalived..."
    apt install -y keepalived

    echo "Keepalived installation completed!"
}

# Function to set up Keepalived configuration
setup_keepalived_config() {
    local ROLE=$1  # 'master' or 'backup'
    local CONFIG_FILE="/etc/keepalived/keepalived.conf"

    echo "Creating Keepalived config for $ROLE..."

    if [ "$ROLE" == "master" ]; then
        cat <<EOL > $CONFIG_FILE
vrrp_instance VI_1 {
    state MASTER
    interface eth0                   # Network interface
    virtual_router_id 51             # Unique ID for the VRRP instance
    priority 101                     # Higher priority for master
    advert_int 1                     # Advertisement interval
    authentication {
        auth_type PASS
        auth_pass YOUR_SECRET_PASSWORD  # Password for authentication
    }
    virtual_ipaddress {
        192.168.1.100                  # Virtual IP address
    }
}
EOL
    elif [ "$ROLE" == "backup" ]; then
        cat <<EOL > $CONFIG_FILE
vrrp_instance VI_1 {
    state BACKUP
    interface eth0                   # Network interface
    virtual_router_id 51             # Must match the master
    priority 100                     # Lower priority for backup
    advert_int 1                     # Advertisement interval
    authentication {
        auth_type PASS
        auth_pass YOUR_SECRET_PASSWORD  # Same password as the master
    }
    virtual_ipaddress {
        192.168.1.100                  # Virtual IP address (same as master)
    }
}
EOL
    else
        echo "Invalid role specified. Use 'master' or 'backup'."
        exit 1
    fi

    # Start Keepalived service
    echo "Starting Keepalived service..."
    systemctl enable keepalived
    systemctl start keepalived

    echo "Keepalived setup for $ROLE completed!"
}

# Main script execution
if [ "$1" == "master" ]; then
    install_keepalived
    setup_keepalived_config "master"
elif [ "$1" == "backup" ]; then
    install_keepalived
    setup_keepalived_config "backup"
else
    echo "Usage: $0 <master|backup>"
    exit 1
fi
