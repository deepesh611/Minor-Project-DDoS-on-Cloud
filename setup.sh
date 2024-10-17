#!/bin/bash


# Check if Python is installed
if ! command -v python3 &>/dev/null; then
    echo -e "\033[0;36mPython3\033[0;31m is not installed.\033[0m"   
    exit 1
else
    if ! python --version &>/dev/null; then
        python3 --version
    else
        python --version
    fi
    echo ""
fi


# Check if pip is installed
if ! command -v pip &>/dev/null; then
    echo -e "\033[0;36mpip\033[0;31m is not installed.\033[0m"       
    exit 1
else
    pip --version
    echo ""
fi


# Start pip installation
if pip3 install -r ./src/requirements.txt; then
    # Display completion message in green
    echo -e "\033[0;32m\nSetup Complete\033[0m"
    
else
    # Display error message in red
    echo -e "\033[0;31m\nFailed to install modules.\033[0m"
    # exit 1                                                      
fi

# Pause for 1 second
sleep 1
    
# Display prompt message in yellow
echo -e "\033[0;35m\nPress Enter to continue... \033[0m"
    
# Read user input
read -r
