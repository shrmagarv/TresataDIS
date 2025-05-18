# Tresata Data Ingestion Service - Database Query Script
# This script helps you query the PostgreSQL database to check job data, logs, and statistics

# Database connection parameters
$dbHost = "localhost"
$dbPort = 4020 # Port mapped in docker-compose.yml
$dbName = "tresata_dis"
$dbUser = "postgres"
$dbPassword = "postgres"

# Function to run a PostgreSQL query and display results
function Invoke-PostgresQuery {
    param (
        [string]$QueryName,
        [string]$Query
    )
    
    Write-Host "`n=== $QueryName ===" -ForegroundColor Yellow
    Write-Host "Query: $Query" -ForegroundColor Gray
    
    # Create a temporary SQL file
    $tempSqlFile = [System.IO.Path]::GetTempFileName() + ".sql"
    $Query | Out-File -FilePath $tempSqlFile -Encoding utf8
    
    # Check if using Docker
    $usingDocker = $true
    try {
        $dockerCheck = docker ps --filter "name=tresata-dis-postgres" --format "{{.Names}}"
        if (-not $dockerCheck) {
            $usingDocker = $false
        }
    } catch {
        $usingDocker = $false
    }
    
    try {
        Write-Host "Executing query..." -ForegroundColor Cyan
        
        if ($usingDocker) {
            # Try using Docker directly if available
            Write-Host "Using Docker PostgreSQL container..." -ForegroundColor Gray
            $result = Get-Content $tempSqlFile | docker exec -i tresata-dis-postgres psql -d $dbName -U $dbUser
        } else {
            # Try using local psql
            Write-Host "Using local PostgreSQL client..." -ForegroundColor Gray
            $env:PGPASSWORD = $dbPassword
            $result = psql -h $dbHost -p $dbPort -d $dbName -U $dbUser -f $tempSqlFile
        }
        
        if ($result) {
            Write-Host "Results:" -ForegroundColor Green
            $result | ForEach-Object { Write-Host $_ }
        } else {
            Write-Host "No results or command executed successfully without output." -ForegroundColor Gray
        }
    }
    catch {
        Write-Host "Error executing query: $_" -ForegroundColor Red
        Write-Host "Options to fix:" -ForegroundColor Yellow
        Write-Host "1. Make sure PostgreSQL client (psql) is installed and in your PATH" -ForegroundColor Yellow
        Write-Host "   Download from: https://www.postgresql.org/download/windows/" -ForegroundColor Yellow
        Write-Host "2. If using Docker, make sure the container is running:" -ForegroundColor Yellow
        Write-Host "   docker ps | findstr tresata-dis-postgres" -ForegroundColor Yellow
        Write-Host "3. Check that the database connection details are correct:" -ForegroundColor Yellow
        Write-Host "   Host: $dbHost, Port: $dbPort, Database: $dbName" -ForegroundColor Yellow
    }
    finally {
        $env:PGPASSWORD = ""
        # Clean up the temporary file
        if (Test-Path $tempSqlFile) {
            Remove-Item $tempSqlFile -Force
        }
    }
}

# Function for direct psql connection
function Start-PostgresInteractive {
    Write-Host "`n=== Interactive PostgreSQL Session ===" -ForegroundColor Yellow
    Write-Host "Connecting to PostgreSQL at $dbHost\:\$dbPort as $dbUser..." -ForegroundColor Cyan
    
    # Check if using Docker
    $usingDocker = $true
    try {
        $dockerCheck = docker ps --filter "name=tresata-dis-postgres" --format "{{.Names}}"
        if (-not $dockerCheck) {
            $usingDocker = $false
        }
    } catch {
        $usingDocker = $false
    }
    
    try {
        if ($usingDocker) {
            # Try using Docker directly if available
            Write-Host "Using Docker PostgreSQL container (type \q to exit)..." -ForegroundColor Green
            docker exec -it tresata-dis-postgres psql -d $dbName -U $dbUser
        } else {
            # Try using local psql
            $env:PGPASSWORD = $dbPassword
            Write-Host "Using local PostgreSQL client (type \q to exit)..." -ForegroundColor Green
            psql -h $dbHost -p $dbPort -d $dbName -U $dbUser
        }
    }
    catch {
        Write-Host "Error connecting to PostgreSQL: $_" -ForegroundColor Red
        Write-Host "Options to fix:" -ForegroundColor Yellow
        Write-Host "1. Make sure PostgreSQL client (psql) is installed and in your PATH" -ForegroundColor Yellow
        Write-Host "   Download from: https://www.postgresql.org/download/windows/" -ForegroundColor Yellow
        Write-Host "2. If using Docker, make sure the container is running:" -ForegroundColor Yellow
        Write-Host "   docker ps | findstr tresata-dis-postgres" -ForegroundColor Yellow
    }
    finally {
        $env:PGPASSWORD = ""
    }
}

# Check for PostgreSQL access options
$psqlAvailable = $null -ne (Get-Command "psql" -ErrorAction SilentlyContinue)
$dockerAvailable = $false

try {
    $dockerCheck = docker ps --filter "name=tresata-dis-postgres" --format "{{.Names}}"
    if ($dockerCheck) {
        $dockerAvailable = $true
        Write-Host "Found PostgreSQL Docker container: $dockerCheck" -ForegroundColor Green
    }
} catch {
    # Docker not available or not running
}

if (-not $psqlAvailable -and -not $dockerAvailable) {
    Write-Host "WARNING: No PostgreSQL access method found." -ForegroundColor Yellow
    Write-Host "Options:" -ForegroundColor White
    Write-Host "1. Install PostgreSQL client (psql) from: https://www.postgresql.org/download/windows/" -ForegroundColor White
    Write-Host "2. Ensure the Docker container 'tresata-dis-postgres' is running: docker-compose up -d postgres" -ForegroundColor White
    Write-Host "3. Use a GUI tool like pgAdmin or DBeaver to connect to your database." -ForegroundColor White
    
    $continue = Read-Host "Do you want to continue anyway? (y/n)"
    if ($continue -ne "y") {
        exit 1
    }
    
    Write-Host "Continuing without verified PostgreSQL access. Some features may not work." -ForegroundColor Yellow
} else {
    if ($psqlAvailable) {
        Write-Host "PostgreSQL client (psql) is available in PATH." -ForegroundColor Green
    }
    if ($dockerAvailable) {
        Write-Host "PostgreSQL Docker container is running." -ForegroundColor Green
    }
}

# Show menu and handle user's choice
function Show-Menu {
    Write-Host "`nTresata Data Ingestion Service - Database Query Tool" -ForegroundColor Cyan
    Write-Host "=================================================" -ForegroundColor Cyan
    Write-Host "1. List all ingestion jobs" -ForegroundColor White
    Write-Host "2. List jobs by status (CREATED, QUEUED, PROCESSING, COMPLETED, FAILED)" -ForegroundColor White
    Write-Host "3. View job logs" -ForegroundColor White
    Write-Host "4. View data statistics" -ForegroundColor White
    Write-Host "5. View detailed job information" -ForegroundColor White
    Write-Host "6. Count records by status" -ForegroundColor White
    Write-Host "7. Interactive PostgreSQL session" -ForegroundColor White
    Write-Host "8. Exit" -ForegroundColor White
    
    $choice = Read-Host "`nEnter your choice (1-8)"
    
    switch ($choice) {
        "1" {
            Invoke-PostgresQuery -QueryName "All Ingestion Jobs" -Query "SELECT * FROM ingestion_jobs ORDER BY created_at DESC;"
        }
        "2" {
            $status = Read-Host "Enter status (CREATED, QUEUED, PROCESSING, COMPLETED, FAILED)"
            Invoke-PostgresQuery -QueryName "Jobs with Status: $status" -Query "SELECT * FROM ingestion_jobs WHERE status = '$status' ORDER BY created_at DESC;"
        }
        "3" {
            $jobId = Read-Host "Enter Job ID (leave empty for all logs)"
            if ([string]::IsNullOrEmpty($jobId)) {
                Invoke-PostgresQuery -QueryName "All Job Logs" -Query "SELECT * FROM job_logs ORDER BY timestamp DESC LIMIT 100;"
            } else {
                Invoke-PostgresQuery -QueryName "Logs for Job ID: $jobId" -Query "SELECT * FROM job_logs WHERE job_id = $jobId ORDER BY timestamp DESC;"
            }
        }
        "4" {
            $jobId = Read-Host "Enter Job ID (leave empty for all statistics)"
            if ([string]::IsNullOrEmpty($jobId)) {
                Invoke-PostgresQuery -QueryName "All Data Statistics" -Query "SELECT * FROM data_statistics ORDER BY timestamp DESC;"
            } else {
                Invoke-PostgresQuery -QueryName "Statistics for Job ID: $jobId" -Query "SELECT * FROM data_statistics WHERE job_id = $jobId ORDER BY timestamp DESC;"
            }
        }
        "5" {
            $jobId = Read-Host "Enter Job ID"
            Invoke-PostgresQuery -QueryName "Detailed Information for Job ID: $jobId" -Query @"
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
            Invoke-PostgresQuery -QueryName "Job Count by Status" -Query "SELECT status, COUNT(*) FROM ingestion_jobs GROUP BY status ORDER BY COUNT(*) DESC;"
        }
        "7" {
            Start-PostgresInteractive
        }
        "8" {
            return $false
        }
        default {
            Write-Host "Invalid choice. Please enter a number between 1 and 8." -ForegroundColor Red
        }
    }
    
    return $true
}

# Main loop
$continue = $true
while ($continue) {
    $continue = Show-Menu
}

Write-Host "Exiting database query tool. Goodbye!" -ForegroundColor Cyan
