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
echo "Installing common utilities: git, net-tools" | tee -a "$LOG_FILE"
dnf install git net-tools -y | tee -a "$LOG_FILE"
check_status "Installing common utilities"

# Install MariaDB server if not already installed
if ! rpm -q mariadb105-server &>/dev/null; then
    echo "Installing MariaDB server" | tee -a "$LOG_FILE"
    dnf install mariadb105-server -y | tee -a "$LOG_FILE"
    check_status "Installing MariaDB server"
else
    echo "MariaDB server is already installed." | tee -a "$LOG_FILE"
fi

# Start and enable MariaDB service
sudo systemctl start mariadb | tee -a "$LOG_FILE"
check_status "Starting MariaDB service"

sudo systemctl enable mariadb | tee -a "$LOG_FILE"
check_status "Enabling MariaDB service"

sudo systemctl status mariadb | tee -a "$LOG_FILE"
check_status "Checking MariaDB service status"

# Grant privileges to 'root' user
echo "Granting full access to 'root'@'%' in MySQL" | tee -a "$LOG_FILE"
mysql -u root -p -e "GRANT ALL PRIVILEGES ON *.* TO 'root'@'%' IDENTIFIED BY 'RoboShop@1' WITH GRANT OPTION; FLUSH PRIVILEGES;" | tee -a "$LOG_FILE"
check_status "Granting full access to 'root'@'%'"

echo "MariaDB installation and configuration completed successfully." | tee -a "$LOG_FILE"
