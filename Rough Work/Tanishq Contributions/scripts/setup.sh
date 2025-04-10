#!/bin/bash

# Define log files for installation
INSTALL_LOG="$HOME/Desktop/DDOS/install.log"
SCALE_UP_LOG="$HOME/Desktop/DDOS/scale_up.log"
SCALE_DOWN_LOG="$HOME/Desktop/DDOS/scale_down.log"

# Function to log messages
log_message() {
    echo "$(date +'%Y-%m-%d %H:%M:%S') - $1" >> "$INSTALL_LOG"
}

# Update package list and install necessary packages
log_message "Updating package list and installing necessary packages..."
sudo apt update -y >> "$INSTALL_LOG" 2>&1
sudo apt install -y awscli iftop tcpdump >> "$INSTALL_LOG" 2>&1

# Check if AWS CLI is installed
if ! command -v aws &> /dev/null; then
    log_message "AWS CLI could not be installed. Please check the installation logs."
    exit 1
fi

# Configure AWS CLI
log_message "Configuring AWS CLI..."
read -p "Enter your AWS Access Key: " AWS_ACCESS_KEY
read -p "Enter your AWS Secret Key: " AWS_SECRET_KEY
read -p "Enter your AWS Region (e.g., us-east-1): " AWS_REGION

aws configure set aws_access_key_id "$AWS_ACCESS_KEY" >> "$INSTALL_LOG" 2>&1
aws configure set aws_secret_access_key "$AWS_SECRET_KEY" >> "$INSTALL_LOG" 2>&1
aws configure set default.region "$AWS_REGION" >> "$INSTALL_LOG" 2>&1

# Create scaling scripts
cat << 'EOF' > "$HOME/Desktop/DDOS/scale_up.sh"
#!/bin/bash
LOG_FILE="$HOME/Desktop/DDOS/scale_up.log"
scale_up() {
    echo "$(date +'%Y-%m-%d %H:%M:%S') - Scaling up resources..." >> "$LOG_FILE"
    INSTANCE_ID=$(aws ec2 run-instances --image-id ami-xxxxxxxx --count 1 --instance-type t2.micro --key-name MyKeyPair --query "Instances[0].InstanceId" --output text)
    if [ $? -eq 0 ]; then
        echo "$(date +'%Y-%m-%d %H:%M:%S') - Launched new instance: $INSTANCE_ID" >> "$LOG_FILE"
        echo "$(date +'%Y-%m-%d %H:%M:%S') - Resources scaled up successfully." >> "$LOG_FILE"
    else
        echo "$(date +'%Y-%m-%d %H:%M:%S') - Failed to scale up resources." >> "$LOG_FILE"
    fi
}
scale_up
EOF

cat << 'EOF' > "$HOME/Desktop/DDOS/scale_down.sh"
#!/bin/bash
LOG_FILE="$HOME/Desktop/DDOS/scale_down.log"
scale_down() {
    echo "$(date +'%Y-%m-%d %H:%M:%S') - Scaling down resources..." >> "$LOG_FILE"
    INSTANCE_ID="i-xxxxxxxxxxxx"  # Replace with the actual instance ID or use a method to fetch an instance ID dynamically
    aws ec2 terminate-instances --instance-ids $INSTANCE_ID
    if [ $? -eq 0 ]; then
        echo "$(date +'%Y-%m-%d %H:%M:%S') - Terminated instance: $INSTANCE_ID" >> "$LOG_FILE"
        echo "$(date +'%Y-%m-%d %H:%M:%S') - Resources scaled down successfully." >> "$LOG_FILE"
    else
        echo "$(date +'%Y-%m-%d %H:%M:%S') - Failed to scale down resources." >> "$LOG_FILE"
    fi
}
scale_down
EOF

# Make scripts executable
chmod +x "$HOME/Desktop/DDOS/scale_up.sh" "$HOME/Desktop/DDOS/scale_down.sh"

# Notify user of completion
log_message "Installation and configuration completed successfully."
echo "Setup is complete. Check the log file at $INSTALL_LOG for details."
