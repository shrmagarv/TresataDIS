#!/bin/bash
# Tresata Data Ingestion Service - Docker Database Query Script (Bash version)
# This script helps you query the PostgreSQL database inside the Docker container

# Docker container name for PostgreSQL
DB_CONTAINER_NAME="tresata-dis-postgres"

# Database connection parameters
DB_NAME="tresata_dis"
DB_USER="postgres"
DB_PASSWORD="postgres"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
CYAN='\033[0;36m'
GRAY='\033[0;37m'
NC='\033[0m' # No Color

# Function to check if Docker is running and the container exists
check_docker_container() {
    echo -e "\n${CYAN}Checking Docker container...${NC}"
    
    # Check if docker command exists
    if ! command -v docker &> /dev/null; then
        echo -e "${RED}Docker command not found. Please install Docker first.${NC}"
        exit 1
    fi
    
    # Check if container exists
    if ! docker ps -a --format "{{.Names}}" | grep -q "^$DB_CONTAINER_NAME$"; then
        echo -e "${RED}PostgreSQL container '$DB_CONTAINER_NAME' not found.${NC}"
        echo -e "${YELLOW}Make sure the container is running with:${NC}"
        echo -e "${YELLOW}docker-compose up -d postgres${NC}"
        exit 1
    fi
    
    # Check if container is running
    if ! docker ps --format "{{.Names}}" | grep -q "^$DB_CONTAINER_NAME$"; then
        echo -e "${RED}PostgreSQL container '$DB_CONTAINER_NAME' exists but is not running.${NC}"
        echo -e "${YELLOW}Start the container with:${NC}"
        echo -e "${YELLOW}docker start $DB_CONTAINER_NAME${NC}"
        exit 1
    fi
    
    echo -e "${GREEN}Container $DB_CONTAINER_NAME is running.${NC}"
}

# Function to run a PostgreSQL query in the Docker container
run_query() {
    local query_name="$1"
    local query="$2"
    
    echo -e "\n${YELLOW}=== $query_name ===${NC}"
    echo -e "${GRAY}Query: $query${NC}"
    
    echo -e "${CYAN}Executing query...${NC}"
    docker exec -i $DB_CONTAINER_NAME psql -d $DB_NAME -U $DB_USER -c "$query"
}

# Function for interactive psql connection inside Docker
start_interactive_session() {
    echo -e "\n${YELLOW}=== Interactive PostgreSQL Session ===${NC}"
    echo -e "${CYAN}Connecting to PostgreSQL in container $DB_CONTAINER_NAME...${NC}"
    
    echo -e "${GREEN}Starting interactive session (type \q to exit)...${NC}"
    docker exec -it $DB_CONTAINER_NAME psql -d $DB_NAME -U $DB_USER
}

# Function to export data to CSV file
export_to_csv() {
    local query_name="$1"
    local query="$2"
    local output_file="$3"
    
    echo -e "\n${YELLOW}=== Exporting $query_name to $output_file ===${NC}"
    echo -e "${GRAY}Query: $query${NC}"
    
    # Create directory if it doesn't exist
    mkdir -p "$(dirname "$output_file")"
    
    echo -e "${CYAN}Exporting data...${NC}"
    docker exec -i $DB_CONTAINER_NAME psql -d $DB_NAME -U $DB_USER -c "COPY ($query) TO STDOUT WITH CSV HEADER" > "$output_file"
    
    if [ -f "$output_file" ]; then
        echo -e "${GREEN}Data exported successfully to $output_file${NC}"
    else
        echo -e "${RED}Failed to export data.${NC}"
    fi
}

# Function to show menu and handle user's choice
show_menu() {
    echo -e "\n${CYAN}Tresata Data Ingestion Service - Docker Database Query Tool${NC}"
    echo -e "${CYAN}=======================================================${NC}"
    echo -e "1. List all ingestion jobs"
    echo -e "2. List jobs by status (CREATED, QUEUED, PROCESSING, COMPLETED, FAILED)"
    echo -e "3. View job logs"
    echo -e "4. View data statistics"
    echo -e "5. View detailed job information"
    echo -e "6. Count records by status"
    echo -e "7. Interactive PostgreSQL session"
    echo -e "8. Export table data to CSV"
    echo -e "9. Show database schema"
    echo -e "10. Exit"
    
    read -p $'\nEnter your choice (1-10): ' choice
    
    case $choice in
        1)
            run_query "All Ingestion Jobs" "SELECT * FROM ingestion_jobs ORDER BY created_at DESC;"
            ;;
        2)
            read -p "Enter status (CREATED, QUEUED, PROCESSING, COMPLETED, FAILED): " status
            run_query "Jobs with Status: $status" "SELECT * FROM ingestion_jobs WHERE status = '$status' ORDER BY created_at DESC;"
            ;;
        3)
            read -p "Enter Job ID (leave empty for all logs): " job_id
            if [ -z "$job_id" ]; then
                run_query "All Job Logs" "SELECT * FROM job_logs ORDER BY timestamp DESC LIMIT 100;"
            else
                run_query "Logs for Job ID: $job_id" "SELECT * FROM job_logs WHERE job_id = $job_id ORDER BY timestamp DESC;"
            fi
            ;;
        4)
            read -p "Enter Job ID (leave empty for all statistics): " job_id
            if [ -z "$job_id" ]; then
                run_query "All Data Statistics" "SELECT * FROM data_statistics ORDER BY timestamp DESC;"
            else
                run_query "Statistics for Job ID: $job_id" "SELECT * FROM data_statistics WHERE job_id = $job_id ORDER BY timestamp DESC;"
            fi
            ;;
        5)
            read -p "Enter Job ID: " job_id
            run_query "Detailed Information for Job ID: $job_id" "SELECT j.*, (SELECT COUNT(*) FROM job_logs l WHERE l.job_id = j.id) AS log_count, (SELECT SUM(records_processed) FROM data_statistics s WHERE s.job_id = j.id) AS total_records_processed, (SELECT SUM(records_failed) FROM data_statistics s WHERE s.job_id = j.id) AS total_records_failed FROM ingestion_jobs j WHERE j.id = $job_id;"
            ;;
        6)
            run_query "Job Count by Status" "SELECT status, COUNT(*) FROM ingestion_jobs GROUP BY status ORDER BY COUNT(*) DESC;"
            ;;
        7)
            start_interactive_session
            ;;
        8)
            echo -e "${YELLOW}Available tables:${NC}"
            docker exec $DB_CONTAINER_NAME psql -d $DB_NAME -U $DB_USER -c "\dt" -t
            
            read -p "Enter table name to export: " table_name
            read -p "Enter output path (e.g., ./exports/data.csv): " output_path
            
            if [ -z "$table_name" ] || [ -z "$output_path" ]; then
                echo -e "${RED}Table name and output path cannot be empty.${NC}"
            else
                export_to_csv "Table: $table_name" "SELECT * FROM $table_name" "$output_path"
            fi
            ;;
        9)
            run_query "Database Schema" "SELECT table_name, column_name, data_type FROM information_schema.columns WHERE table_schema = 'public' ORDER BY table_name, ordinal_position;"
            ;;
        10)
            echo -e "${CYAN}Exiting database query tool. Goodbye!${NC}"
            exit 0
            ;;
        *)
            echo -e "${RED}Invalid choice. Please enter a number between 1 and 10.${NC}"
            ;;
    esac
}

# Main script

# Check if the Docker container exists and is running
check_docker_container

# Main loop
while true; do
    show_menu
done
