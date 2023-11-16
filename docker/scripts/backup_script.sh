#!/bin/bash

# Read MySQL database credentials from secret files
DB_USER=$(cat /run/secrets/bookshop_mysql_user)
DB_PASSWORD=$(cat /run/secrets/bookshop_mysql_password)
DB_NAME=$(cat /run/secrets/bookshop_mysql_database)

# Define the MySQL hostname as an environment variable (or use the default)
MYSQL_HOST="${MYSQL_HOST:-mysql}"

# Backup directory within the container
BACKUP_DIR="/backups"

# Timestamp for the backup file
TIMESTAMP=$(date +%Y%m%d%H%M%S)
BACKUP_FILE="$BACKUP_DIR/backup_$TIMESTAMP.sql"

# Perform the database backup using mysqldump
mysqldump -h $MYSQL_HOST -u $DB_USER -p $DB_PASSWORD $DB_NAME > $BACKUP_FILE

# Check if the backup was successful
if [ $? -eq 0 ]; then
  echo "Database backup successful. Backup saved to: $BACKUP_FILE"
else
  echo "Error: Database backup failed."
fi
