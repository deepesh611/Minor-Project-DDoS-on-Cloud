#!/bin/bash

# Installatiion 
if ! command -v iftop &> /dev/null
then
    #echo "iftop not fouund, installing..."
    sudo appt install -y iftop 2> /dev/null
fi

# Variables
RATE_LIMIT="1mbit"           # Max rate allowed (adjust based on your needs)
BURST_SIZE="32k"             # Burst size
LIMIT="1000"                 # Queue size limit in packets
PACKET_THRESHOLD=10          # Threshold for packet count per IP
LOG_DIR="$HOME/Desktop/DDOS/ddos_monitor" # Directory to store logs

# Function to check if a command is successful
check_command() {
  if [ $? -ne 0 ]; then
    echo "Error: $1"
    exit 1
  fi
}

# Create the log directory with sudo and change ownership
sudo mkdir -p "$LOG_DIR"
check_command "Failed to create log directory. Check permissions."

# Set up log files
TCPDUMP_LOG="$LOG_DIR/tcpdump_$(date +'%Y%m%d_%H%M%S').pcap"
IFTOP_LOG="$LOG_DIR/iftop_log.txt"
ALERT_LOG="$LOG_DIR/ddos_alerts.log"
BLACKLIST_LOG="$LOG_DIR/blacklist_ips.log"

# Function to list network interfaces
list_interfaces() {
  echo "Available network interfaces:"
  ip link show | awk -F: '/^[0-9]+: / {print $2}' | awk '{$1=$1};1'
}

# Function to prompt user to select an interface
select_interface() {
  list_interfaces
  read -p "Enter the interface you want to monitor: " interface
  INTERFACE="$interface"
}

# Prompt the user to select an interface
select_interface

# Function to check if the interface exists
check_interface() {
  if ! ip link show "$INTERFACE" &> /dev/null; then
    echo "Error: Network interface '$INTERFACE' not found. Please check the interface name."
    exit 1
  fi
}

# Check if the network interface is valid
check_interface

# Function to set up rate limiting
setup_rate_limit() {
    echo "Setting up rate limiting on interface $INTERFACE with max rate $RATE_LIMIT and burst $BURST_SIZE..."

    # Clear any existing traffic control rules on the interface
    sudo tc qdisc del dev "$INTERFACE" root 2>/dev/null

    # Add rate limiting with a token bucket filter
    sudo tc qdisc add dev "$INTERFACE" root handle 1: htb default 10
    sudo tc class add dev "$INTERFACE" parent 1: classid 1:1 htb rate "$RATE_LIMIT" burst "$BURST_SIZE"

    # Add a filter for traffic limiting based on the default class
    sudo tc filter add dev "$INTERFACE" protocol ip parent 1: prio 1 u32 match ip src 0.0.0.0/0 flowid 1:1

    echo "Rate limiting applied on interface $INTERFACE with max rate $RATE_LIMIT."
}

# Function to remove rate limiting
remove_rate_limit() {
    echo "Removing rate limiting from interface $INTERFACE..."
    sudo tc qdisc del dev "$INTERFACE" root
    echo "Rate limiting removed from interface $INTERFACE."
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

# Function to check high packet rate for potential DDoS IPs
check_ddos_suspects() {
  echo "Checking for high traffic IPs..."
  if ! sudo tcpdump -r "$TCPDUMP_LOG" -n | awk '{print $3}' | grep -oE '^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+' | \
    sort | uniq -c | awk -v threshold="$PACKET_THRESHOLD" '$1 > threshold {print $2 " - " $1 " packets"}' >> "$ALERT_LOG"; then
    echo "Error: Failed to analyze tcpdump log for DDoS suspects."
  else
    echo "Suspicious IPs (if any) logged to $ALERT_LOG"
  fi
}

# Check for arguments to setup or remove rate limiting
if [ "$1" == "remove" ]; then
    remove_rate_limit
else
    setup_rate_limit
fi

# Start tcpdump to capture traffic on the interface and log packets
echo "Starting tcpdump on $INTERFACE..."
if ! sudo tcpdump -i "$INTERFACE" -w "$TCPDUMP_LOG" -c 10 &> /dev/null 2>&1; then
  echo "Error: Failed to start tcpdump. Attempting to restart network services."
  sudo systemctl restart NetworkManager
  check_command "Failed to restart network services. Please check your system."

  # Retry starting tcpdump
  echo "Retrying to start tcpdump on $INTERFACE..."
  if ! sudo tcpdump -i "$INTERFACE" -w "$TCPDUMP_LOG" -c 10 &> /dev/null & then
    echo "Error: tcpdump failed to start again. Please check the interface name and permissions."
    exit 1
  fi
fi
TCPDUMP_PID=$!

# Start iftop to monitor traffic in real time and log output
echo "Starting iftop on $INTERFACE for real-time monitoring..."
if ! sudo iftop -i "$INTERFACE" -t -s 120 -L 10 > "$IFTOP_LOG" 
then
  echo "Error: Failed to start iftop. Attempting to restart network services."
  sudo systemctl restart NetworkManager
  check_command "Failed to restart network services. Please check your system."

  # Retry starting iftop
  echo "Retrying to start iftop on $INTERFACE..."
  if ! sudo iftop -i "$INTERFACE" -t > "$IFTOP_LOG" & then
    echo "Error: iftop failed to start again. Please check the interface name and permissions."
    kill "$TCPDUMP_PID"
    exit 1
  fi
fi

IFTOP_PID=$!

# Function to log messages to syslog
log_syslog() {
    local message="$1"
    logger -t "$LOG_TAG" "$message"
}

# Function to check for high packet rate IPs and block them
detect_and_block_ddos() {
    # Capture network traffic temporarily
    sudo tcpdump -i "$INTERFACE" -w "$TCPDUMP_LOG" -c 10 2>/dev/null

    # Find IPs with packet counts above the threshold
    sudo tcpdump -r "$TCPDUMP_LOG" -n | awk '{print $3}' | grep -oE '^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+' | \
    sort | uniq -c | awk -v threshold="$PACKET_THRESHOLD" '$1 > threshold {print $2}' | while read -r ip; do
        # Log detected DDoS attempt
        log_syslog "Detected potential DDoS attack from IP: $ip with packet count exceeding $PACKET_THRESHOLD"
        
        # Add the IP to iptables if not already blocked
        if ! sudo iptables -C INPUT -s "$ip" -j DROP 2>/dev/null; then
            sudo iptables -A INPUT -s "$ip" -j DROP
            log_syslog "Blocked IP: $ip due to suspected DDoS activity"
        fi
    done

    # Remove the temporary tcpdump log file
    rm -f "$TCPDUMP_LOG"
}

# Monitor and detect DDoS attempts every 5 minutes
while true; do
    log_syslog "Starting DDoS detection on $INTERFACE"
    detect_and_block_ddos
    log_syslog "DDoS detection cycle completed, sleeping for 5 minutes"
    sleep 300
done


#coundown function
countdown() {
    local seconds=$1
    while [[ $seconds -gt 0  ]]
    do 
        echo -ne "Monitoring in progress... Time remaining: ${seconds}s\033[0K\r"
        sleep 1
        ((seconds--))
    done
}

coundown 180

# Stop tcpdump and iftop after monitoring period
echo "Stopping tcpdump and iftop..."
kill "$TCPDUMP_PID"
kill "$IFTOP_PID"

# Analyze tcpdump logs for high packet rates
check_ddos_suspects

# Display final log locations
echo "Logs saved:"
echo " - tcpdump log: $TCPDUMP_LOG"
echo " - iftop log: $IFTOP_LOG"
echo " - Alert log for high traffic IPs: $ALERT_LOG"

# Display log contents
echo -e "\n--- IFTOP LOG ---"
cat "$IFTOP_LOG"

echo -e "\n--- ALERT LOG ---"
cat "$ALERT_LOG"

echo -e "\n--- Blacklist log ---"
cat "$BLACKLIST_LOG"

