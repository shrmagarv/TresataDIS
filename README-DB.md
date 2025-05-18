# Database Operations Guide for TresataDIS

This guide explains how to interact with the PostgreSQL database used by the Tresata Data Ingestion Service (TresataDIS).

## Database Configuration

The application uses a PostgreSQL database with the following default configuration:
- **Database Host**: localhost 
- **Database Port**: 4020 (mapped from container's port 5432)
- **Database Name**: tresata_dis
- **Username**: postgres
- **Password**: postgres

## Scripts Overview

This repository includes several scripts to help you interact with the database:

### For Windows (PowerShell)

1. **db-query.ps1** - Original script that uses local `psql` client to connect to the database directly
2. **docker-db-query.ps1** - Interactive script that uses Docker commands to interact with the database in the container
3. **docker-db-commands.ps1** - Quick reference for common Docker database commands

### For Linux/Mac (Bash)

1. **docker-db-query.sh** - Interactive script that uses Docker commands to interact with the database in the container
2. **docker-db-commands.sh** - Quick reference for common Docker database commands

## Using Docker Scripts (Recommended)

The Docker scripts are the recommended way to interact with the database as they only require Docker to be installed and running - no need for a local PostgreSQL client.

### Running PowerShell Scripts

If you encounter execution policy restrictions when running the PowerShell scripts, you can use one of these approaches:

```powershell
# Option 1: Run with execution policy bypass (one-time)
PowerShell -ExecutionPolicy Bypass -File ./docker-db-query.ps1

# Option 2: Use the batch file wrapper
.\run-db-query.bat

# Option 3: Change execution policy for current user (requires admin privileges)
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser
```

### Interactive Query Tool

1. Make sure Docker and the PostgreSQL container are running:
   ```bash
   docker-compose up -d postgres
   ```

2. Run the interactive script:
   - Windows: `.\docker-db-query.ps1`
   - Linux/Mac: `./docker-db-query.sh`

3. Use the menu options to perform various database operations:
   - List ingestion jobs
   - View job logs
   - Check data statistics
   - Interactive PostgreSQL session
   - Export data to CSV
   - View database schema

### Quick Commands

For quick database operations without the interactive menu:

1. View available commands:
   - Windows: `.\docker-db-commands.ps1`
   - Linux/Mac: `./docker-db-commands.sh`

2. Copy and paste the desired command from the output

## Common Database Tasks

### Checking Database Schema

```bash
# Using interactive tool
# Select "9. Show database schema" from the menu

# Using direct command
docker exec -it tresata-dis-postgres psql -d tresata_dis -U postgres -c "SELECT table_name, column_name, data_type FROM information_schema.columns WHERE table_schema = 'public' ORDER BY table_name, ordinal_position;"
```

### Viewing Ingestion Jobs

```bash
# Using direct command
docker exec -it tresata-dis-postgres psql -d tresata_dis -U postgres -c "SELECT * FROM ingestion_jobs ORDER BY created_at DESC;"
```

### Creating a Database Backup

```bash
# Windows PowerShell
docker exec -it tresata-dis-postgres pg_dump -U postgres tresata_dis > backup_$(Get-Date -Format 'yyyy-MM-dd').sql

# Linux/Mac Bash
docker exec -it tresata-dis-postgres pg_dump -U postgres tresata_dis > backup_$(date +%Y-%m-%d).sql
```

### Running Custom SQL Queries

```bash
# Interactive PostgreSQL session
docker exec -it tresata-dis-postgres psql -d tresata_dis -U postgres

# Execute a single query
docker exec -it tresata-dis-postgres psql -d tresata_dis -U postgres -c "YOUR SQL QUERY HERE;"

# Run SQL from file
cat ./your-script.sql | docker exec -i tresata-dis-postgres psql -d tresata_dis -U postgres
```

## Database Schema

The primary tables in the database include:

1. **ingestion_jobs** - Records of data ingestion jobs
2. **job_logs** - Detailed logs for each job
3. **data_statistics** - Statistics about processed data

For a complete schema view, use the "Show database schema" option in the interactive tool or run the schema query directly.

## Troubleshooting

### Container Not Running

If you get an error about the container not running, start it with:

```bash
docker start tresata-dis-postgres
```

Or bring up the complete environment with:

```bash
docker-compose up -d postgres
```

### Database Connection Issues

Ensure the Docker container is running and the port mapping (4020:5432) is correct. You can verify with:

```bash
docker ps | grep tresata-dis-postgres
```

### Permission Denied

If you get permission errors when executing scripts:

```bash
# Linux/Mac
chmod +x docker-db-query.sh docker-db-commands.sh
```
