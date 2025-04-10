#!/bin/bash

# Honeypot Script

# Directory to store honeypot logs
LOG_DIR="$HOME/Desktop/DDOS/honeypot_log"
mkdir -p "$LOG_DIR"

# Ports to listen on (e.g., HTTP, FTP, SSH)
PORTS=(21 22 80)

# CSV file to store structured honeypot data
CSV_FILE="$LOG_DIR/dataset_sdn.csv"

# Initialize the CSV file with headers if it doesn't exist
if [ ! -f "$CSV_FILE" ]; then
    echo "timestamp,port,source_ip,source_port,attempt_details" > "$CSV_FILE"
fi

# Function to start a honeypot on a specific port
start_honeypot() {
    local port=$1
    local log_file="$LOG_DIR/port_${port}_log.txt"
    
    echo "Starting honeypot on port $port..."
    
    # Use netcat to listen on the port indefinitely
    while true; do
        # Listen for incoming connections and capture connection details
        connection=$(sudo nc -lvkp "$port" -w 5 2>&1)
        
        # Extract connection details
        timestamp=$(date +"%Y-%m-%d %H:%M:%S")
        source_ip=$(echo "$connection" | grep -oE 'Connection from [0-9]+\.[0-9]+\.[0-9]+\.[0-9]+' | awk '{print $3}')
        source_port=$(echo "$connection" | grep -oE '[0-9]+$')
        attempt_details=$(echo "$connection" | tr '\n' ' ')
        
        # Log details in CSV format if IP is detected
        if [ -n "$source_ip" ]; then
            echo "$timestamp,$port,$source_ip,$source_port,\"$attempt_details\"" >> "$CSV_FILE"
        fi
        
        # Log connection details in a readable format in a separate log file
        echo "Connection attempt on port $port at $timestamp from $source_ip:$source_port" >> "$log_file"
    done
}

# Start honeypots on each port in the background
for port in "${PORTS[@]}"; do
    start_honeypot "$port" &
done

# Keep script running until manually stopped
echo "Honeypot is running. Press Ctrl+C to stop."
wait
