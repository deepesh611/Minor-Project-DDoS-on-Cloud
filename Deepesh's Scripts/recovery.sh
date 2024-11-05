#!/bin/bash

# Define the network interface and threshold
INTERFACE="eth0"  # Change to your network interface
THRESHOLD=10000    # Example threshold (in bytes)
BLOCKED_IP="0.0.0.0"  # Placeholder for the IP to block (will be set later)

# Monitor network traffic
while true; do
    # Get the number of bytes received in the last minute
    RX_BYTES=$(cat /sys/class/net/$INTERFACE/statistics/rx_bytes)
    sleep 60  # Wait for one minute

    # Check the current number of bytes received again
    NEW_RX_BYTES=$(cat /sys/class/net/$INTERFACE/statistics/rx_bytes)
    BYTES_RECEIVED=$((NEW_RX_BYTES - RX_BYTES))

    # If the received bytes exceed the threshold, take action
    if [ "$BYTES_RECEIVED" -gt "$THRESHOLD" ]; then
        echo "Excessive traffic detected! Disconnecting from the network..."

        # Get the IP address with the highest traffic
        BLOCKED_IP=$(sudo tcpdump -i $INTERFACE -n -c 100 | awk '{print $3}' | cut -d'.' -f1-4 | sort | uniq -c | sort -nr | head -n 1 | awk '{print $2}')

        # If an IP was found to block
        if [ -n "$BLOCKED_IP" ]; then
            echo "Blocking IP: $BLOCKED_IP"
            # Block the IP address using iptables
            sudo iptables -A INPUT -s $BLOCKED_IP -j DROP
            sudo iptables -A OUTPUT -d $BLOCKED_IP -j DROP
        fi

        # Disconnect the network interface
        sudo ifconfig $INTERFACE down
        
        # Wait a moment to ensure the interface is fully down
        sleep 5
        
        echo "Reconnecting to the network..."
        # Reconnect the network interface
        sudo ifconfig $INTERFACE up

        echo "Network reconnected. Traffic from $BLOCKED_IP is blocked."
    fi
done
