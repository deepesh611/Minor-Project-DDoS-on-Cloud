#!/bin/bash

# Data Extraction Script

# File containing raw honeypot data
CSV_FILE="/home/parrot/Desktop/DDOS/dataset_sdn.csv"  # Make sure this path is correct

# Output directory for processed data
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
