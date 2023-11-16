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

# Function to check Docker Compose version
check_docker_compose_version() {
  local min_version="1.29.0"  # Minimum required Docker Compose version

  local compose_version
  compose_version=$(docker-compose --version | awk '{print $3}')

  if [[ "$compose_version" < "$min_version" ]]; then
    echo -e "${RED}${BOLD}Docker Compose version $compose_version is not supported. Minimum required version is $min_version.${NC}"
    echo 

    # Display your final message with the execution time
    end_time=$(date +%s)
    execution_message=$(calculate_execution_time "$start_time" "$end_time")

    echo -e "${RED}${BOLD}Script finished unsuccessfully.${NC}${BOLD} Execution time: ${execution_message}.${NC}"
    echo

    exit 1
  else
    echo -e "${GREEN}${BOLD}Docker Compose version $compose_version is compatible.${NC}"
    echo      
  fi
}

# Function to start the MySQL service with Docker Compose
start_docker_service() {
  local compose_file="./docker/docker-compose.yml"

  echo -e "${YELLOW}${BOLD}Checking Docker Compose compatibility...${NC}"
  loading_bar 0.05
  check_docker_compose_version

  echo -e "${YELLOW}${BOLD}Starting the Docker service with Docker Compose...${NC}"

  # Start the MySQL service in detached mode
  if docker-compose -f "$compose_file" up -d; then
    echo
    echo -e "${GREEN}${BOLD}Docker service started successfully.${NC}"
  else
    echo -e "${RED}${BOLD}Failed to start MySQL service.${NC}"
    echo

    # Display your final message with the execution time
    end_time=$(date +%s)
    execution_message=$(calculate_execution_time "$start_time" "$end_time")

    echo -e "${RED}${BOLD}Script finished unsuccessfully.${NC}${BOLD} Execution time: ${execution_message}.${NC}"
    echo
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
      echo -e "${GREEN}${BOLD}Script Initialising...${NC}"
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

./setup.sh
./generate-secrets.sh
#autochanger to put all the information in the right places=
start_docker_service
#health check

# Display your final message with the execution time
end_time=$(date +%s)
execution_message=$(calculate_execution_time "$start_time" "$end_time")

echo
echo -e "${GREEN}${BOLD}Script finished successfully.${NC}${BOLD} Execution time: ${execution_message}.${NC}"
echo
