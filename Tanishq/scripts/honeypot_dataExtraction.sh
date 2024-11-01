#!/bin/bash

# Directory to store honeypot logs
LOG_DIR="$HOME/Desktop/DDOS/honeypot_log"
mkdir -p "$LOG_DIR"

# Ports to listen on (e.g., HTTP, FTP, SSH)
PORTS=(21 22 80)

# CSV file to store structured honeypot data
CSV_FILE="$HOME/Desktop/DDOS/dataset_sdn.csv"

# Initialize the CSV file with headers if it doesn't exist
if [ ! -f "$CSV_FILE" ]; then
    echo "timestamp,port,source_ip,source_port,attempt_details" > "$CSV_FILE"
fi

# Function to start a honeypot on a specified port
start_honeypot() {
    local port=$1
    local log_file="$LOG_DIR/port_${port}_log.txt"
    
    echo "Starting honeypot on port $port..."
    
    # Listen indefinitely and log incoming connections
    while true; do
        connection=$(sudo nc -lvkp "$port" -w 5 2>&1)

        # Extract connection details
        timestamp=$(date +"%Y-%m-%d %H:%M:%S")
        source_ip=$(echo "$connection" | grep -oE 'Connection from [0-9]+\.[0-9]+\.[0-9]+\.[0-9]+' | awk '{print $3}')
        source_port=$(echo "$connection" | grep -oE '[0-9]+$')
        attempt_details=$(echo "$connection" | tr '\n' ' ')
        
        # Log details in CSV format
        if [ -n "$source_ip" ]; then
            echo "$timestamp,$port,$source_ip,$source_port,\"$attempt_details\"" >> "$CSV_FILE"
            echo "Connection attempt logged: $timestamp - Port: $port - Source IP: $source_ip - Source Port: $source_port"
        fi
    done
}

# Start honeypots on each port in the background
for port in "${PORTS[@]}"; do
    start_honeypot "$port" &
    PID_LIST+=($!)  # Store the process ID of the honeypot
done

# Keep script running for 60 seconds
echo "Honeypot is running. Press Ctrl+C to stop."
sleep 60

# Terminate all background honeypot processes using the stored PIDs
echo "Stopping honeypots..."
for pid in "${PID_LIST[@]}"; do
    if kill -0 "$pid" >/dev/null 2>&1; then  # Check if process exists
        kill "$pid"
    fi
done

# Data Extraction Script
PROCESSED_DIR="$HOME/Desktop/DDOS/processed_data"
mkdir -p "$PROCESSED_DIR"

# Check if the CSV file exists before proceeding
if [[ ! -f "$CSV_FILE" ]]; then
    echo "Error: CSV file not found at $CSV_FILE"
    exit 1
fi

# Extract date-based patterns and connection frequency per IP
awk -F, 'NR>1 {count[$3]++} END {for (ip in count) print ip","count[ip]}' "$CSV_FILE" > "$PROCESSED_DIR/connection_frequency.csv"

echo "Processed data saved to $PROCESSED_DIR/connection_frequency.csv"
