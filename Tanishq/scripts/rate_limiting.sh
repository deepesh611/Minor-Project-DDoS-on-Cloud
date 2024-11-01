#!/bin/bash

# Variables
INTERFACE="enp0s3"             # Network interface to apply rate limiting
RATE_LIMIT="1mbit"           # Max rate allowed (adjust based on your needs, e.g., "1mbit" or "500kbit")
BURST_SIZE="32k"             # Burst size (buffer size before traffic gets limited)
LIMIT="1000"                 # Queue size limit in packets (higher limit for larger buffers)

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

# Function to remove rate limiting (useful for debugging or testing)
remove_rate_limit() {
    echo "Removing rate limiting from interface $INTERFACE..."
    sudo tc qdisc del dev "$INTERFACE" root
    echo "Rate limiting removed from interface $INTERFACE."
}

# Check for arguments to setup or remove rate limiting
if [ "$1" == "remove" ]; then
    remove_rate_limit
else
    setup_rate_limit
fi
