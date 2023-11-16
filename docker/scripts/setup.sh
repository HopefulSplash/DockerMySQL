#!/bin/bash

# Log file for this script
SCRIPT_LOG="/var/log/setup_script.log"

# Function to log messages to the script log
log_message() {
    local message="$1"
    echo "$(date +"%Y-%m-%d %H:%M:%S"): $message" >> "$SCRIPT_LOG"
}

# Check if the custom cron job already exists
if [ ! -f "/etc/cron.d/my-cron-job" ]; then
    # Check if cron is already installed
    if ! command -v cron &>/dev/null; then
        log_message "Installing cron..."
        apt-get update >> "$SCRIPT_LOG" 2>&1
        apt-get install -y cron >> "$SCRIPT_LOG" 2>&1
    fi

    log_message "Custom cron job does not exist, creating it..."

    # Create the log file if it doesn't exist
    touch /var/log/cron.log
    chmod 644 /var/log/cron.log

    # Create a custom cron job file to run your backup script daily at midnight
    echo "0 0 * * * root /bin/bash -c '/scripts/backup_script.sh >> /var/log/cron.log 2>&1'" > /etc/cron.d/my-cron-job

    # Start cron
    service cron start >> "$SCRIPT_LOG" 2>&1

    log_message "Custom cron job created, cron service started, and log file created."
else
    log_message "Custom cron job already exists."
fi

# Check if MySQL client tools (mysqldump) are installed
if ! command -v mysqldump &>/dev/null; then
    log_message "Installing MySQL client tools (mysqldump)..."
    apt-get install -y mysql-client >> "$SCRIPT_LOG" 2>&1
fi

# Make the backup script executable
chmod +x ./scripts/backup_script.sh

# Keep the container running
tail -f /dev/null