# Tresata Data Ingestion Service - Master Test Script
# This script runs all test scripts in sequence and summarizes the results

# Set the script root directory to ensure all paths are relative to the script
$scriptRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
$dataPath = Join-Path -Path $scriptRoot -ChildPath "data"
$outputPath = Join-Path -Path $dataPath -ChildPath "output"

# Function to check and prepare test environment
function Initialize-TestEnvironment {
    # Create data directory if it doesn't exist
    if (-not (Test-Path -Path $dataPath)) {
        Write-Host "Creating data directory..." -ForegroundColor Yellow
        New-Item -ItemType Directory -Path $dataPath -Force | Out-Null
    }
    
    # Create sample files if they don't exist
    $sampleCsvPath = Join-Path -Path $dataPath -ChildPath "sample.csv"
    if (-not (Test-Path -Path $sampleCsvPath)) {
        Write-Host "Creating sample CSV file..." -ForegroundColor Yellow
        @"
id,name,email,age,city
1,John Doe,john.doe@example.com,35,New York
2,Jane Smith,jane.smith@example.com,28,San Francisco
3,Bob Johnson,bob.johnson@example.com,42,Chicago
4,Alice Brown,alice.brown@example.com,31,Boston
5,Charlie Davis,charlie.davis@example.com,39,Seattle
"@ | Out-File -FilePath $sampleCsvPath -Encoding utf8
    }
    
    $productsCsvPath = Join-Path -Path $dataPath -ChildPath "products.csv"
    if (-not (Test-Path -Path $productsCsvPath)) {
        Write-Host "Creating products CSV file..." -ForegroundColor Yellow
        @"
product_id,product_name,category,price,stock_quantity,last_updated
1001,Laptop X1,Electronics,1299.99,45,2025-03-15
1002,Wireless Headphones,Electronics,199.99,120,2025-03-14
1003,Smart Watch Pro,Electronics,249.99,85,2025-03-13
1004,Coffee Maker Deluxe,Appliances,79.99,30,2025-03-12
1005,Blender Ultimate,Appliances,149.99,20,2025-03-11
1006,Desk Chair Ergonomic,Furniture,199.99,15,2025-03-10
1007,Standing Desk,Furniture,349.99,10,2025-03-09
1008,LED Desk Lamp,Home Office,39.99,50,2025-03-08
1009,Wireless Keyboard,Electronics,59.99,75,2025-03-07
1010,External Hard Drive 2TB,Electronics,89.99,40,2025-03-06
"@ | Out-File -FilePath $productsCsvPath -Encoding utf8
    }
    
    $sampleJsonPath = Join-Path -Path $dataPath -ChildPath "sample.json"
    if (-not (Test-Path -Path $sampleJsonPath)) {
        Write-Host "Creating sample JSON file..." -ForegroundColor Yellow
        @"
[
  {
    "id": 1,
    "name": "John Doe",
    "email": "john.doe@example.com",
    "is_active": true,
    "created_at": "2025-03-15T10:30:00Z"
  },
  {
    "id": 2,
    "name": "Jane Smith",
    "email": "jane.smith@example.com",
    "is_active": true,
    "created_at": "2025-03-14T14:45:00Z"
  },
  {
    "id": 3,
    "name": "Bob Johnson",
    "email": "bob.johnson@example.com",
    "is_active": false,
    "created_at": "2025-03-13T09:15:00Z"
  }
]
"@ | Out-File -FilePath $sampleJsonPath -Encoding utf8
    }
    
    $ordersXmlPath = Join-Path -Path $dataPath -ChildPath "orders.xml"
    if (-not (Test-Path -Path $ordersXmlPath)) {
        Write-Host "Creating orders XML file..." -ForegroundColor Yellow
        @"
<?xml version="1.0" encoding="UTF-8"?>
<orders>
  <order>
    <id>1001</id>
    <customer_id>101</customer_id>
    <order_date>2025-03-15</order_date>
    <payment_method>Credit Card</payment_method>
    <items>
      <item>
        <product_id>1001</product_id>
        <quantity>1</quantity>
        <unit_price>1299.99</unit_price>
      </item>
      <item>
        <product_id>1002</product_id>
        <quantity>1</quantity>
        <unit_price>199.99</unit_price>
      </item>
    </items>
    <total>1499.98</total>
  </order>
  <order>
    <id>1002</id>
    <customer_id>102</customer_id>
    <order_date>2025-03-14</order_date>
    <payment_method>PayPal</payment_method>
    <items>
      <item>
        <product_id>1003</product_id>
        <quantity>1</quantity>
        <unit_price>249.99</unit_price>
      </item>
    </items>
    <total>249.99</total>
  </order>
</orders>
"@ | Out-File -FilePath $ordersXmlPath -Encoding utf8
    }
}

# Initialize the test environment
Write-Host "Initializing test environment..." -ForegroundColor Cyan
Initialize-TestEnvironment

# Initialize the test database
Initialize-TestDatabase

# Clear the output directory
if (Test-Path -Path $outputPath) {
    Write-Host "Cleaning output directory..." -ForegroundColor Yellow
    Remove-Item -Path "$outputPath\*" -Recurse -Force
} else {
    Write-Host "Creating output directory..." -ForegroundColor Yellow
    New-Item -ItemType Directory -Path $outputPath -Force | Out-Null
}

# Function to display a header
function Show-Header {
    param([string]$Title)
    
    $separator = "=" * ($Title.Length + 10)
    Write-Host "`n$separator" -ForegroundColor Magenta
    Write-Host "===  $Title  ===" -ForegroundColor Magenta
    Write-Host "$separator`n" -ForegroundColor Magenta
}

# Function to measure execution time
function Measure-ScriptExecution {
    param([string]$ScriptPath)
    
    # Check if the file exists in the current directory
    if (Test-Path -Path $ScriptPath) {
        $scriptName = (Get-Item $ScriptPath).Name
        Write-Host "Executing $scriptName..." -ForegroundColor Yellow
        
        $sw = [System.Diagnostics.Stopwatch]::StartNew()
        & $ScriptPath
        $sw.Stop()
        
        Write-Host "`n$scriptName completed in $($sw.Elapsed.TotalSeconds.ToString("0.00")) seconds" -ForegroundColor Green
    } else {
        Write-Host "Script not found: $ScriptPath" -ForegroundColor Red
        Write-Host "Make sure the script file exists in the current directory" -ForegroundColor Yellow
    }
}

# Set the location to the current script's directory
$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
Set-Location -Path $scriptDir

# Function to create test scripts if they don't exist
function New-TestScripts {
    # Define paths for test scripts
    $testApiPath = Join-Path -Path $scriptDir -ChildPath "test-api.ps1"
    $testKafkaPath = Join-Path -Path $scriptDir -ChildPath "test-kafka.ps1" 
    $testDbStoragePath = Join-Path -Path $scriptDir -ChildPath "test-db-storage.ps1"
    
    # Create test-api.ps1 if it doesn't exist
    if (-not (Test-Path -Path $testApiPath)) {
        Write-Host "Creating test-api.ps1..." -ForegroundColor Yellow
        @'
# Tresata Data Ingestion Service - API Test Script
$baseUrl = "http://localhost:8080/api/ingestion"
$scriptRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
$dataPath = Join-Path -Path $scriptRoot -ChildPath "data"
$outputPath = Join-Path -Path $dataPath -ChildPath "output"

Write-Host "API Test Script: This is a placeholder. Please implement actual API tests."
Write-Host "This script would normally test the REST API endpoints for data ingestion."
Write-Host "Data Path: $dataPath"
Write-Host "Output Path: $outputPath"
'@ | Out-File -FilePath $testApiPath -Encoding utf8
    }
    
    # Create test-kafka.ps1 if it doesn't exist
    if (-not (Test-Path -Path $testKafkaPath)) {
        Write-Host "Creating test-kafka.ps1..." -ForegroundColor Yellow
        @'
# Tresata Data Ingestion Service - Kafka Test Script
$baseUrl = "http://localhost:8080/api/kafka"
$scriptRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
$dataPath = Join-Path -Path $scriptRoot -ChildPath "data"

Write-Host "Kafka Test Script: This is a placeholder. Please implement actual Kafka tests."
Write-Host "This script would normally test the Kafka integration."
Write-Host "Data Path: $dataPath"
'@ | Out-File -FilePath $testKafkaPath -Encoding utf8
    }
    
    # Create test-db-storage.ps1 if it doesn't exist
    if (-not (Test-Path -Path $testDbStoragePath)) {
        Write-Host "Creating test-db-storage.ps1..." -ForegroundColor Yellow
        @'
# Tresata Data Ingestion Service - Database Storage Test Script
$baseUrl = "http://localhost:8080/api/ingestion"
$scriptRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
$dataPath = Join-Path -Path $scriptRoot -ChildPath "data"

Write-Host "Database Storage Test Script: This is a placeholder. Please implement actual database tests."
Write-Host "This script would normally test the DATABASE destination type functionality."
Write-Host "Data Path: $dataPath"

# Function to query the database
function Query-Database {
    param (
        [string]$Query,
        [string]$Description
    )
    
    Write-Host "`n=== $Description ===" -ForegroundColor Yellow
    Write-Host "Query: $Query" -ForegroundColor Gray
    
    try {
        $result = docker exec -i tresata-dis-postgres psql -d tresata_dis -U postgres -c "$Query"
        Write-Host "Result:" -ForegroundColor Green
        $result | ForEach-Object { Write-Host $_ }
        return $result
    }
    catch {
        Write-Host "Error executing query: $_" -ForegroundColor Red
        return $null
    }
}

# Check if PostgreSQL container is running
Write-Host "`nChecking if PostgreSQL container is running..." -ForegroundColor Cyan
docker ps -a --filter "name=tresata-dis-postgres" --format "{{.Status}}"

# Quick test query
Write-Host "`nRunning a test query..." -ForegroundColor Cyan
Query-Database -Query "SELECT current_timestamp as current_time;" -Description "Test Query"
'@ | Out-File -FilePath $testDbStoragePath -Encoding utf8
    }
}

# Create missing test scripts if needed
New-TestScripts

# Check if test scripts exist and show a message if they don't
$testApiPath = Join-Path -Path $scriptDir -ChildPath "test-api.ps1"
$testKafkaPath = Join-Path -Path $scriptDir -ChildPath "test-kafka.ps1" 
$testDbStoragePath = Join-Path -Path $scriptDir -ChildPath "test-db-storage.ps1"

if (-not (Test-Path -Path $testApiPath)) {
    Write-Host "Warning: test-api.ps1 not found at $testApiPath" -ForegroundColor Yellow
}
if (-not (Test-Path -Path $testKafkaPath)) {
    Write-Host "Warning: test-kafka.ps1 not found at $testKafkaPath" -ForegroundColor Yellow
}
if (-not (Test-Path -Path $testDbStoragePath)) {
    Write-Host "Warning: test-db-storage.ps1 not found at $testDbStoragePath" -ForegroundColor Yellow
}

# Run the API tests
Show-Header "API TESTS"
Measure-ScriptExecution -ScriptPath $testApiPath

# Run the Kafka tests
Show-Header "KAFKA TESTS"
Measure-ScriptExecution -ScriptPath $testKafkaPath

# Run the Database Storage tests
Show-Header "DATABASE STORAGE TESTS"

# Check if Docker is available before running database tests
$dockerAvailable = $null -ne (Get-Command "docker" -ErrorAction SilentlyContinue)
if (-not $dockerAvailable) {
    Write-Host "Docker is not available. Skipping database storage tests." -ForegroundColor Yellow
    Write-Host "Please install Docker to run database tests." -ForegroundColor Yellow
} else {
    # Check if PostgreSQL container exists
    $containerExists = docker ps -a --filter "name=tresata-dis-postgres" --format "{{.Names}}" 2>$null
    if (-not $containerExists) {
        Write-Host "PostgreSQL container doesn't exist. The test script will attempt to create it." -ForegroundColor Yellow
    }
    
    # Run the database tests
    Measure-ScriptExecution -ScriptPath $testDbStoragePath
}

# Display summary of results
Show-Header "TEST RESULTS SUMMARY"

# Check output files
$outputFiles = Get-ChildItem -Path $outputPath -File
$fileCount = $outputFiles.Count

Write-Host "Output Files Generated: $fileCount" -ForegroundColor Cyan

if ($fileCount -gt 0) {
    $table = @()
    foreach ($file in $outputFiles) {
        $size = "{0:N2} KB" -f ($file.Length / 1KB)
        $row = [PSCustomObject]@{
            FileName = $file.Name
            Size = $size
            LastModified = $file.LastWriteTime
        }
        $table += $row
    }
    
    $table | Format-Table -AutoSize
}

# Check the application log
$logPath = Join-Path -Path $scriptRoot -ChildPath "..\logs\tresata-dis.log"
if (Test-Path -Path $logPath) {
    $logSize = (Get-Item -Path $logPath).Length / 1KB
    Write-Host "Log File Size: $("{0:N2}" -f $logSize) KB" -ForegroundColor Cyan
    
    # Check for errors in the log
    $errorCount = (Select-String -Path $logPath -Pattern "ERROR").Count
    if ($errorCount -gt 0) {
        Write-Host "Errors Found in Log: $errorCount" -ForegroundColor Red
        Write-Host "Latest errors:" -ForegroundColor Red
        Select-String -Path $logPath -Pattern "ERROR" -Context 0,0 | 
            Select-Object -Last 3 | 
            ForEach-Object { Write-Host $_.Line -ForegroundColor Red }
    } else {
        Write-Host "No Errors Found in Log" -ForegroundColor Green
    }
}

# Check database tables created by DATABASE storage tests
try {
    Write-Host "`nChecking Database Tables:" -ForegroundColor Cyan
    
    # Check if Docker is available and container is running
    $containerExists = $null -ne (Get-Command "docker" -ErrorAction SilentlyContinue) -and 
                      (docker ps --format "{{.Names}}" | Select-String -Pattern "tresata-dis-postgres" -Quiet)
    
    if ($containerExists) {
        $result = docker exec -i tresata-dis-postgres psql -d tresata_dis -U postgres -c "
            SELECT table_name, 
                   (SELECT COUNT(*) FROM information_schema.columns WHERE table_name = t.table_name) as columns,
                   pg_total_relation_size(table_name::text) as size_bytes
            FROM information_schema.tables t 
            WHERE table_schema = 'public' 
              AND table_type = 'BASE TABLE' 
              AND table_name IN ('products', 'users', 'json_data')
            ORDER BY table_name;"
        
        if ($result) {
            Write-Host $result -ForegroundColor White
        } else {
            Write-Host "Could not query database tables" -ForegroundColor Yellow
        }
    } else {
        Write-Host "PostgreSQL container not found or Docker not available." -ForegroundColor Yellow
        Write-Host "Make sure the container is running with: docker-compose up -d postgres" -ForegroundColor Yellow
    }
} catch {
    Write-Host "Error checking database tables: $_" -ForegroundColor Red
}

# Next steps
Write-Host "`nAll tests completed. Next steps:" -ForegroundColor Yellow
Write-Host "1. Check the processed files in: $outputPath" -ForegroundColor White
Write-Host "2. View Kafka topics at: http://localhost:8090" -ForegroundColor White
Write-Host "3. Check application logs at: $logPath" -ForegroundColor White
Write-Host "4. View database tables via: $(Join-Path -Path $scriptRoot -ChildPath 'docker-db-query.ps1')" -ForegroundColor White

Write-Host "`n=== Testing Completed ===" -ForegroundColor Green

# Function to initialize and prepare test database
function Initialize-TestDatabase {
    Write-Host "Initializing test database..." -ForegroundColor Cyan
    
    # Check if Docker is available
    if (-not (Get-Command "docker" -ErrorAction SilentlyContinue)) {
        Write-Host "Docker is not available. Skipping database initialization." -ForegroundColor Yellow
        return
    }
      # Check if container exists
    $containerExists = docker ps -a --filter "name=tresata-dis-postgres" --format "{{.Names}}" 2> $null
    
    if (-not $containerExists) {
        Write-Host "PostgreSQL container not found. Creating container..." -ForegroundColor Yellow
        
        # Check if docker-compose file exists
        $dockerComposePath = Join-Path -Path $scriptRoot -ChildPath "docker-compose.yml"
        if (Test-Path -Path $dockerComposePath) {
            Write-Host "Starting PostgreSQL using docker-compose..." -ForegroundColor Cyan
            docker-compose -f $dockerComposePath up -d postgres
            
            # Wait for container to initialize
            Write-Host "Waiting for PostgreSQL container to initialize..." -ForegroundColor Yellow
            Start-Sleep -Seconds 10
        } else {
            Write-Host "Docker compose file not found. Creating PostgreSQL container directly..." -ForegroundColor Yellow
            docker run -d --name tresata-dis-postgres -e POSTGRES_DB=tresata_dis -e POSTGRES_USER=postgres -e POSTGRES_PASSWORD=postgres -p 5432:5432 postgres:latest
            Start-Sleep -Seconds 10
        }
    } elseif (-not (docker ps --filter "name=tresata-dis-postgres" --format "{{.Names}}" 2> $null)) {
        Write-Host "PostgreSQL container exists but is not running. Starting container..." -ForegroundColor Yellow
        docker start tresata-dis-postgres
        Start-Sleep -Seconds 5
    } else {
        Write-Host "PostgreSQL container is already running." -ForegroundColor Green
    }
    
    # Create the required tables
    Write-Host "Creating required database tables..." -ForegroundColor Cyan
    
    # Function to execute SQL in PostgreSQL container
    function Invoke-PostgresQuery {
        param([string]$Query)
        
        try {
            docker exec -i tresata-dis-postgres psql -d tresata_dis -U postgres -c "$Query" 2> $null
            return $true
        } catch {
            Write-Host "Error executing query: $_" -ForegroundColor Red
            return $false
        }
    }
    
    # Create required tables if they don't exist
    $createUsersTable = @"
CREATE TABLE IF NOT EXISTS users (
    id INTEGER,
    name VARCHAR(100),
    email VARCHAR(150),
    age INTEGER,
    city VARCHAR(100)
);
"@

    $createProductsTable = @"
CREATE TABLE IF NOT EXISTS products (
    product_id INTEGER,
    product_name VARCHAR(255),
    category VARCHAR(100),
    price NUMERIC(10,2),
    stock_quantity INTEGER,
    last_updated DATE
);
"@

    $createJsonDataTable = @"
CREATE TABLE IF NOT EXISTS json_data (
    id INTEGER,
    name VARCHAR(100),
    email VARCHAR(150),
    is_active BOOLEAN,
    created_at TIMESTAMP
);
"@

    # Execute the create table statements
    Invoke-PostgresQuery -Query $createUsersTable
    Invoke-PostgresQuery -Query $createProductsTable
    Invoke-PostgresQuery -Query $createJsonDataTable
    
    Write-Host "Database initialization complete." -ForegroundColor Green
}
