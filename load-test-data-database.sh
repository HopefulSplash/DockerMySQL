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
  echo "mysql_container=\"$mysql_container\"" > "$config_file"
  echo "mysql_user=\"$mysql_user\"" >> "$config_file"
  echo "mysql_password=\"$mysql_password\"" >> "$config_file"
  echo "mysql_database=\"$mysql_database\"" >> "$config_file"
  echo "backup_dir=\"$backup_dir\"" >> "$config_file"
  echo "backup_retention_days=\"$backup_retention_days\"" >> "$config_file"
}

# Function to load test data from an SQL file into a MySQL database inside a Docker container
load_test_data() {
  # Path to the SQL file
  local sql_file="./docker/sql/test-data.sql"

  # Check if the SQL file exists
  if [ ! -f "$sql_file" ]; then
    echo -e "${RED}${BOLD}Error: SQL file${NC}${BOLD} '$sql_file' not found." >> "$log_file"
    return 1
  fi

  echo
  echo -e "${YELLOW}${BOLD}Loading test date into the MySQL database...${NC}"
  loading_bar 0.05
  echo

  # Get the MySQL container's IP address and suppress warnings
  mysql_container_ip=$(docker inspect -f '{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}' "$mysql_container" 2>/dev/null)

  # Check if the IP address is empty or not
  if [ -z "$mysql_container_ip" ]; then
    echo -e "${RED}${BOLD}Failed to retrieve MySQL container IP address.${NC}${BOLD} Ensure that the container is running and the name is correct."
    exit 1
  fi

  # Use docker exec to run the MySQL client inside the container and execute the SQL file
  docker exec -i "$mysql_container" mysql -u"$mysql_user" -p"$mysql_password" -h"$mysql_container_ip" "$mysql_database" < "$sql_file" 2>> "$log_file"

  # Check the exit status of the mysql command
  local exit_status=$?
  if [ $exit_status -eq 0 ]; then
    echo -e "${GREEN}${BOLD}Test data loaded successfully${NC}${BOLD} from '$sql_file' into database '$mysql_database'." >> "$log_file"
    # Optionally, you can include additional logging or verification steps here
  else
    echo -e "${RED}${BOLD}Error: Failed to load test data${NC}${BOLD} from '$sql_file' into database '$mysql_database'." >> "$log_file"
    # Optionally, you can also log the error to your main log file here if needed
  fi
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

load_configuration

# Main script execution
load_test_data


# Save the configuration
save_configuration

# Display your final message with the execution time
end_time=$(date +%s)
execution_message=$(calculate_execution_time "$start_time" "$end_time")

echo
echo -e "${GREEN}${BOLD}Script finished successfully.${NC}${BOLD} Execution time: ${execution_message}.${NC}"
echo
log_message "${GREEN}${BOLD}Script finished successfully.${NC}${BOLD} Execution time: ${execution_message}.${NC}"