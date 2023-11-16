#!/bin/bash
# Script Name: DockerInstallSmith.sh
# Description: A script to simplify Docker installation, Docker Compose installation, and Docker startup on Linux, macOS, and Windows.
# Author: Your Name
# Usage: ./DockerInstallSmith.sh

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

# Function to display an error message and exit
error_exit() {
    echo -e "${RED}${BOLD}Error: $1${NC}"
    echo 

    # Display your final message with the execution time
    end_time=$(date +%s)
    execution_message=$(calculate_execution_time "$start_time" "$end_time")

    echo -e "${RED}${BOLD}Script finished unsuccessfully.${NC}${BOLD} Execution time: ${execution_message}.${NC}"
    echo

    exit 1
}

# Function to display a success message
success_message() {
    echo -e "${GREEN}${BOLD}$1${NC}"
}

# Function to install Docker on Linux
install_docker_linux() {
    echo -e "${YELLOW}${BOLD}Installing Docker on Linux...${NC}"
    loading_bar 0.05
    sudo apt-get update || error_exit "Failed to update package lists."
    sudo apt-get install -y docker.io || error_exit "Failed to install Docker."
}

# Function to install Docker on macOS using Homebrew
install_docker_macos() {
    echo -e "${YELLOW}${BOLD}Installing Docker on macOS using Homebrew...${NC}"
    loading_bar 0.05
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install.sh)" || error_exit "Failed to install Homebrew."
    brew install docker || error_exit "Failed to install Docker."
}

# Function to install Docker Compose on Linux
install_docker_compose_linux() {
    echo -e "${YELLOW}${BOLD}Installing Docker Compose on Linux...${NC}"
    loading_bar 0.05
    sudo apt-get update || error_exit "Failed to update package lists."
    sudo apt-get install -y docker-compose || error_exit "Failed to install Docker Compose."
}

# Function to install Docker Compose on macOS using Homebrew
install_docker_compose_macos() {
    echo -e "${YELLOW}${BOLD}Installing Docker Compose on macOS using Homebrew...${NC}"
    loading_bar 0.05
    brew install docker-compose || error_exit "Failed to install Docker Compose."
}

# Function to install Docker Compose on Windows
install_docker_compose_windows() {
    echo -e "${YELLOW}${BOLD}Installing Docker Compose on Windows...${NC}"
    loading_bar 0.05
    curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-Windows-x86_64.exe" -o docker-compose.exe || error_exit "Failed to download Docker Compose."
    chmod +x docker-compose.exe || error_exit "Failed to set execute permissions for Docker Compose."
    sudo mv docker-compose.exe /usr/local/bin/docker-compose || error_exit "Failed to move Docker Compose to /usr/local/bin."
}

# Function to check and install Docker
check_and_install_docker() {
    # Check if Docker is installed
    if ! command -v docker &>/dev/null; then
        # Docker is not installed, so we need to install it
        if [[ "$(uname -s)" == "Linux" ]]; then
            install_docker_linux
        elif [[ "$(uname -s)" == "Darwin" ]]; then
            install_docker_macos
        elif [[ "$(uname -o)" == "Cygwin" || "$(uname -o)" == "Msys" ]]; then
            install_docker_windows
        else
            echo -e "${RED}${BOLD}Error: Unsupported operating system.${NC}"
            echo

            # Display your final message with the execution time
            end_time=$(date +%s)
            execution_message=$(calculate_execution_time "$start_time" "$end_time")

            echo -e "${RED}${BOLD}Script finished unsuccessfully.${NC}${BOLD} Execution time: ${execution_message}.${NC}"
            echo

            exit 1
        fi
    else
        success_message "Docker is already installed."
    fi
}

# Function to check and install Docker Compose
check_and_install_docker_compose() {
    # Check if Docker Compose is installed
    if ! command -v docker-compose &>/dev/null; then
        # Docker Compose is not installed, so we need to install it
        if [[ "$(uname -s)" == "Linux" ]]; then
            install_docker_compose_linux
        elif [[ "$(uname -s)" == "Darwin" ]]; then
            install_docker_compose_macos
        elif [[ "$(uname -o)" == "Cygwin" || "$(uname -o)" == "Msys" ]]; then
            install_docker_compose_windows
        else
            echo -e "${RED}${BOLD}Error: Unsupported operating system.${NC}"
            echo

            # Display your final message with the execution time
            end_time=$(date +%s)
            execution_message=$(calculate_execution_time "$start_time" "$end_time")

            echo -e "${RED}${BOLD}Script finished unsuccessfully.${NC}${BOLD} Execution time: ${execution_message}.${NC}"
            echo

            exit 1
        fi
    else
        success_message "Docker Compose is already installed."
    fi
}

# Function to check and start Docker
check_and_start_docker() {
    # Check if Docker is running
    if ! docker info &>/dev/null; then
        # Docker is not running, so we need to start it
        if [[ "$(uname -s)" == "Linux" ]]; then
            start_docker_linux
        elif [[ "$(uname -s)" == "Darwin" ]]; then
            start_docker_macos
        elif [[ "$(uname -o)" == "Cygwin" || "$(uname -o)" == "Msys" ]]; then
            start_docker_windows
        else
            echo -e "${RED}${BOLD}Error: Unsupported operating system.${NC}"
            echo

            # Display your final message with the execution time
            end_time=$(date +%s)
            execution_message=$(calculate_execution_time "$start_time" "$end_time")

            echo -e "${RED}${BOLD}Script finished unsuccessfully.${NC}${BOLD} Execution time: ${execution_message}.${NC}"
            echo

            exit 1
        fi
    else
        echo -e "${YELLOW}Waiting for Docker to start...${NC}"
        loading_bar 0.15
        success_message "Docker is already running."
    fi
}

# Function to start Docker on Linux
start_docker_linux() {
    echo -e "${YELLOW}${BOLD}Starting Docker on Linux...${NC}"
    loading_bar 0.05
    sudo systemctl start docker || error_exit "Failed to start Docker on Linux."
}

# Function to start Docker on macOS
start_docker_macos() {
    echo -e "${YELLOW}${BOLD}Starting Docker on macOS...${NC}"
    loading_bar 0.05
    open -a Docker || error_exit "Failed to start Docker on macOS."
}

# Function to start Docker on Windows
start_docker_windows() {
    echo -e "${YELLOW}${BOLD}Starting Docker on Windows...${NC}"
    loading_bar 0.05
    # Use docker-compose to start containers (replace with your Docker Compose file path)
    # Example: docker-compose -f /path/to/your/docker-compose.yml up -d
    docker-compose -f /path/to/your/docker-compose.yml up -d || error_exit "Failed to start Docker containers on Windows."
    echo -e "${GREEN}${BOLD}Docker containers on Windows started successfully.${NC}"
}

# Title and description
display_title() {
echo -e "${RED}${BOLD}
  _____             _           _____           _        _ _  _____           _ _   _     
 |  __ \           | |         |_   _|         | |      | | |/ ____|         (_) | | |    
 | |  | | ___   ___| | _____ _ __| |  _ __  ___| |_ __ _| | | (___  _ __ ___  _| |_| |__  
 | |  | |/ _ \ / __| |/ / _ \ '__| | | '_ \/ __| __/ _' | | |\___ \| '_ ' _ \| | __| '_ \ 
 | |__| | (_) | (__|   <  __/ | _| |_| | | \__ \ || (_| | | |____) | | | | | | | |_| | | |
 |_____/ \___/ \___|_|\_\___|_||_____|_| |_|___/\__\__,_|_|_|_____/|_| |_| |_|_|\__|_| |_|
${NC}"
}
display_title

echo -e "${RED}${BOLD}                 Like a blacksmith forging iron but for Docker!${NC}"
echo
echo -e "${BOLD}${GREY}DockerInstallSmith is your go-to tool for effortlessly configuring Docker on your system. This script automates"
echo -e " a range of essential tasks, ensuring that you're ready to harness the power of Docker with ease.${NC}"
echo
echo -e "${BOLD}${GREY}1.${NC} ${BOLD}${PURPLE}Docker Installation:${NC} ${GREY}Checks for an existing Docker installation and installs it if needed."
echo -e "   It provides seamless support for Linux, macOS, and Windows.${NC}"
echo
echo -e "${BOLD}${GREY}2.${NC} ${BOLD}${PURPLE}Docker Startup:${NC} ${GREY}Ensures Docker is up and running. If not, it initiates Docker to"
echo -e "   guarantee your Docker environment is always available.${NC}"
echo
echo -e "${BOLD}${GREY}3.${NC} ${BOLD}${PURPLE}Docker Compose Installation:${NC} ${GREY}Verifies the presence of Docker Compose and installs it if required."
echo -e "   Docker Compose simplifies managing multi-container applications.${NC}"
echo
echo -e "${GREY}Whether you're a Docker enthusiast or just starting your containerization journey, DockerInstallSmith simplifies setup"
echo -e "and maintenance, allowing you to focus on building and deploying your applications.${NC}"
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

echo -e "${YELLOW}Checking and installing Docker...${NC}"
loading_bar 0.05
check_and_install_docker
echo

echo -e "${YELLOW}Checking and installing Docker Compose...${NC}"
loading_bar 0.05
check_and_install_docker_compose
echo

echo -e "${YELLOW}Checking and starting Docker...${NC}"
loading_bar 0.05
check_and_start_docker
echo

success_message "Docker and Docker Compose are installed and ready to use."
echo

# Display your final message with the execution time
end_time=$(date +%s)
execution_message=$(calculate_execution_time "$start_time" "$end_time")

echo -e "${GREEN}${BOLD}Script finished successfully.${NC}${BOLD} Execution time: ${execution_message}.${NC}"
echo
