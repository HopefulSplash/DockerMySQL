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

# Function to load configuration from a file
load_configuration() {
  if [ -f "$config_file" ]; then
    source "$config_file"
  else
    handle_error "Configuration file '$config_file' not found."
  fi
}

# Function to handle errors
handle_error() {
  echo -e "\e[1;31mError:\e[0m $1"
  exit 1
}

# Function to replace x lines of existing_sql_file with the content of template_sql
replace_lines() {
  head -n "$lines_to_copy" "$template_sql" > "$existing_sql_file.tmp" && tail -n +"$((lines_to_copy + 1))" "$existing_sql_file" >> "$existing_sql_file.tmp"
  mv "$existing_sql_file.tmp" "$existing_sql_file"
}

load_configuration

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

# Debugging: Display loaded configuration
echo -e "${YELLOW}${BOLD}Fetching current configuration values from $existing_sql_file...${NC}"
loading_bar 0.02
echo
echo -e "${PURPLE}${BOLD}Current Configuration Values${NC}"
echo -e "${GREY}${BOLD}mysql_container${NC}:${WHITE}${BOLD} $mysql_container${NC}"
echo -e "${GREY}${BOLD}mysql_user${NC}:${WHITE}${BOLD} $mysql_user${NC}"
echo -e "${GREY}${BOLD}mysql_password${NC}:${WHITE}${BOLD} $mysql_password${NC}"
echo -e "${GREY}${BOLD}mysql_root_password${NC}:${WHITE}${BOLD} $mysql_root_password${NC}"
echo -e "${GREY}${BOLD}mysql_database${NC}:${WHITE}${BOLD} $mysql_database${NC}"
echo -e "${GREY}${BOLD}backup_dir${NC}:${WHITE}${BOLD} $backup_dir${NC}"
echo -e "${GREY}${BOLD}backup_retention_days${NC}:${WHITE}${BOLD} $backup_retention_days${NC}"

# Your SQL file to copy from
existing_sql_file="./docker/sql/init.sql"

# Your SQL template file with placeholders
template_sql="./docker/sql/template.sql"

# Your final SQL script
sql_script="./docker/sql/init.sql"

# Number of lines to copy from init.sql
lines_to_copy=14  # Change this according to your needs

# Check if init.sql file exists
if [ ! -f "$existing_sql_file" ]; then
  handle_error "init.sql file not found."
fi

# Copy x lines from init.sql into template.sql
if [ ! -f "$template_sql" ]; then
  head -n "$lines_to_copy" "$existing_sql_file" > "$template_sql"
fi

# Set the maximum number of iterations
max_iterations=5  # Set the desired maximum number of iterations

# Loop to replace lines
for ((iteration = 1; iteration <= max_iterations; iteration++)); do
  replace_lines
done

# Replace placeholders in the template file using awk
echo
echo -e "${YELLOW}${BOLD}Processing new configuration values and storing into $existing_sql_file...${NC}"
loading_bar 0.05

awk -v db="$mysql_database" -v user="$mysql_user" -v rootpassword="$mysql_root_password" -v password="$mysql_password" '
    { 
    gsub(/<mysql_database>/, db); 
    gsub(/<mysql_user>/, user); 
    gsub(/<mysql_password>/, password); 
    gsub(/<mysql_root_password>/, rootpassword); 
    print
    }
' "$existing_sql_file" > "$existing_sql_file.tmp" && mv "$existing_sql_file.tmp" "$existing_sql_file"

echo
echo -e "${GREEN}${BOLD}New Configuration Values${NC}"
echo -e "${GREY}${BOLD}mysql_container${NC}:${WHITE}${BOLD} $mysql_container${NC}"
echo -e "${GREY}${BOLD}mysql_user${NC}:${WHITE}${BOLD} $mysql_user${NC}"
echo -e "${GREY}${BOLD}mysql_password${NC}:${WHITE}${BOLD} $mysql_password${NC}"
echo -e "${GREY}${BOLD}mysql_root_password${NC}:${WHITE}${BOLD} $mysql_root_password${NC}"
echo -e "${GREY}${BOLD}mysql_database${NC}:${WHITE}${BOLD} $mysql_database${NC}"
echo -e "${GREY}${BOLD}backup_dir${NC}:${WHITE}${BOLD} $backup_dir${NC}"
echo -e "${GREY}${BOLD}backup_retention_days${NC}:${WHITE}${BOLD} $backup_retention_days${NC}"


# Display your final message with the execution time
end_time=$(date +%s)
execution_message=$(calculate_execution_time "$start_time" "$end_time")

echo
echo -e "${GREEN}${BOLD}Script finished successfully.${NC}${BOLD} Execution time: ${execution_message}.${NC}"
echo
log_message "${GREEN}${BOLD}Script finished successfully.${NC}${BOLD} Execution time: ${execution_message}.${NC}"