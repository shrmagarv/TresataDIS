#!/bin/bash
# Tresata Data Ingestion Service - Quick Docker Database Commands (Bash version)
# This file contains common docker exec commands for database operations

# Colors for output
CYAN='\033[0;36m'
YELLOW='\033[0;33m'
WHITE='\033[1;37m'
GRAY='\033[0;37m'
NC='\033[0m' # No Color

# PostgreSQL container name
DB_CONTAINER_NAME="tresata-dis-postgres"

# Database connection parameters
DB_NAME="tresata_dis"
DB_USER="postgres"

echo -e "${CYAN}Tresata Data Ingestion Service - Quick Database Commands${NC}"
echo -e "${CYAN}===================================================${NC}"
echo -e "${YELLOW}Copy and paste any of these commands to perform database operations:${NC}"

echo -e "\n${WHITE}1. Check container status:${NC}"
echo -e "${GRAY}docker ps -a | grep tresata-dis-postgres${NC}"

echo -e "\n${WHITE}2. Start PostgreSQL container (if not running):${NC}"
echo -e "${GRAY}docker start $DB_CONTAINER_NAME${NC}"

echo -e "\n${WHITE}3. Interactive PostgreSQL session:${NC}"
echo -e "${GRAY}docker exec -it $DB_CONTAINER_NAME psql -d $DB_NAME -U $DB_USER${NC}"

echo -e "\n${WHITE}4. List all tables:${NC}"
echo -e "${GRAY}docker exec -it $DB_CONTAINER_NAME psql -d $DB_NAME -U $DB_USER -c '\dt'${NC}"

echo -e "\n${WHITE}5. View ingestion jobs:${NC}"
echo -e "${GRAY}docker exec -it $DB_CONTAINER_NAME psql -d $DB_NAME -U $DB_USER -c 'SELECT * FROM ingestion_jobs ORDER BY created_at DESC;'${NC}"

echo -e "\n${WHITE}6. View job logs:${NC}"
echo -e "${GRAY}docker exec -it $DB_CONTAINER_NAME psql -d $DB_NAME -U $DB_USER -c 'SELECT * FROM job_logs ORDER BY timestamp DESC LIMIT 50;'${NC}"

echo -e "\n${WHITE}7. View data statistics:${NC}"
echo -e "${GRAY}docker exec -it $DB_CONTAINER_NAME psql -d $DB_NAME -U $DB_USER -c 'SELECT * FROM data_statistics ORDER BY timestamp DESC;'${NC}"

echo -e "\n${WHITE}8. View database schema:${NC}"
echo -e "${GRAY}docker exec -it $DB_CONTAINER_NAME psql -d $DB_NAME -U $DB_USER -c \"SELECT table_name, column_name, data_type FROM information_schema.columns WHERE table_schema = 'public' ORDER BY table_name, ordinal_position;\"${NC}"

echo -e "\n${WHITE}9. Create a database backup:${NC}"
echo -e "${GRAY}docker exec -it $DB_CONTAINER_NAME pg_dump -U $DB_USER $DB_NAME > backup_\$(date +%Y-%m-%d).sql${NC}"

echo -e "\n${WHITE}10. Execute SQL from file:${NC}"
echo -e "${GRAY}cat ./your-script.sql | docker exec -i $DB_CONTAINER_NAME psql -d $DB_NAME -U $DB_USER${NC}"

echo -e "\n${CYAN}Note: For interactive script with more features, run:${NC}"
echo -e "${YELLOW}./docker-db-query.sh${NC}"
