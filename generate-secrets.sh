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

# Define the paths to the secret files
MYSQL_ROOT_PASSWORD_FILE="./docker/secrets/mysql_root_password.txt"
MYSQL_DATABASE_FILE="./docker/secrets/mysql_database.txt"
MYSQL_USER_FILE="./docker/secrets/mysql_user.txt"
MYSQL_PASSWORD_FILE="./docker/secrets/mysql_password.txt"

# Function to generate a random strong password
generate_strong_password() {
  pwgen -s 20 1
}

# Function to generate a random password on Windows and macOS
generate_password_windows_mac() {
  openssl rand -base64 20 | tr -d "=+/" | cut -c1-20
}

# Function to create or update secret files
create_or_update_secret_file() {
  local file_path="$1"
  local secret_value="$2"
  
  echo -n "$secret_value" > "$file_path"
  chmod 600 "$file_path"
  echo "$file_path"
}

# Function to check if a command is available and install it if missing
check_and_install_command() {
  local command_name="$1"
  local package_name="$2"
  local system_name="$3"
  
  # Determine the current operating system
  case "$OSTYPE" in
    linux-gnu)
      os_name="Linux"
      ;;
    darwin*)
      os_name="macOS"
      ;;
    msys* | cygwin)
      os_name="Windows"
      ;;
    *)
      os_name="Unknown"
      ;;
  esac
  
  # Only display messages if the current OS matches the provided OS
  if [ "$system_name" = "$os_name" ]; then
    # Log required package and system information
    loading_bar 0.05
    
    if ! command -v "$command_name" &>/dev/null; then
      while true; do
        read -rp "${YELLOW}${BOLD}The command '$command_name' is not installed. Do you want to install it for $system_name? (yes/no): ${NC}" install_choice
        case "$install_choice" in
          [yY]|[yY][eE][sS])
            echo -e "${YELLOW}${BOLD}Installing $package_name...${NC}"
            case "$system_name" in
              Linux)
                sudo apt-get update -y
                sudo apt-get install -y "$package_name"
                ;;
              macOS)
                brew update
                brew install "$package_name"
                ;;
              Windows)
                pacman -Sy --noconfirm "$package_name"
                ;;
              *)
                echo -e "${RED}${BOLD}Unsupported system, stopping script execution.${NC}"
                
                # Display your final message with the execution time
                end_time=$(date +%s)
                execution_message=$(calculate_execution_time "$start_time" "$end_time")
                echo -e "${RED}${BOLD}Script exited successfully.${NC}${BOLD} Execution time: ${execution_message}.${NC}"
                echo  
      
                # Display your final message with the execution time
                end_time=$(date +%s)
                execution_message=$(calculate_execution_time "$start_time" "$end_time")

                echo -e "${RED}${BOLD}Script finished unsuccessfully.${NC}${BOLD} Execution time: ${execution_message}.${NC}"
                echo

                exit 1
                ;;
            esac
            echo -e "${GREEN}${BOLD}$package_name is installed for $system_name.${NC}"
            break
            ;;
          [nN]|[nN][oO])
            echo -e "${RED}${BOLD}You chose not to install $package_name, stopping script execution.${NC}"
            
            # Display your final message with the execution time
            end_time=$(date +%s)
            execution_message=$(calculate_execution_time "$start_time" "$end_time")
            echo -e "${GREEN}${BOLD}Script exited successfully.${NC}${BOLD} Execution time: ${execution_message}.${NC}"
            echo      
            exit 1
            ;;
          *)
            echo -e "${RED}${BOLD}Invalid choice.${WHITE}${BOLD} Please enter ${NC}${GREEN}${BOLD}yes${NC}${WHITE}${BOLD} or ${NC}${RED}${BOLD}no${NC}${WHITE}${BOLD}.${NC}"
            ;;
        esac
      done
    else
      # Log that the package is already installed
      echo -e "${GREEN}${BOLD}$package_name is already installed this $system_name system.${NC}"
    fi
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

# Title and description
display_title() {
echo -e "${RED}${BOLD}
  _____             _             _____                    _    _____           _ _   _     
 |  __ \           | |           / ____|                  | |  / ____|         (_) | | |    
 | |  | | ___   ___| | _____ _ _| (___   ___  ___ _ __ ___| |_| (___  _ __ ___  _| |_| |__  
 | |  | |/ _ \ / __| |/ / _ \ '__\___ \ / _ \/ __| '__/ _ \ __|\___ \| '_ ' _ \| | __| '_ \ 
 | |__| | (_) | (__|   <  __/ |  ____) |  __/ (__| | |  __/ |_ ____) | | | | | | | |_| | | |
 |_____/ \___/ \___|_|\_\___|_| |_____/ \___|\___|_|  \___|\__|_____/|_| |_| |_|_|\__|_| |_|
${NC}"
}
display_title

echo -e "${RED}${BOLD}                 Like a blacksmith forging iron but for Docker!${NC}"
echo
echo -e "${BOLD}${GREY}Docker Secret Smith simplifies the generation of Docker secret files for your applications"
echo -e "and ensures that you have the necessary dependencies installed. It will create or update"
echo -e "the following secret files:${NC}"
echo
echo -e "${BOLD}${GREY}1. ${BOLD}${PURPLE}MySQL Root Password:${NC} ${GREY}A strong and secure password that provides administrative"
echo -e "   access to the MySQL database server. This password is longer and more secure.${NC}"
echo
echo -e "${BOLD}${GREY}2. ${BOLD}${PURPLE}MySQL Database Name:${NC} ${GREY}The name of the MySQL database that your application will"
echo -e "   use to store data. This is where your application's data will be stored.${NC}"
echo
echo -e "${BOLD}${GREY}3. ${BOLD}${PURPLE}MySQL User:${NC} ${GREY}The username for accessing the MySQL database. This user will"
echo -e "   have specific privileges to interact with the database.${NC}"
echo
echo -e "${BOLD}${GREY}4. ${BOLD}${PURPLE}MySQL Password:${NC} ${GREY}A strong and secure password for the MySQL user. This password"
echo -e "   is used to authenticate and secure the user's access to the database.${NC}"
echo
echo -e "${GREY}Please ensure that you keep these secret files and passwords in a secure location, as${NC}"
echo -e "${GREY}they are essential for the proper functioning of your Dockerized applications.${NC}"
echo

# Ask the user to continue
while true; do
  read -rp $'\033[1;37m\033[1mDo you want to start? (\033[1;32myes \033[1;37mor\033[1;31m no\033[1;37m): \033[0m' choice
  case "$choice" in
    [yY]|[yY][eE][sS])
      echo
      echo -e "${GREEN}${BOLD}Script Initialising...${NC}"
      break
      ;;
    [nN]|[nN][oO])
      # Display your final message with the execution time
      end_time=$(date +%s)
      execution_message=$(calculate_execution_time "$start_time" "$end_time")

      echo -e "${GREEN}${BOLD}Script exited successfully.${NC}${BOLD} Execution time: ${execution_message}.${NC}"
      echo      
      exit 1
      ;;
    *)
      echo -e "${RED}${BOLD}Invalid choice.${WHITE}${BOLD} Please enter ${NC}${GREEN}${BOLD}yes${NC}${WHITE}${BOLD} or ${NC}${RED}${BOLD}no${NC}${WHITE}${BOLD}.${NC}"
      ;;
  esac
done

# Check and install required utilities
echo
echo -e "${YELLOW}Checking dependencies and installing if needed...${NC}"
check_and_install_command "pwgen" "pwgen" "Linux"
check_and_install_command "openssl" "openssl" "macOS"
check_and_install_command "openssl" "openssl" "Windows"

echo

# Function to delete files with a loading bar
delete_files() {
  local files=("$@")
  local total_files=${#files[@]}
  
  for file in "${files[@]}"; do
    if [ -f "$file" ]; then
      echo -e "${BLUE}Deleting $file...${NC}"
      loading_bar 0.05
      rm -f "$file"
    fi
  done
}

# Delete existing files sequentially
echo -e "${YELLOW}Cleaning up existing secret files...${NC}"
delete_files "${MYSQL_ROOT_PASSWORD_FILE}" "${MYSQL_PASSWORD_FILE}"
echo -e "${GREEN}${BOLD}DOCKER secret files have been deleted.${NC}"
echo

CONFIG_FILE="./config/backup-config.sh"

# Function to read a specific configuration value from the file
read_config() {
    local key="$1"
    local value=$(grep -E "^$key=" "$CONFIG_FILE" | cut -d '=' -f 2)
    echo "$value"
}

# Generate new secret files sequentially
echo -e "${YELLOW}Generating new secret files...${NC}"

# MySQL Root Password
echo -e "${BLUE}Creating $MYSQL_ROOT_PASSWORD_FILE...${NC}"
loading_bar 0.05
MYSQL_ROOT_PASSWORD=$(generate_password_windows_mac)
MYSQL_ROOT_PASSWORD_FILE_LOCATION=$(create_or_update_secret_file "$MYSQL_ROOT_PASSWORD_FILE" "$MYSQL_ROOT_PASSWORD")

# MySQL Database Name
echo -e "${BLUE}Creating $MYSQL_DATABASE_FILE...${NC}"
loading_bar 0.05
MYSQL_DATABASE_NAME=$(read_config "mysql_database")
MYSQL_DATABASE_FILE_LOCATION=$(create_or_update_secret_file "$MYSQL_DATABASE_FILE" "$MYSQL_DATABASE_NAME")

# MySQL User
echo -e "${BLUE}Creating $MYSQL_USER_FILE...${NC}"
loading_bar 0.05
MYSQL_USER=$(read_config "mysql_user")
MYSQL_USER_FILE_LOCATION=$(create_or_update_secret_file "$MYSQL_USER_FILE" "$MYSQL_USER")

# MySQL Password
echo -e "${BLUE}Creating $MYSQL_PASSWORD_FILE...${NC}"
loading_bar 0.05
MYSQL_PASSWORD=$(generate_password_windows_mac)
MYSQL_PASSWORD_FILE_LOCATION=$(create_or_update_secret_file "$MYSQL_PASSWORD_FILE" "$MYSQL_PASSWORD")

echo -e "${GREEN}${BOLD}DOCKER secret files have been created.${NC}"
echo

# Display the generated values in a formatted table
echo -e "${ORANGE}${BOLD}Please remember to KEEP a copy of these credentials in a secure place! (Note: These will be delete once start-database.sh is successfully executed!)${NC}"
printf "+--------------------------------+--------------------------------------------------------------+---------------------------------------------------+\n"
printf "| %-30s | %-60s | %-50s|\n" "SECRET" "VALUE" "FILE LOCATION"
printf "+--------------------------------+--------------------------------------------------------------+---------------------------------------------------+\n"
printf "| %-30s | %-60s | %-50s|\n" "MySQL Root Password" "$(cat "$MYSQL_ROOT_PASSWORD_FILE")" "$MYSQL_ROOT_PASSWORD_FILE_LOCATION"
printf "| %-30s | %-60s | %-50s|\n" "MySQL Database Name" "$MYSQL_DATABASE_NAME" "$MYSQL_DATABASE_FILE_LOCATION"
printf "| %-30s | %-60s | %-50s|\n" "MySQL User" "$MYSQL_USER" "$MYSQL_USER_FILE_LOCATION"
printf "| %-30s | %-60s | %-50s|\n" "MySQL Password" "$(cat "$MYSQL_PASSWORD_FILE")" "$MYSQL_PASSWORD_FILE_LOCATION"
printf "+--------------------------------+--------------------------------------------------------------+---------------------------------------------------+\n"
echo

# Display your final message with the execution time
end_time=$(date +%s)
execution_message=$(calculate_execution_time "$start_time" "$end_time")

echo -e "${GREEN}${BOLD}Script finished successfully.${NC}${BOLD} Execution time: ${execution_message}.${NC}"
echo
