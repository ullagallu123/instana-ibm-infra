#!/bin/bash

# Get the script's name without the path and extension
SCRIPT_NAME=$(basename "$0" .sh)

# Define the log file
LOG_FILE="/tmp/${SCRIPT_NAME}_$(date +'%Y%m%d_%H%M%S').log"

# Function to check command execution status
check_status() {
    if [ $? -ne 0 ]; then
        echo "Error: $1 failed. Check the log for details." | tee -a "$LOG_FILE"
        exit 1
    else
        echo "$1 succeeded." | tee -a "$LOG_FILE"
    fi
}

# Check for sudo privileges
if [ "$(id -u)" -ne 0 ]; then
    echo "This script requires sudo privileges. Please run as root or use sudo." | tee -a "$LOG_FILE"
    exit 1
fi

# Install common utilities
echo "Installing common utilities: git, net-tools, telnet" | tee -a "$LOG_FILE"
sudo yum install -y git net-tools telnet | tee -a "$LOG_FILE"
check_status "Installing common utilities"

# Create MongoDB repo file if it does not exist
if [ ! -f /etc/yum.repos.d/mongodb-org-7.0.repo ]; then
    cat <<EOL | tee /etc/yum.repos.d/mongodb-org-7.0.repo | tee -a "$LOG_FILE"
[mongodb-org-7.0]
name=MongoDB Repository
baseurl=https://repo.mongodb.org/yum/amazon/2023/mongodb-org/7.0/x86_64/
gpgcheck=1
enabled=1
gpgkey=https://pgp.mongodb.com/server-7.0.asc
EOL
    check_status "Creating MongoDB repo file"
else
    echo "MongoDB repo file already exists." | tee -a "$LOG_FILE"
fi

# Install MongoDB if not already installed
if ! rpm -q mongodb-org &>/dev/null; then
    sudo yum install -y mongodb-org | tee -a "$LOG_FILE"
    check_status "Installing MongoDB"
else
    echo "MongoDB is already installed." | tee -a "$LOG_FILE"
fi

# Update listen address in /etc/mongod.conf
if grep -q '127.0.0.1' /etc/mongod.conf; then
    sudo sed -i 's/127.0.0.1/0.0.0.0/' /etc/mongod.conf | tee -a "$LOG_FILE"
    check_status "Updating listen address in mongod.conf"
else
    echo "Listen address already set to 0.0.0.0 in mongod.conf." | tee -a "$LOG_FILE"
fi

# Enable and start MongoDB service
sudo systemctl enable mongod | tee -a "$LOG_FILE"
check_status "Enabling mongod service"

sudo systemctl start mongod | tee -a "$LOG_FILE"
check_status "Starting mongod service"

sudo systemctl daemon-reload | tee -a "$LOG_FILE"
check_status "Reloading systemd daemon"

sudo systemctl status mongod | tee -a "$LOG_FILE"
check_status "Checking mongod service status"

# Optional commands for information
# Uncomment if needed
# mongosh
# sudo rm -r /var/log/mongodb
# sudo rm -r /var/lib/mongo

echo "MongoDB installation and configuration completed successfully." | tee -a "$LOG_FILE"
