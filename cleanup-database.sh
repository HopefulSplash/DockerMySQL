#!/bin/bash
start_time=$(date +%s)

# Function to calculate and format execution time
calculate_execution_time() {
  local start_time="$1"
  local end_time="$2"
  
  local duration=$((end_time - start_time))
  local execution_message=""
  
  local seconds=$((duration % 60))
  local minutes=$((duration / 60 % 60))
  local hours=$((duration / 3600))
  
  if ((hours > 0)); then
    execution_message="${hours} hours"
  fi
  
  if ((minutes > 0)); then
    if [ -n "$execution_message" ]; then
      execution_message="${execution_message}, "
    fi
    execution_message="${execution_message}${minutes} minutes"
  fi
  
  if ((seconds > 0)); then
    if [ -n "$execution_message" ]; then
      execution_message="${execution_message}, "
    fi
    execution_message="${execution_message}${seconds} seconds"
  fi
  
  if [ -z "$execution_message" ]; then
    execution_message="less than 1 second"
  fi
  
  echo "$execution_message"
}

# Function to create a loading bar on the same line
loading_bar() {
  local duration="$1"
  local width=30  # Width of the loading bar
  local progress=0

  while [ "$progress" -le 100 ]; do
    local num_chars="$((progress * width / 100))"
    local bar="["

    for ((i = 0; i < num_chars; i++)); do
      bar+="="
    done

    for ((i = num_chars; i < width; i++)); do
      bar+=" "
    done

    bar+="] $progress%"
    echo -en "\r${BLUE}${bar}${NC}"
    progress=$((progress + 2))
    sleep "$duration"
  done

  # After completion, print a newline to move to the next line
  echo
}


config_file="./config/backup-config.sh"
log_file="./logs/log.txt"

# Function to log messages to the log file
log_message() {
  local message="$1"
  echo "$(date +'%Y-%m-%d %H:%M:%S') - $message" >> "$log_file"
}

# Initialize log file and directory
mkdir -p "$(dirname "$log_file")"
touch "$log_file"

# Function to handle errors
handle_error() {
  local message="$1"
  echo "Error: $message"
  log_message "Error: $message"
  exit 1
}

# Function to load configuration from a file
load_configuration() {
  if [ -f "$config_file" ]; then
    source "$config_file"
  else
    handle_error "Configuration file '$config_file' not found."
  fi
}

# Function to save configuration to a file
save_configuration() {
  echo -e "${GREY}${BOLD}mysql_container=\"$mysql_container\"" > "$config_file${NC}${BOLD}"
  echo -e "${GREY}${BOLD}mysql_user=\"$mysql_user\"" >> "$config_file${NC}${BOLD}"
  echo -e "${GREY}${BOLD}mysql_password=\"$mysql_password\"" >> "$config_file${NC}${BOLD}"
  echo -e "${GREY}${BOLD}mysql_database=\"$mysql_database\"" >> "$config_file${NC}${BOLD}"
  echo -e "${GREY}${BOLD}backup_dir=\"$backup_dir\"" >> "$config_file${NC}${BOLD}"
  echo -e "${GREY}${BOLD}backup_retention_days=\"$backup_retention_days\"" >> "$config_file${NC}${BOLD}"
}

clear_database_table_data() {
  echo
  echo -e "${YELLOW}${BOLD}Cleaning up the MySQL database...${NC}"
  loading_bar 0.05
  echo

  # Store the original file descriptors for stdout and stderr
  exec 3>&1
  exec 4>&2

  # Redirect all output to the log file
  exec >> "$log_file" 2>&1

  # Get the MySQL container's IP address and suppress warnings
  mysql_container_ip=$(docker inspect -f '{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}' "$mysql_container" 2>/dev/null)

  # Check if the IP address is empty or not
  if [ -z "$mysql_container_ip" ]; then
    echo "${RED}${BOLD}Failed to retrieve MySQL container IP address. Ensure that the container is running and the name is correct.${NC}${BOLD}"
    exit 1
  fi

  # Disable foreign key checks and suppress output
  docker exec -i "$mysql_container" mysql -u"$mysql_user" -p"$mysql_password" -h"$mysql_container_ip" -e "SET FOREIGN_KEY_CHECKS=0;" 2>/dev/null

  # Get a list of tables in the database
  tables=$(docker exec -i "$mysql_container" mysql -u"$mysql_user" -p"$mysql_password" -h"$mysql_container_ip" -e "USE $mysql_database; SHOW TABLES;" | grep -v "Tables_in_")

  # Truncate tables while handling foreign key constraints and suppress output
  for table in $tables; do
    docker exec -i "$mysql_container" mysql -u"$mysql_user" -p"$mysql_password" -h"$mysql_container_ip" -e "USE $mysql_database; SET FOREIGN_KEY_CHECKS=0; TRUNCATE TABLE $table; SET FOREIGN_KEY_CHECKS=1;" 2>/dev/null
  done

  # Restore the original file descriptors for stdout and stderr
  exec 1>&3
  exec 2>&4

  echo -e "${GREEN}${BOLD}MySQL database cleanup completed.${NC}"
  echo
}

wipe_entire_database() {
  echo
  echo -e "${YELLOW}${BOLD}Wiping the entire MySQL database...${NC}"
  loading_bar 0.05
  echo

  # Store the original file descriptors for stdout and stderr
  exec 3>&1
  exec 4>&2

  # Redirect all output to the log file
  exec >> "$log_file" 2>&1

  # Get the MySQL container's IP address and suppress warnings
  mysql_container_ip=$(docker inspect -f '{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}' "$mysql_container" 2>/dev/null)

  # Check if the IP address is empty or not
  if [ -z "$mysql_container_ip" ]; then
    echo "${RED}${BOLD}Failed to retrieve MySQL container IP address. Ensure that the container is running and the name is correct.${NC}${BOLD}"
    exit 1
  fi

  # Drop the entire database and recreate it
  docker exec -i "$mysql_container" mysql -u"$mysql_user" -p"$mysql_password" -h"$mysql_container_ip" -e "DROP DATABASE IF EXISTS $mysql_database; CREATE DATABASE $mysql_database;" 2>/dev/null

  # Restore the original file descriptors for stdout and stderr
  exec 1>&3
  exec 2>&4

  echo -e "${GREEN}${BOLD}MySQL database wiped and recreated.${NC}"
  echo
}

list_and_clear_tables() {
  echo
  echo -e "${YELLOW}${BOLD}Listing tables in the MySQL database...${NC}"
  loading_bar 0.05
  echo

  # Get the MySQL container's IP address and suppress warnings
  mysql_container_ip=$(docker inspect -f '{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}' "$mysql_container" 2>/dev/null)

  # Check if the IP address is empty or not
  if [ -z "$mysql_container_ip" ]; then
    echo "${RED}${BOLD}Failed to retrieve MySQL container IP address. Ensure that the container is running and the name is correct.${NC}${BOLD}"
    exit 1
  fi

  # Get a list of tables in the database
  tables=$(docker exec -i "$mysql_container" mysql -u"$mysql_user" -p"$mysql_password" -h"$mysql_container_ip" -e "USE $mysql_database; SHOW TABLES;" | grep -v "Tables_in_")

  # Display the list of tables and prompt for table selection
  echo "${WHITE}${BOLD}Tables in the database:${NC}${BOLD}"
  for table in $tables; do
    echo " - $table"
  done
  read -rp "Enter the names of tables to clear (comma-separated): " tables_to_clear

  # Truncate selected tables while handling foreign key constraints and suppress output
  for table in $(echo "$tables_to_clear" | tr ',' ' '); do
    docker exec -i "$mysql_container" mysql -u"$mysql_user" -p"$mysql_password" -h"$mysql_container_ip" -e "USE $mysql_database; SET FOREIGN_KEY_CHECKS=0; TRUNCATE TABLE $table; SET FOREIGN_KEY_CHECKS=1;" 2>/dev/null
  done

  echo -e "${GREEN}${BOLD}Selected tables cleared.${NC}"
  echo
}

# Function to delete the entire MySQL database
delete_entire_database() {
  echo
  echo -e "${YELLOW}${BOLD}Deleting the entire MySQL database...${NC}"
  loading_bar 0.05
  echo

  # Get the MySQL container's IP address and suppress warnings
  mysql_container_ip=$(docker inspect -f '{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}' "$mysql_container" 2>/dev/null)

  # Check if the IP address is empty or not
  if [ -z "$mysql_container_ip" ]; then
    echo "${RED}${BOLD}Failed to retrieve MySQL container IP address. Ensure that the container is running and the name is correct.${NC}${BOLD}"
    exit 1
  fi

  # Drop the entire database
  docker exec -i "$mysql_container" mysql -u"$mysql_user" -p"$mysql_password" -h"$mysql_container_ip" -e "DROP DATABASE IF EXISTS $mysql_database;" 2>/dev/null

  echo -e "${GREEN}${BOLD}MySQL database deleted.${NC}"
  echo
}

# Function to delete the table selected from a MySQL database
list_and_delete_tables() {
  echo
  echo -e "${YELLOW}${BOLD}Listing tables in the MySQL database...${NC}"
  loading_bar 0.05
  echo

  # Get the MySQL container's IP address and suppress warnings
  mysql_container_ip=$(docker inspect -f '{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}' "$mysql_container" 2>/dev/null)

  # Check if the IP address is empty or not
  if [ -z "$mysql_container_ip" ]; then
    echo "${RED}${BOLD}Failed to retrieve MySQL container IP address. Ensure that the container is running and the name is correct.${NC}${BOLD}"
    exit 1
  fi

  # Get a list of tables in the database
  tables=$(docker exec -i "$mysql_container" mysql -u"$mysql_user" -p"$mysql_password" -h"$mysql_container_ip" -e "USE $mysql_database; SHOW TABLES;" | grep -v "Tables_in_")

  # Display the list of tables and prompt for table selection
  echo "Tables in the database:"
  for table in $tables; do
    echo " - $table"
  done
  read -rp "Enter the names of tables to delete (comma-separated): " tables_to_delete

  # Iterate through the selected tables to delete
  for table in $(echo "$tables_to_delete" | tr ',' ' '); do
    # Query foreign key constraints that reference the table to be deleted
    referencing_tables=$(docker exec -i "$mysql_container" mysql -u"$mysql_user" -p"$mysql_password" -h"$mysql_container_ip" -e "SELECT TABLE_NAME, CONSTRAINT_NAME FROM information_schema.KEY_COLUMN_USAGE WHERE REFERENCED_TABLE_NAME = '$table';")

    # Iterate through referencing tables and drop foreign key constraints
    for referencing_info in $referencing_tables; do
      referencing_table=$(echo "$referencing_info" | awk '{print $1}')
      fk_name=$(echo "$referencing_info" | awk '{print $2}')
      if [ -n "$referencing_table" ] && [ -n "$fk_name" ]; then
        docker exec -i "$mysql_container" mysql -u"$mysql_user" -p"$mysql_password" -h"$mysql_container_ip" -e "USE $mysql_database; ALTER TABLE $referencing_table DROP FOREIGN KEY $fk_name;"
        echo -e "${GREEN}${BOLD}Foreign key '$fk_name' in table '$referencing_table' dropped.${NC}"
      fi
    done

    # Delete the table
    delete_output=$(docker exec -i "$mysql_container" mysql -u"$mysql_user" -p"$mysql_password" -h"$mysql_container_ip" -e "USE $mysql_database; DROP TABLE IF EXISTS $table;" 2>&1)

    # Check for errors during deletion
    if [ -n "$delete_output" ]; then
      echo -e "${RED}${BOLD}Error deleting table '$table':${NC}"
      echo "$delete_output"
    else
      echo -e "${GREEN}${BOLD}Table '$table' deleted.${NC}"
    fi
  done

  echo
}

# Function to clean up the MySQL database
cleanup_mysql_database() {

  # Prompt the user for cleanup options
  echo -e "${WHITE}${BOLD}Select an option:${NC}${BOLD}"
  echo
  echo -e "${GREY}${BOLD}1. Wipe all tables in the database${NC}${BOLD}"
  echo -e "${GREY}${BOLD}2. Completely clear the database (drop all tables and data)${NC}${BOLD}"
  echo -e "${GREY}${BOLD}3. Completely delete the database${NC}${BOLD}"
  echo -e "${GREY}${BOLD}4. List tables in the database and choose which ones to clear${NC}${BOLD}"
  echo -e "${GREY}${BOLD}5. List tables in the database and choose which ones to delete${NC}${BOLD}"
  echo

  read -rp "Enter the option number: " option

  case "$option" in
    1)
      clear_database_table_data >> "$log_file"  # Redirecting output to the log file
      ;;
    2)
      wipe_entire_database >> "$log_file"  # Redirecting output to the log file
      ;;
    3)
      delete_entire_database >> "$log_file"  # Redirecting output to the log file
      ;;
    4)
      list_and_clear_tables >> "$log_file"  # Redirecting output to the log file
      ;;
    5)
      list_and_delete_tables >> "$log_file"  # Redirecting output to the log file
      ;;
    *)
      echo
      echo -e "${RED}${BOLD}Invalid option. Please select a valid option.${NC}"
      ;;
  esac

}

# Colors for better formatting
GREEN='\033[0;32m'      # Green
YELLOW='\033[1;33m'     # Yellow
BLUE='\033[0;34m'       # Blue
RED='\033[0;31m'        # Red
ORANGE='\033[0;91m'     # Orange
PURPLE='\033[0;35m'     # Purple
CYAN='\033[0;36m'       # Cyan
WHITE='\033[1;37m'      # White
GREY='\033[0;90m'       # Gray
BOLD='\033[1m'          # Bold
NC='\033[0m'            # No Color

# Main script execution
load_configuration

cleanup_mysql_database

# Save the configuration
save_configuration

# Display your final message with the execution time
end_time=$(date +%s)
execution_message=$(calculate_execution_time "$start_time" "$end_time")

echo
echo -e "${GREEN}${BOLD}Script finished successfully.${NC}${BOLD} Execution time: ${execution_message}.${NC}"
echo
log_message "${GREEN}${BOLD}Script finished successfully.${NC}${BOLD} Execution time: ${execution_message}.${NC}"