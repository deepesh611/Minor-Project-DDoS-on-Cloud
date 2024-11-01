#!/bin/bash

# Title
echo "=============================================================================="
figlet "Anti-DDOS"
echo "=============================================================================="

# Install required tools if not present
echo "Checking required tools..."
if ! command -v iftop &> /dev/null; then
    echo -n "Processing [######........] Installing required tools..."
    for i in {1..10}; do
        echo -n "Processing ["
        for ((j=0; j<i; j++)); do echo -n "#"; done
        for ((j=i; j<10; j++)); do echo -n "."; done
        echo -ne "]\r"
        sleep 0.1
    done
    echo ""  # New line after progress

    # Actual installation command
    sudo apt install -y iftop tcpdump > /dev/null || { echo "Error: Failed to install tools"; exit 1; }
    echo "Tools installed successfully."
else
    echo "Required tools already installed."
fi

# Variables
RATE_LIMIT="1mbit"           # Max rate allowed (adjust based on your needs)
BURST_SIZE="32k"             # Burst size
PACKET_THRESHOLD=10          # Threshold for packet count per IP
LOG_DIR="$HOME/path/to/ddos_monitor" # Directory to store logs
HONEYPOT_DIR="$LOG_DIR/honeypot_data"  # Directory to store honeypot data
AUTO_SCALE_THRESHOLD=1000    # Traffic threshold to trigger auto-scaling (in KB)
SCALE_UP_COMMAND="./scale_up.sh"  # Command to scale up resources
SCALE_DOWN_COMMAND="./scale_down.sh"  # Command to scale down resources

# Function to check if a command is successful
check_command() {
    if [ $? -ne 0 ]; then
        echo "Error: $1"
        exit 1
    fi
}

# Create log directories
echo "Setting up logging directories..."
mkdir -p "$LOG_DIR" "$HONEYPOT_DIR"
check_command "Failed to create log directory. Check permissions."
echo "Log directories set up at $LOG_DIR."

# Set up log files
TCPDUMP_LOG="$LOG_DIR/tcpdump_$(date +'%Y%m%d_%H%M%S').pcap"
IFTOP_LOG="$LOG_DIR/iftop_log.txt"
BLACKLIST_LOG="$LOG_DIR/blacklist_ips.log"
HONEYPOT_LOG="$HONEYPOT_DIR/honeypot_$(date +'%Y%m%d_%H%M%S').log"

# Function to list network interfaces
list_interfaces() {
    echo "Available network interfaces:"
    ip link show | awk -F: '/^[0-9]+: / {print $2}' | awk '{$1=$1};1'
}

# Function to prompt user to select an interface
select_interface() {
    list_interfaces
    read -p "Enter the interface you want to monitor: " INTERFACE
}

# Prompt the user to select an interface
select_interface

# Check if the interface exists
if ! ip link show "$INTERFACE" &> /dev/null; then
    echo "Error: Network interface '$INTERFACE' not found. Please check the interface name."
    exit 1
fi

# Function to set up rate limiting
setup_rate_limit() {
    echo "Setting up rate limiting on interface $INTERFACE with max rate $RATE_LIMIT and burst $BURST_SIZE..."

    # Remove existing qdiscs if they exist
    sudo tc qdisc del dev "$INTERFACE" root 2>/dev/null

    # Add rate limiting with a token bucket filter
    sudo tc qdisc add dev "$INTERFACE" root handle 1: htb default 10 || check_command "Failed to add traffic control rules."
    sudo tc class add dev "$INTERFACE" parent 1: classid 1:1 htb rate "$RATE_LIMIT" burst "$BURST_SIZE" || check_command "Failed to set rate limit class."
    sudo tc filter add dev "$INTERFACE" protocol ip parent 1: prio 1 u32 match ip src 0.0.0.0/0 flowid 1:1 || check_command "Failed to add traffic filter."

    echo "Rate limiting applied on interface $INTERFACE with max rate $RATE_LIMIT."
}

# Function to remove rate limiting
remove_rate_limit() {
    echo "Removing rate limiting from interface $INTERFACE..."

    # Check if there's an existing root qdisc
    if sudo tc qdisc show dev "$INTERFACE" | grep -q "root"; then
        # If a root qdisc exists, delete it
        sudo tc qdisc del dev "$INTERFACE" root || check_command "Failed to remove rate limiting."
        echo "Rate limiting removed from interface $INTERFACE."
    else
        echo "No rate limiting rules found on interface $INTERFACE."
    fi
}

# Function to check and blacklist high packet rate IPs
check_and_blacklist_ips() {
    echo "Checking for high traffic IPs to blacklist..."

    # Analyze tcpdump log and find IPs exceeding packet threshold
    sudo tcpdump -r "$TCPDUMP_LOG" -n | awk '{print $3}' | grep -oE '^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+' | \
    sort | uniq -c | awk -v threshold="$PACKET_THRESHOLD" '$1 > threshold {print $2}' > "$BLACKLIST_LOG"

    # Read IPs from blacklist log and add to iptables
    while IFS= read -r ip; do
        if ! sudo iptables -C INPUT -s "$ip" -j DROP 2>/dev/null; then
            echo "Blocking IP: $ip"
            sudo iptables -A INPUT -s "$ip" -j DROP
        else
            echo "IP $ip is already blacklisted."
        fi
    done < "$BLACKLIST_LOG"

    echo "Blacklisting complete. Blocked IPs are logged in $BLACKLIST_LOG."
}

# Function to log data from suspicious traffic to the honeypot
log_honeypot_data() {
    echo "Logging honeypot data..."
    
    # Capture data from suspicious traffic
    sudo tcpdump -i "$INTERFACE" -w "$HONEYPOT_LOG" -c 50 2>/dev/null

    # Log honeypot data
    echo "Honeypot data logged in $HONEYPOT_LOG."
}

# Function to detect and block potential DDoS attacks
detect_and_block_ddos() {
    echo "Detecting potential DDoS attacks..."

    # Check if the tcpdump log is created
    if [ ! -f "$TCPDUMP_LOG" ]; then
        echo "Warning: tcpdump log not found. Monitoring has not started yet. Retrying..."
        return
    fi

    # Check packet counts and blacklist IPs if needed
    check_and_blacklist_ips

    echo "DDoS detection completed."
}

# Function for auto-scaling resources based on traffic
auto_scale() {
    # Check if IFTOP_LOG exists and has content
    if [ ! -s "$IFTOP_LOG" ]; then
        echo "Warning: Traffic log unavailable or empty. Skipping auto-scale."
        return
    fi

    # Extract the last recorded traffic value (check units and adjust to KB)
    current_traffic=$(tail -n 1 "$IFTOP_LOG" | awk '{print $1}' | sed 's/[^0-9]*//g')  
    current_traffic_kb=$((current_traffic / 1024))  # Convert to KB if bytes

    echo "Current traffic: $current_traffic_kb KB"

    # Scale down if traffic is below half threshold
    if (( current_traffic_kb < (AUTO_SCALE_THRESHOLD / 2) )); then
        echo "Traffic is low ($current_traffic_kb KB). Scaling down resources."
        $SCALE_DOWN_COMMAND || { echo "Failed to scale down resources."; }
        return
    fi

    # Scale up if traffic is above threshold
    if (( current_traffic_kb > AUTO_SCALE_THRESHOLD )); then
        echo "Traffic is high ($current_traffic_kb KB). Scaling up resources..."
        $SCALE_UP_COMMAND || { echo "Failed to scale up resources."; }
    else
        echo "Traffic is moderate ($current_traffic_kb KB). No scaling required."
    fi
}

# Check for arguments to setup or remove rate limiting
if [[ "$1" == "remove" ]]; then
    remove_rate_limit
else
    setup_rate_limit
fi

# Start tcpdump to capture traffic on the interface and log packets
echo "Starting network traffic monitoring..."
sudo tcpdump -i "$INTERFACE" -w "$TCPDUMP_LOG" -c 10 2> /dev/null &
TCPDUMP_PID=$!

# Start iftop to monitor traffic in real time and log output
echo "Starting iftop on $INTERFACE for real-time monitoring..."
sudo iftop -i "$INTERFACE" -t > "$IFTOP_LOG" &

# Monitor and analyze traffic continuously
while true; do
    sleep 5
    detect_and_block_ddos
    log_honeypot_data
    auto_scale
done

# Cleanup
trap "kill $TCPDUMP_PID; exit" SIGINT
