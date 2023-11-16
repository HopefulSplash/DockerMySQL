#!/bin/bash
start_time=$(date +%s)

# Read the current values from the configuration file
current_mysql_container=$(read_config "mysql_container")
current_mysql_user=$(read_config "mysql_user")
current_mysql_database=$(read_config "mysql_database")

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

# File path to store configuration
CONFIG_FILE="./config/backup-config.sh"

# Function to read a specific configuration value from the file
read_config() {
    local key="$1"
    local value=$(grep -E "^$key=" "$CONFIG_FILE" | cut -d '=' -f 2)
    echo "$value"
}

# Function to update a specific configuration value in the file
update_config() {
    local key="$1"
    local value="$2"
    # Add double quotes around the value
    value="\"$value\""
    awk -v key="$key" -v new_value="$value" 'BEGIN{FS=OFS="="} $1 == key {$2=new_value}1' "$CONFIG_FILE" > temp_file && mv temp_file "$CONFIG_FILE"
}

update_config_values(){

    # Prompt the user for input
    read -p "Enter the MySQL container name (leave empty to keep current value: $current_mysql_container): " new_mysql_container
    read -p "Enter the MySQL user (leave empty to keep current value: $current_mysql_user): " new_mysql_user
    read -p "Enter the MySQL database name (leave empty to keep current value: $current_mysql_database): " new_mysql_database

    # Update the file with new values if provided
    if [ -n "$new_mysql_container" ]; then
        update_config "mysql_container" "$new_mysql_container"
    fi

    if [ -n "$new_mysql_user" ]; then
        update_config "mysql_user" "$new_mysql_user"
    fi

    if [ -n "$new_mysql_database" ]; then
        update_config "mysql_database" "$new_mysql_database"
    fi
    echo
}

show_current_config_values(){
    # Display the updated configuration
    echo
    echo "Current Configuration:"
    cat "$CONFIG_FILE"
    echo
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

# Title and description
display_title() {
echo -e "${RED}${BOLD}
  _____             _           _____       _ _   _       _ _           _   _              _____           _ _   _     
 |  __ \           | |         |_   _|     (_) | (_)     | (_)         | | (_)            / ____|         (_) | | |    
 | |  | | ___   ___| | _____ _ __| |  _ __  _| |_ _  __ _| |_ ___  __ _| |_ _  ___  _ __ | (___  _ __ ___  _| |_| |__  
 | |  | |/ _ \ / __| |/ / _ \ '__| | | '_ \| | __| |/ _' | | / __|/ _' | __| |/ _ \| '_ \ \___ \| '_ ' _ \| | __| '_ \ 
 | |__| | (_) | (__|   <  __/ | _| |_| | | | | |_| | (_| | | \__ \ (_| | |_| | (_) | | | |____) | | | | | | | |_| | | |
 |_____/ \___/ \___|_|\_\___|_||_____|_| |_|_|\__|_|\__,_|_|_|___/\__,_|\__|_|\___/|_| |_|_____/|_| |_| |_|_|\__|_| |_|
${NC}"
}

display_title

echo -e "${RED}${BOLD}                                     Like a blacksmith forging iron but for Docker!${NC}"
echo
echo -e "${BOLD}${GREY}Welcome to Docker Setup Script! This tool streamlines the process of configuring Docker on your system."
echo -e "It automates critical steps, ensuring you can leverage Docker's power effortlessly.${NC}"
echo
echo -e "${BOLD}${GREY}1.${NC} ${BOLD}${PURPLE}Docker Installation:${NC} ${GREY}Checks for an existing Docker installation and installs it if necessary."
echo -e "   Compatible with Linux, macOS, and Windows.${NC}"
echo
echo -e "${BOLD}${GREY}2.${NC} ${BOLD}${PURPLE}Docker Startup:${NC} ${GREY}Confirms Docker is up and running. If not, it initiates Docker to ensure"
echo -e "   your Docker environment is always ready.${NC}"
echo
echo -e "${BOLD}${GREY}3.${NC} ${BOLD}${PURPLE}Docker Compose Installation:${NC} ${GREY}Checks Docker Compose and installs it if missing."
echo -e "   Docker Compose simplifies managing multi-container applications.${NC}"
echo
echo -e "${GREY}Whether you're new to Docker or an experienced user, our script simplifies the setup"
echo -e "and maintenance, freeing you to focus on building and deploying your applications.${NC}"
echo

# Ask the user to continue
while true; do
  read -rp $'\033[1;37m\033[1mDo you want to start? (\033[1;32myes \033[1;37mor\033[1;31m no\033[1;37m): \033[0m' choice
  case "$choice" in
    [yY]|[yY][eE][sS])
      echo
      break
      ;;
    [nN]|[nN][oO])
      # Display your final message with the execution time
      end_time=$(date +%s)
      execution_message=$(calculate_execution_time "$start_time" "$end_time")
      
      echo
      echo -e "${GREEN}${BOLD}Script exited successfully.${NC}${BOLD} Execution time: ${execution_message}.${NC}"
      echo      

      exit 1
      ;;
    *)
      echo -e "${RED}${BOLD}Invalid choice.${WHITE}${BOLD} Please enter ${NC}${GREEN}${BOLD}yes${NC}${WHITE}${BOLD} or ${NC}${RED}${BOLD}no${NC}${WHITE}${BOLD}.${NC}"
      ;;
  esac
done

echo -e "${YELLOW}${BOLD}Checking Current Config Values...${NC}"
loading_bar 0.05
show_current_config_values

update_config_values

echo -e "${YELLOW}${BOLD}Checking Updated Config Values...${NC}"
loading_bar 0.05
show_current_config_values

# Display your final message with the execution time
end_time=$(date +%s)
execution_message=$(calculate_execution_time "$start_time" "$end_time")

echo -e "${GREEN}${BOLD}Script finished successfully.${NC}${BOLD} Execution time: ${execution_message}.${NC}"
echo