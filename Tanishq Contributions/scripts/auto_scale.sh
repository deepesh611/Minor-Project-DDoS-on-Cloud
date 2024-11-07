#!/bin/bash

# Configurable variables
LOAD_THRESHOLD=2.0            # Set the load threshold (adjust based on server capacity)
CHECK_INTERVAL=60             # Check server load every 60 seconds
BACKUP_SERVER_IP="192.168.0.140"  # IP or hostname of the backup server
LOG_FILE="/home/parrot/Desktop/DDOS/auto_scale.log"

# Create the directory for the log file if it doesn't exist
LOG_DIR=$(dirname "$LOG_FILE")
mkdir -p "$LOG_DIR"

# Function to check server load
check_load() {
    # Get the 1-minute load average
    local load_avg=$(uptime | awk -F'load average:' '{ print $2 }' | cut -d, -f1 | xargs)
    echo "$load_avg"
}

# Function to start backup server
start_backup_server() {
    # Command to start backup server; replace with actual start command/API call
    echo "$(date) - High load detected! Starting backup server at $BACKUP_SERVER_IP..." >> "$LOG_FILE"
    # Example placeholder command; replace with actual command, e.g., SSH or API call
    ssh user@"$BACKUP_SERVER_IP" 'sudo systemctl start apache2' >> "$LOG_FILE" 2>&1
}

# Function to log load events
log_event() {
    local message="$1"
    echo "$(date) - $message" >> "$LOG_FILE"
}

# Main loop to monitor load and trigger backup server
while true; do
    # Get current load average
    load=$(check_load)
    
    # Compare load average to threshold
    if (( $(echo "$load > $LOAD_THRESHOLD" | bc -l) )); then
        log_event "Load is $load, exceeding threshold of $LOAD_THRESHOLD. Triggering backup server..."
        start_backup_server
    else
        log_event "Load is $load, within normal limits."
    fi
    
    # Sleep for the check interval
    sleep "$CHECK_INTERVAL"
done
