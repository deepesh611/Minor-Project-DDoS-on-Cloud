#!/bin/bash

# Function to check if a command is successful
check_command() {
  if [ $? -ne 0 ]; then
    echo "Error: $1"
    exit 1
  fi
}

# Create the log directory with sudo and change ownership
sudo mkdir -p /var/log/ddos_monitor
check_command "Failed to create log directory. Check permissions."

sudo chown parrot:parrot /var/log/ddos_monitor
check_command "Failed to change ownership of log directory."

# Directory to store logs
LOG_DIR="/var/log/ddos_monitor"

# Set up log files
TCPDUMP_LOG="$LOG_DIR/tcpdump_$(date +'%Y%m%d_%H%M%S').pcap"
IFTOP_LOG="$LOG_DIR/iftop_log.txt"
ALERT_LOG="$LOG_DIR/ddos_alerts.log"

# Function to list network interfaces
list_interfaces() {
  echo "Available network interfaces:"
  ip link show | awk -F: '/^[0-9]+: / {print $2}' | awk '{$1=$1};1'  # List interfaces without leading/trailing whitespace
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

# Function to check if a process is running
is_process_running() {
    ps -p "$1" > /dev/null 2>&1
}

# Threshold for packet count per IP (adjust as needed)
PACKET_THRESHOLD=10

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

# Start tcpdump to capture traffic on the interface and log packets
echo "Starting tcpdump on $INTERFACE..."
if ! sudo tcpdump -i "$INTERFACE" -w "$TCPDUMP_LOG" &> /dev/null 2>&1
then
  echo "Error: Failed to start tcpdump. Attempting to restart network services."
  sudo systemctl restart NetworkManager
  check_command "Failed to restart network services. Please check your system."
  
  # Retry starting tcpdump
  echo "Retrying to start tcpdump on $INTERFACE..."
  if ! sudo tcpdump -i "$INTERFACE" -w "$TCPDUMP_LOG" &> /dev/null & then
    echo "Error: tcpdump failed to start again. Please check the interface name and permissions."
    exit 1
  fi
fi
TCPDUMP_PID=$!

# Give tcpdump a moment to start
sleep 2

# Start iftop to monitor traffic in real time and log output
echo "Starting iftop on $INTERFACE for real-time monitoring..."
if ! sudo iftop -i "$INTERFACE" -t > "$IFTOP_LOG" & then
  echo "Error: Failed to start iftop. Attempting to restart network services."
  sudo systemctl restart NetworkManager
  check_command "Failed to restart network services. Please check your system."

  # Retry starting iftop
  echo "Retrying to start iftop on $INTERFACE..."
  if ! sudo iftop -i "$INTERFACE" -t > "$IFTOP_LOG" & then
    echo "Error: iftop failed to start again. Please check the interface name and permissions."
    kill $TCPDUMP_PID
    exit 1
  fi
fi
IFTOP_PID=$!

# Monitor for a specified period, then check logs (run for 5 minutes here)
MONITOR_DURATION=120
echo "Monitoring traffic for $MONITOR_DURATION seconds..."
sleep "$MONITOR_DURATION"

# Stop tcpdump and iftop after monitoring period
echo "Stopping tcpdump and iftop..."
kill $TCPDUMP_PID
kill $IFTOP_PID

# Analyze tcpdump logs for high packet rates
check_ddos_suspects

# Display final log locations
echo "Logs saved:"
echo " - tcpdump log: $TCPDUMP_LOG"
echo " - iftop log: $IFTOP_LOG"
echo " - Alert log for high traffic IPs: $ALERT_LOG"
