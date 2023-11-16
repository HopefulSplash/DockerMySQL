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


                #//TODO HERE ------------------------>
                #//1 / 3 still left to do
                #//2 - same as this and same output so do 1 then do both 


perform_mysql_backup() {
    local exit_code=0

    while true; do
        # Prompt the user for confirmation
        echo -ne "${NC}${BOLD}Are you sure you want to backup the database from '${GREEN}${BOLD}$mysql_container${NC}${BOLD}'? (${GREEN}${BOLD}Yes ${NC}${BOLD}/ ${RED}${BOLD}X${NC}${BOLD}): " 
        read -re confirm
        echo

        case "$confirm" in
            [Yy]|[Yy][Ee][Ss])
                local backup_filename="mysql_backup_$(date +'%Y%m%d%H%M%S').sql.gz"
                local backup_path="$backup_dir/$backup_filename"

                echo -e "${YELLOW}${BOLD}Starting MySQL backup from $mysql_container...${NC}"
                loading_bar 0.05
                echo

                # Perform the MySQL backup and log output to a file
                docker exec "$mysql_container" mysqldump -u"$mysql_user" -p"$mysql_password" "$mysql_database" > "$backup_path" 2> "./logs/mysql_backup_output.txt"
                exit_code=$?

                if [ $exit_code -eq 0 ]; then
                    echo -e "${GREEN}${BOLD}MySQL backup completed successfully. Backup saved to $backup_path${NC}"
                    log_message="$(date +'%Y-%m-%d %H:%M:%S') - MySQL backup from $mysql_container: SUCCESS"

                    # Call the cleanup function to delete old backups
                    cleanup_backups

                else
                    echo -e "${RED}${BOLD}MySQL backup failed.${NC}"
                    log_message="$(date +'%Y-%m-%d %H:%M:%S') - MySQL backup from $mysql_container: FAILED"

                    if [ $exit_code -eq 1 ]; then
                        echo
                        echo -e "${RED}${BOLD}ERROR: ${NC}${BOLD}Please check your MySQL credentials.${NC}"
                    elif [ $exit_code -eq 2 ]; then
                        echo
                        echo -e "${RED}${BOLD}ERROR: ${NC}${BOLD}Please ensure the specified database ('$mysql_database') exists.${NC}"
                    else
                        echo
                        echo -e "${RED}${BOLD}ERROR: ${NC}${BOLD}An unknown error occurred.${NC}"
                    fi
                fi

                # Append the MySQL restore output to the log file
                cat ./logs/mysql_backup_output.txt >>  $log_file

                # Additional cleanup (optional)
                # Remove the temporary MySQL restore output file
                rm -f ./logs/mysql_backup_output.txt

                echo "$log_message" >> $log_file
                break
                ;;
            [Xx])
                break
                ;;
            *)
                # Invalid input, provide instructions
                echo -e "${RED}${BOLD}Invalid choice.${WHITE}${BOLD}"
                echo -e "Please enter (${NC}${GREEN}${BOLD}Yes${NC} / ${RED}${BOLD}X${NC} to exit)" 
                echo
                ;;
        esac
    done
}

# Function to display an overview of permissions
display_permissions() {
    local perm_chars="$1"
    local overview=""

    if [[ $perm_chars == *"r"* ]]; then
        overview+="Read"
    fi

    if [[ $perm_chars == *"w"* ]]; then
        if [ -n "$overview" ]; then
            overview+=", "
        fi
        overview+="Write"
    fi

    if [[ $perm_chars == *"x"* ]]; then
        if [ -n "$overview" ]; then
            overview+=", "
        fi
        overview+="Execute"
    fi

    if [ -z "$overview" ]; then
        overview="None"
    fi

    echo -e "$overview"
}

# Function to list available backups with a border
list_backups() {
    echo -e "${YELLOW}${BOLD}Searching for available backups in $backup_dir...${NC}"
    loading_bar 0.05
    echo

    # Check if gstat is available, use stat if not
    if command -v gstat &> /dev/null; then
        # Use gstat if available (for macOS)
        stat_command="gstat"
    else
        # Use stat if gstat is not available
        stat_command="stat"
    fi

    # Create a header with column titles and add a border
    printf "+------------------------------------------+--------------+-----------------+----------------+-----------------------+------------+\n"
    printf "| %-40s | %-12s | %-15s | %-15s | %-20s | %-10s |\n" "Backup Filename" "File Size" "Permissions" "Owner" "Last Modified" "File Type"
    printf "+------------------------------------------+--------------+-----------------+----------------+-----------------------+------------+\n"
    
    # Loop through backup files and display their details
    for backup_file in "$backup_dir"/*.sql.gz; do
        if [ -f "$backup_file" ]; then
            # Get file size in human-readable format (e.g., 4.0K)
            file_size=$(du -h "$backup_file" | awk '{print $1}')
            # Get file permissions using stat or gstat command
            permissions=$("$stat_command" -f "%Sp" "$backup_file")
            # Display permissions as an overview
            permissions_overview=$(display_permissions "$permissions")
            # Get file owner
            owner=$("$stat_command" -f "%Su" "$backup_file")
            # Get last modified timestamp
            last_modified=$(date -r "$backup_file" "+%Y-%m-%d %H:%M:%S")
            # Get file type (regular file, directory, etc.)
            file_type=$(file -b "$backup_file" | awk '{print $1}')
            # Extract only the filename without the path
            filename=$(basename "$backup_file")
            
            # Print details with a border
            printf "| %-40s | %-12s | %-15s | %-15s | %-20s | %-10s |\n" "$filename" "$file_size" "$permissions_overview" "$owner" "$last_modified" "$file_type"
        fi
    done
    
    # Add a bottom border
    printf "+------------------------------------------+--------------+-----------------+----------------+-----------------------+------------+\n"
}

# Function to perform MySQL restore with detailed output
perform_mysql_restore() {
    local exit_code=0

    # Ensure the backup file exists
    if [ ! -f "$backup_dir/$selected_filename" ]; then
        echo -e "${RED}${BOLD}ERROR: ${NC}${BOLD}Backup file (${GREEN}${BOLD}$selected_filename${NC}${BOLD}) not found in $backup_dir.${NC}"
        echo
        return 1
    fi

    loading_bar 0.05

    # Perform the MySQL restore and log output to a file
    docker exec -i "$mysql_container" mysql -u"$mysql_user" -p"$mysql_password" "$mysql_database" < <(cat "$backup_dir/$selected_filename") > ./logs/mysql_restore_output.txt 2>&1
    exit_code=${PIPESTATUS[0]}
    echo

    if [ $exit_code -eq 0 ]; then
        echo -e "${GREEN}${BOLD}MySQL restore completed successfully from $backup_dir/$selected_filename.${NC}"
        echo

        # Log the successful restore
        log_message="$(date +'%Y-%m-%d %H:%M:%S') - MySQL restore from $selected_filename: SUCCESS"
    else
        echo -e "${RED}${BOLD}MySQL restore failed using $backup_dir/$selected_filename.${NC}"
        echo

        # Log the failed restore
        log_message="$(date +'%Y-%m-%d %H:%M:%S') - MySQL restore from $selected_filename: FAILED"
        
        # Additional error handling
        if grep -q "No such file or directory" ./logs/mysql_restore_output.txt; then
            echo -e "${RED}${BOLD}ERROR: ${NC}${BOLD}The backup file does not exist or is in a different format.${NC}"
            echo
        elif grep -q "Container .* is not running" ./logs/mysql_restore_output.txt; then
            echo -e "${RED}${BOLD}ERROR: ${NC}${BOLD}The Docker container $mysql_container is not running.${NC}"
            echo
        elif grep -q "Access denied for user" ./logs/mysql_restore_output.txt; then
            echo -e "${RED}${BOLD}ERROR: ${NC}${BOLD}Access denied. Check your MySQL user and password.${NC}"
            echo
        else
            # Handle other errors not explicitly listed
            echo -e "${RED}${BOLD}ERROR: ${NC}${BOLD}An unexpected error occurred. Check mysql_restore_output.txt for details.${NC}"
            echo
        fi
    fi

    # Append the MySQL restore output to the log file
    cat ./logs/mysql_restore_output.txt >>  $log_file

    # Additional cleanup (optional)
    # Remove the temporary MySQL restore output file
    rm -f ./logs/mysql_restore_output.txt

    echo "$log_message" >> $log_file
    return $exit_code
}

# Function to restore a MySQL backup with a selection table
restore_mysql_backup() {
    while true; do
        local filenames=()
        
        # Check if gstat is available, use stat if not
        if command -v gstat &> /dev/null; then
            # Use gstat if available (for macOS)
            stat_command="gstat"
        else
            # Use stat if gstat is not available
            stat_command="stat"
        fi

        # Create a header with column titles and add a border
        printf "+-----+------------------------------------------+--------------+-----------------+----------------+-----------------------+------------+\n"
        printf "| %-2s | %-40s | %-12s | %-15s | %-15s | %-20s | %-10s |\n" " # " "Backup Filename" "File Size" "Permissions" "Owner" "Last Modified" "File Type"
        printf "+-----+------------------------------------------+--------------+-----------------+----------------+-----------------------+------------+\n"
        
        # Loop through backup files and display their details with a number for selection
        local count=1
        for backup_file in "$backup_dir"/*.sql.gz; do
            if [ -f "$backup_file" ]; then
                # Get file size in human-readable format (e.g., 4.0K)
                file_size=$(du -h "$backup_file" | awk '{print $1}')
                # Get file permissions using stat or gstat command
                permissions=$("$stat_command" -f "%Sp" "$backup_file")
                # Display permissions as an overview
                permissions_overview=$(display_permissions "$permissions")
                # Get file owner
                owner=$("$stat_command" -f "%Su" "$backup_file")
                # Get last modified timestamp
                last_modified=$(date -r "$backup_file" "+%Y-%m-%d %H:%M:%S")
                # Get file type (regular file, directory, etc.)
                file_type=$(file -b "$backup_file" | awk '{print $1}')
                # Extract only the filename without the path
                filename=$(basename "$backup_file")
                
                
                # Print details with a border and a number for selection
                printf "| %-3s | %-40s | %-12s | %-15s | %-15s | %-20s | %-10s |\n" "$count" "$filename" "$file_size" "$permissions_readable" "$owner" "$last_modified" "$file_type"
                
                # Add the filename to the list for selection
                filenames+=("$filename")
                
                count=$((count + 1))
            fi
        done
        
        # Add a bottom border
        printf "+-----+------------------------------------------+--------------+-----------------+----------------+-----------------------+------------+\n"
        echo 

        # Prompt the user to select a backup for restoration
        echo -ne "${NC}${BOLD}Enter the ${GREEN}${BOLD}number${NC}${BOLD} of the backup file to restore - (${RED}${BOLD}X${NC}${BOLD}) to exit: ${NC}"
        read -re selection

        # Check if the user wants to exit
        if [[ "$selection" == "x" ]]; then
            break
        fi
        
        # Check if the selection is valid
        if [[ ! "$selection" =~ ^[0-9]+$ ]]; then
            echo
            echo -e "${RED}${BOLD}Invalid input."
            echo -e "${NC}${BOLD}Please enter the ${GREEN}${BOLD}number ${NC}${BOLD}of the file you wish to restore.${NC}" 
            echo
        elif [ "$selection" -lt 1 ] || [ "$selection" -gt "${#filenames[@]}" ]; then
            echo
            echo -e "${RED}${BOLD}Invalid selection"
            echo -e "${NC}${BOLD}Please enter a ${GREEN}${BOLD}valid number${NC}${BOLD} within the range displayed above.${NC}" 
            echo
        else
            # Get the selected filename
            selected_filename="${filenames[$((selection - 1))]}"
            
            if [ -f "$backup_dir/$selected_filename" ]; then
                echo
                echo -ne "${NC}${BOLD}Are you sure you want to restore the database from '${GREEN}${BOLD}$selected_filename${NC}${BOLD}'? (${GREEN}${BOLD}Yes ${NC}${BOLD}/ ${RED}${BOLD}X${NC}${BOLD}): " 
                read -re confirm

                if [ "$confirm" == "y" ] || [ "$confirm" == "Y" ] || [ "$confirm" == "Yes" ] || [ "$confirm" == "yes" ]; then
                    echo
                    echo -e "${YELLOW}${BOLD}Starting MySQL restore from $selected_filename...${NC}"
                    perform_mysql_restore
                else
                    echo
                    echo -e "${PURPLE}${BOLD}WARNING: ${NC}${BOLD}No changes have been made, restore operation canceled.${NC}"
                    break
                fi
            else
                echo
                echo -e "${RED}${BOLD}ERROR: ${NC}${BOLD}No Backup file (${GREEN}${BOLD}$selected_filename${NC}${BOLD}) not found in $backup_dir.${NC}" 
            fi
        fi
    done
}

# Function to perform backup cleanup
cleanup_backups() {
    echo
    echo -e "${YELLOW}${BOLD}Processing backups that are exceeding retention limit of $backup_retention_days days...${NC}"
    loading_bar 0.05

    deleted_files=()  # Create an empty array to store deleted files

    # Use a while loop to process each deleted file
    while IFS= read -r -d '' file; do
        rm "$file"  # Attempt to delete the file
        if [ $? -eq 0 ]; then
            deleted_files+=("$file")  # Add the file to the list of deleted files if deletion was successful
        else
            echo
            echo -e "${RED}${BOLD}Error deleting file: $file${NC}"
            echo
        fi
    done < <(find "$backup_dir" -type f -mtime +"$backup_retention_days" -name "*.sql.gz" -print0)

    if [ ${#deleted_files[@]} -gt 0 ]; then
        echo
        echo -e "${GREEN}${BOLD}Old backups exceeding $backup_retention_days days have been deleted successfully:${NC}"
        
        # Create a header with column titles and add a border
        printf "+-----+------------------------------------------+--------------+-----------------+----------------+-----------------------+------------+\n"
        printf "| %-2s | %-40s | %-12s | %-15s | %-15s | %-20s | %-10s |\n" " # " "Backup Filename" "File Size" "Permissions" "Owner" "Last Modified" "File Type"
        printf "+-----+------------------------------------------+--------------+-----------------+----------------+-----------------------+------------+\n"
        
        # Loop through backup files and display their details with a number for selection
        local count=1
        for backup_file in "${deleted_files[@]}"; do
            if [ -f "$backup_file" ]; then
                # Get file size in human-readable format (e.g., 4.0K)
                file_size=$(du -h "$backup_file" | awk '{print $1}')
                # Get file permissions using stat or gstat command
                permissions=$("$stat_command" -f "%Sp" "$backup_file")
                # Display permissions as an overview
                permissions_readable=$(display_permissions "$permissions")
                # Get file owner
                owner=$("$stat_command" -f "%Su" "$backup_file")
                # Get last modified timestamp
                last_modified=$(date -r "$backup_file" "+%Y-%m-%d %H:%M:%S")
                # Get file type (regular file, directory, etc.)
                file_type=$(file -b "$backup_file" | awk '{print $1}')
                # Extract only the filename without the path
                filename=$(basename "$backup_file")
                
                # Print details with a border and a number for selection
                printf "| %-3s | %-40s | %-12s | %-15s | %-15s | %-20s | %-10s |\n" "$count" "$filename" "$file_size" "$permissions_readable" "$owner" "$last_modified" "$file_type"
                
                count=$((count + 1))
            fi
        done
        
        # Add a bottom border
        printf "+-----+------------------------------------------+--------------+-----------------+----------------+-----------------------+------------+\n"
        
    else
        echo
        echo -e "${GREEN}${BOLD}No old backups exceeding $backup_retention_days days were found.${NC}"
    fi
}

# Function for the main user interaction
user_interaction() {
    
  while true; do
    # Title and description
    display_title() {
    echo -e "${RED}${BOLD}
     _____             _             __  __        _____  ____  _       _____           _ _   _     
    |  __ \           | |           |  \/  |      / ____|/ __ \| |     / ____|         (_) | | |    
    | |  | | ___   ___| | _____ _ __| \  / |_   _| (___ | |  | | |    | (___  _ __ ___  _| |_| |__  
    | |  | |/ _ \ / __| |/ / _ \ '__| |\/| | | | |\___ \| |  | | |     \___ \| '_ ' _ \| | __| '_ \ 
    | |__| | (_) | (__|   <  __/ |  | |  | | |_| |____) | |__| | |____ ____) | | | | | | | |_| | | |
    |_____/ \___/ \___|_|\_\___|_|  |_|  |_|\__, |_____/ \___\_\______|_____/|_| |_| |_|_|\__|_| |_|
                                            __/ |                                                  
                                           |___/                                                                                                                       
    ${NC}"
    }

    display_title

    echo -e "${RED}${BOLD}                        Like a blacksmith forging iron but for Docker!${NC}"
    echo
    echo -e "${BOLD}${GREY}Welcome to the Docker and MySQL Backup Script! This tool simplifies the process of"
    echo -e "backing up your MySQL databases in Docker containers, ensuring your data is safe and"
    echo -e "easily recoverable.${NC}"
    echo
    echo -e "${BOLD}${GREY}1.${NC} ${BOLD}${PURPLE}Perform MySQL Backup:${NC} ${GREY}Create backups of your MySQL databases running in Docker containers."
    echo -e "   It ensures your data is securely stored for future recovery.${NC}"
    echo
    echo -e "${BOLD}${GREY}2.${NC} ${BOLD}${PURPLE}List Available Backups:${NC} ${GREY}View the list of existing backups to select one for restoration or management.${NC}"
    echo
    echo -e "${BOLD}${GREY}3.${NC} ${BOLD}${PURPLE}Restore MySQL Backup:${NC} ${GREY}Restore your MySQL database from a previously created backup. Safely recover"
    echo -e "   your data in case of unexpected events.${NC}"
    echo
    echo -e "${GREY}This script streamlines Docker and MySQL backup tasks, allowing you to focus on"
    echo -e "data integrity and peace of mind.${NC}"
    echo

    echo -ne "${NC}${BOLD}Select an option (${NC}${GREEN}${BOLD}1${NC}/${GREEN}${BOLD}2${NC}/${GREEN}${BOLD}3${NC}) - (${RED}${BOLD}X${NC}) to exit: " 
    read -re choice
    case "$choice" in
      1)
        echo
        echo -e "${GREEN}${BOLD}Option 1 Selected${NC}"
        echo
        perform_mysql_backup        ;;
      2)
        echo
        echo -e "${GREEN}${BOLD}Option 2 Selected${NC}"
        echo
        list_backups
        ;;
      3)
        echo
        echo -e "${GREEN}${BOLD}Option 3 Selected${NC}"
        echo
        restore_mysql_backup        
        ;;
      [xX])
        # User wants to exit
        end_time=$(date +%s)
        execution_message=$(calculate_execution_time "$start_time" "$end_time")
        
        echo
        echo -e "${GREEN}${BOLD}Script exited successfully.${NC}${BOLD} Execution time: ${execution_message}.${NC}"
        echo
        exit 0
        ;;
      *)
        echo
        echo -e "${RED}${BOLD}Invalid choice.${WHITE}${BOLD}"
        echo -e "Please enter (${NC}${GREEN}${BOLD}1${NC}/${GREEN}${BOLD}2${NC}/${GREEN}${BOLD}3${NC}) - (${RED}${BOLD}X${NC}) to exit." 
        echo
        ;;
    esac
  done
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

user_interaction

# Save the configuration
save_configuration

# Display your final message with the execution time
end_time=$(date +%s)
execution_message=$(calculate_execution_time "$start_time" "$end_time")

echo
echo -e "${GREEN}${BOLD}Script finished successfully.${NC}${BOLD} Execution time: ${execution_message}.${NC}"
echo
log_message "${GREEN}${BOLD}Script finished successfully.${NC}${BOLD} Execution time: ${execution_message}.${NC}"