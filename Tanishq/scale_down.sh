#!/bin/bash

# Log file path
LOG_FILE="$HOME/path/to/scale_down.log"

# Function to log messages
log_message() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') - $1" >> "$LOG_FILE"
}

# Example actions for scaling down resources
log_message "Scaling down resources..."

# Decrease system limits (example: reducing max file descriptors)
sudo sysctl -w fs.file-max=50000

# Stop a service if it’s running (example: web server)
SERVICE="apache2"  # Replace with your service name
if systemctl is-active --quiet "$SERVICE"; then
    sudo systemctl stop "$SERVICE"
    log_message "$SERVICE stopped."
else
    log_message "$SERVICE is not running."
fi

# Add other commands as necessary
log_message "Scaling down completed."
