# Tresata Data Ingestion Service - Docker Database Query Script
# This script helps you query the PostgreSQL database inside the Docker container
# without requiring psql to be installed on the host machine.

# Docker container name for PostgreSQL
$dbContainerName = "tresata-dis-postgres"

# Database connection parameters
$dbName = "tresata_dis"
$dbUser = "postgres"
$dbPassword = "postgres"

# Function to check if Docker is running and the container exists
function Test-DockerContainer {
    try {
        $containerExists = docker ps -a --format "{{.Names}}" | Select-String -Pattern "^$dbContainerName$" -Quiet
        if (-not $containerExists) {
            Write-Host "PostgreSQL container '$dbContainerName' not found." -ForegroundColor Red
            Write-Host "Make sure the container is running with:" -ForegroundColor Yellow
            Write-Host "docker-compose up -d postgres" -ForegroundColor Yellow
            return $false
        }
        
        $containerRunning = docker ps --format "{{.Names}}" | Select-String -Pattern "^$dbContainerName$" -Quiet
        if (-not $containerRunning) {
            Write-Host "PostgreSQL container '$dbContainerName' exists but is not running." -ForegroundColor Red
            Write-Host "Start the container with:" -ForegroundColor Yellow
            Write-Host "docker start $dbContainerName" -ForegroundColor Yellow
            return $false
        }
        
        return $true
    }
    catch {
        Write-Host "Error checking Docker container: $_" -ForegroundColor Red
        Write-Host "Make sure Docker is installed and running." -ForegroundColor Yellow
        return $false
    }
}

# Function to run a PostgreSQL query in the Docker container
function Invoke-DockerPostgresQuery {
    param (
        [string]$QueryName,
        [string]$Query
    )
    
    Write-Host "`n=== $QueryName ===" -ForegroundColor Yellow
    Write-Host "Query: $Query" -ForegroundColor Gray
    
    # Run the query using docker exec
    try {
        Write-Host "Executing query..." -ForegroundColor Cyan
        $result = docker exec -i $dbContainerName psql -d $dbName -U $dbUser -c "$Query"
        
        if ($result) {
            Write-Host "Results:" -ForegroundColor Green
            $result | ForEach-Object { Write-Host $_ }
        } else {
            Write-Host "No results or command executed successfully without output." -ForegroundColor Gray
        }
    }
    catch {
        Write-Host "Error executing query: $_" -ForegroundColor Red
    }
}

# Function for interactive psql connection inside Docker
function Start-DockerPostgresInteractive {
    Write-Host "`n=== Interactive PostgreSQL Session ===" -ForegroundColor Yellow
    Write-Host "Connecting to PostgreSQL in container $dbContainerName..." -ForegroundColor Cyan
    
    try {
        Write-Host "Starting interactive session (type \q to exit)..." -ForegroundColor Green
        docker exec -it $dbContainerName psql -d $dbName -U $dbUser
    }
    catch {
        Write-Host "Error connecting to PostgreSQL: $_" -ForegroundColor Red
    }
}

# Function to export data to CSV file
function Export-DataToCsv {
    param (
        [string]$QueryName,
        [string]$Query,
        [string]$OutputFile
    )
    
    Write-Host "`n=== Exporting $QueryName to $OutputFile ===" -ForegroundColor Yellow
    Write-Host "Query: $Query" -ForegroundColor Gray
    
    try {
        # Create directory if it doesn't exist
        $directory = Split-Path -Parent $OutputFile
        if (-not (Test-Path $directory)) {
            New-Item -ItemType Directory -Path $directory -Force | Out-Null
        }
        
        # Run query and export to CSV
        Write-Host "Exporting data..." -ForegroundColor Cyan
        docker exec -i $dbContainerName psql -d $dbName -U $dbUser -c "COPY ($Query) TO STDOUT WITH CSV HEADER" > $OutputFile
        
        if (Test-Path $OutputFile) {
            Write-Host "Data exported successfully to $OutputFile" -ForegroundColor Green
        } else {
            Write-Host "Failed to export data." -ForegroundColor Red
        }
    }
    catch {
        Write-Host "Error exporting data: $_" -ForegroundColor Red
    }
}

# Show menu and handle user's choice
function Show-Menu {
    Write-Host "`nTresata Data Ingestion Service - Docker Database Query Tool" -ForegroundColor Cyan
    Write-Host "=======================================================" -ForegroundColor Cyan
    Write-Host "1. List all ingestion jobs" -ForegroundColor White
    Write-Host "2. List jobs by status (CREATED, QUEUED, PROCESSING, COMPLETED, FAILED)" -ForegroundColor White
    Write-Host "3. View job logs" -ForegroundColor White
    Write-Host "4. View data statistics" -ForegroundColor White
    Write-Host "5. View detailed job information" -ForegroundColor White
    Write-Host "6. Count records by status" -ForegroundColor White
    Write-Host "7. Interactive PostgreSQL session" -ForegroundColor White
    Write-Host "8. Export table data to CSV" -ForegroundColor White
    Write-Host "9. Show database schema" -ForegroundColor White
    Write-Host "10. Exit" -ForegroundColor White
    
    $choice = Read-Host "`nEnter your choice (1-10)"
    
    switch ($choice) {
        "1" {
            Invoke-DockerPostgresQuery -QueryName "All Ingestion Jobs" -Query "SELECT * FROM ingestion_jobs ORDER BY created_at DESC;"
        }
        "2" {
            $status = Read-Host "Enter status (CREATED, QUEUED, PROCESSING, COMPLETED, FAILED)"
            Invoke-DockerPostgresQuery -QueryName "Jobs with Status: $status" -Query "SELECT * FROM ingestion_jobs WHERE status = '$status' ORDER BY created_at DESC;"
        }
        "3" {
            $jobId = Read-Host "Enter Job ID (leave empty for all logs)"
            if ([string]::IsNullOrEmpty($jobId)) {
                Invoke-DockerPostgresQuery -QueryName "All Job Logs" -Query "SELECT * FROM job_logs ORDER BY timestamp DESC LIMIT 100;"
            } else {
                Invoke-DockerPostgresQuery -QueryName "Logs for Job ID: $jobId" -Query "SELECT * FROM job_logs WHERE job_id = $jobId ORDER BY timestamp DESC;"
            }
        }
        "4" {
            $jobId = Read-Host "Enter Job ID (leave empty for all statistics)"
            if ([string]::IsNullOrEmpty($jobId)) {
                Invoke-DockerPostgresQuery -QueryName "All Data Statistics" -Query "SELECT * FROM data_statistics ORDER BY timestamp DESC;"
            } else {
                Invoke-DockerPostgresQuery -QueryName "Statistics for Job ID: $jobId" -Query "SELECT * FROM data_statistics WHERE job_id = $jobId ORDER BY timestamp DESC;"
            }
        }
        "5" {
            $jobId = Read-Host "Enter Job ID"
            Invoke-DockerPostgresQuery -QueryName "Detailed Information for Job ID: $jobId" -Query @"
SELECT 
    j.*, 
    (SELECT COUNT(*) FROM job_logs l WHERE l.job_id = j.id) AS log_count,
    (SELECT SUM(records_processed) FROM data_statistics s WHERE s.job_id = j.id) AS total_records_processed,
    (SELECT SUM(records_failed) FROM data_statistics s WHERE s.job_id = j.id) AS total_records_failed
FROM 
    ingestion_jobs j
WHERE 
    j.id = $jobId;
"@
        }
        "6" {
            Invoke-DockerPostgresQuery -QueryName "Job Count by Status" -Query "SELECT status, COUNT(*) FROM ingestion_jobs GROUP BY status ORDER BY COUNT(*) DESC;"
        }
        "7" {
            Start-DockerPostgresInteractive
        }
        "8" {
            $tables = docker exec $dbContainerName psql -d $dbName -U $dbUser -c "\dt" -t | ForEach-Object { $_.Trim() }
            Write-Host "Available tables:" -ForegroundColor Yellow
            $tables | ForEach-Object { Write-Host "- $_" -ForegroundColor White }
            
            $tableName = Read-Host "Enter table name to export"
            $outputPath = Read-Host "Enter output path (e.g., ./exports/data.csv)"
            
            if ([string]::IsNullOrEmpty($tableName) -or [string]::IsNullOrEmpty($outputPath)) {
                Write-Host "Table name and output path cannot be empty." -ForegroundColor Red
            } else {
                Export-DataToCsv -QueryName "Table: $tableName" -Query "SELECT * FROM $tableName" -OutputFile $outputPath
            }
        }
        "9" {
            Invoke-DockerPostgresQuery -QueryName "Database Schema" -Query @"
SELECT 
    table_name, 
    column_name, 
    data_type 
FROM 
    information_schema.columns 
WHERE 
    table_schema = 'public' 
ORDER BY 
    table_name, 
    ordinal_position;
"@
        }
        "10" {
            return $false
        }
        default {
            Write-Host "Invalid choice. Please enter a number between 1 and 10." -ForegroundColor Red
        }
    }
    
    return $true
}

# Check if Docker is available
$dockerAvailable = $null -ne (Get-Command "docker" -ErrorAction SilentlyContinue)
if (-not $dockerAvailable) {
    Write-Host "Docker command not found." -ForegroundColor Red
    Write-Host "Please install Docker from: https://www.docker.com/products/docker-desktop/" -ForegroundColor Yellow
    exit 1
}

# Check if the Docker container exists and is running
if (-not (Test-DockerContainer)) {
    exit 1
}

# Main loop
$continue = $true
while ($continue) {
    $continue = Show-Menu
}

Write-Host "Exiting database query tool. Goodbye!" -ForegroundColor Cyan
