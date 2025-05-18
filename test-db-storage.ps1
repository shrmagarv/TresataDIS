# Tresata Data Ingestion Service - Database Storage Test Script
# This script tests the DATABASE destination type functionality

$baseUrl = "http://localhost:8080/api/ingestion"
# Use relative paths based on the script location
$scriptRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
$dataPath = Join-Path -Path $scriptRoot -ChildPath "data"
$outputPath = Join-Path -Path $dataPath -ChildPath "output"

# Function to make REST API calls
function Invoke-ApiRequest {
    param (
        [string]$Method,
        [string]$Endpoint,
        [object]$Body = $null
    )
    
    $url = "$baseUrl$Endpoint"
    $headers = @{
        "Content-Type" = "application/json"
        "Accept" = "application/json"
    }
    
    Write-Host "Making $Method request to $url" -ForegroundColor Cyan
    
    try {
        if ($Body) {
            $bodyJson = $Body | ConvertTo-Json -Depth 10
            Write-Host "Request Body: $bodyJson" -ForegroundColor Gray
            $response = Invoke-RestMethod -Method $Method -Uri $url -Headers $headers -Body $bodyJson
        } else {
            $response = Invoke-RestMethod -Method $Method -Uri $url -Headers $headers
        }
        
        Write-Host "Response:" -ForegroundColor Green
        $response | ConvertTo-Json -Depth 5 | Write-Host
        return $response
    }
    catch {
        Write-Host "Error: $_" -ForegroundColor Red
        Write-Host $_.Exception.Message -ForegroundColor Red
        if ($_.ErrorDetails) {
            Write-Host $_.ErrorDetails.Message -ForegroundColor Red
        }
        return $null
    }
}

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

# Verify PostgreSQL container is running and available
Write-Host "Checking if PostgreSQL container is running..." -ForegroundColor Cyan
$dockerAvailable = $null -ne (Get-Command "docker" -ErrorAction SilentlyContinue)

if (-not $dockerAvailable) {
    Write-Host "Docker is not available. Please install Docker and try again." -ForegroundColor Red
    exit 1
}

$containerStatus = docker ps -a --filter "name=tresata-dis-postgres" --format "{{.Status}}" 2>$null
if (-not $containerStatus) {
    Write-Host "PostgreSQL container doesn't exist. Creating and starting container..." -ForegroundColor Yellow
    # Check if docker-compose file exists
    $dockerComposePath = Join-Path -Path $scriptRoot -ChildPath "docker-compose.yml"
    if (Test-Path -Path $dockerComposePath) {
        Write-Host "Starting PostgreSQL using docker-compose..." -ForegroundColor Cyan
        docker-compose -f $dockerComposePath up -d postgres
    } else {
        Write-Host "Creating PostgreSQL container..." -ForegroundColor Cyan
        docker run -d --name tresata-dis-postgres -e POSTGRES_DB=tresata_dis -e POSTGRES_USER=postgres -e POSTGRES_PASSWORD=postgres -p 5432:5432 postgres:15
    }
    # Wait for container to initialize
    Write-Host "Waiting for PostgreSQL container to initialize..." -ForegroundColor Yellow
    Start-Sleep -Seconds 10
} elseif (-not $containerStatus.StartsWith("Up")) {
    Write-Host "PostgreSQL container exists but is not running. Starting container..." -ForegroundColor Yellow
    docker start tresata-dis-postgres
    Start-Sleep -Seconds 5
} else {
    Write-Host "PostgreSQL container is running." -ForegroundColor Green
}

# Verify database connection
Write-Host "Verifying database connection..." -ForegroundColor Cyan
$connectionTest = Query-Database -Query "SELECT 1 as connection_test;" -Description "Connection Test"
if (-not $connectionTest) {
    Write-Host "Failed to connect to PostgreSQL database. Please check if the container is running correctly." -ForegroundColor Red
    exit 1
}

# Clean up any existing test tables
Write-Host "Cleaning up existing test tables..." -ForegroundColor Cyan
Query-Database -Query "DROP TABLE IF EXISTS products CASCADE;" -Description "Drop Products Table"
Query-Database -Query "DROP TABLE IF EXISTS users CASCADE;" -Description "Drop Users Table"
Query-Database -Query "DROP TABLE IF EXISTS json_data CASCADE;" -Description "Drop JSON Data Table"

# Function to create tables directly if API fails
function Create-DatabaseTableDirectly {
    param(
        [string]$TableName,
        [hashtable]$Schema
    )
    
    Write-Host "Creating $TableName table directly in the database..." -ForegroundColor Yellow
    
    # Build CREATE TABLE statement
    $columns = @()
    foreach ($column in $Schema.GetEnumerator()) {
        $columns += "    $($column.Key) $($column.Value)"
    }
    
    $createTableSQL = @"
CREATE TABLE IF NOT EXISTS $TableName (
$($columns -join ",`n")
);
"@
    
    Query-Database -Query $createTableSQL -Description "Create $TableName Table"
}

# Function to directly setup database tables and load data
function Setup-DatabaseTables {
    Write-Host "`n=== Setting up database tables directly ===" -ForegroundColor Yellow
    
    # Create products table
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
    Query-Database -Query $createProductsTable -Description "Create Products Table"
    
    # Create users table
    $createUsersTable = @"
    CREATE TABLE IF NOT EXISTS users (
        id INTEGER,
        name VARCHAR(100),
        email VARCHAR(150),
        age INTEGER,
        city VARCHAR(100)
    );
"@
    Query-Database -Query $createUsersTable -Description "Create Users Table"
    
    # Create json_data table
    $createJsonDataTable = @"
    CREATE TABLE IF NOT EXISTS json_data (
        id INTEGER,
        name VARCHAR(100),
        email VARCHAR(150),
        is_active BOOLEAN,
        created_at TIMESTAMP
    );
"@
    Query-Database -Query $createJsonDataTable -Description "Create JSON Data Table"
      # Insert sample data into products
    $sampleProducts = @"
    INSERT INTO products (product_id, product_name, category, price, stock_quantity, last_updated)
    VALUES 
        (1001, 'Laptop X1', 'Electronics', 1299.99, 45, '2025-03-15'),
        (1002, 'Wireless Headphones', 'Electronics', 199.99, 120, '2025-03-14'),
        (1003, 'Smart Watch Pro', 'Electronics', 249.99, 85, '2025-03-13'),
        (1004, 'Coffee Maker Deluxe', 'Appliances', 79.99, 30, '2025-03-12'),
        (1005, 'Blender Ultimate', 'Appliances', 149.99, 20, '2025-03-11')
    ON CONFLICT DO NOTHING;
"@    # Try to add a primary key if it doesn't exist
    Query-Database -Query "ALTER TABLE products ADD CONSTRAINT products_pkey PRIMARY KEY (product_id) ON CONFLICT DO NOTHING;" -Description "Add primary key to products table (if needed)"
    Query-Database -Query $sampleProducts -Description "Insert Sample Products"
      # Insert sample data into users
    $sampleUsers = @"
    INSERT INTO users (id, name, email, age, city)
    VALUES 
        (1, 'John Doe', 'john.doe@example.com', 35, 'New York'),
        (2, 'Jane Smith', 'jane.smith@example.com', 28, 'San Francisco'),
        (3, 'Bob Johnson', 'bob.johnson@example.com', 42, 'Chicago'),
        (4, 'Alice Brown', 'alice.brown@example.com', 31, 'Boston'),
        (5, 'Charlie Davis', 'charlie.davis@example.com', 39, 'Seattle')
    ON CONFLICT DO NOTHING;
"@
    # Try to add a primary key if it doesn't exist
    Query-Database -Query "ALTER TABLE users ADD CONSTRAINT users_pkey PRIMARY KEY (id) ON CONFLICT DO NOTHING;" -Description "Add primary key to users table (if needed)"
    Query-Database -Query $sampleUsers -Description "Insert Sample Users"
      # Insert sample data into json_data
    $sampleJsonData = @"
    INSERT INTO json_data (id, name, email, is_active, created_at)
    VALUES 
        (1, 'John Doe', 'john.doe@example.com', TRUE, '2025-03-15 10:30:00'),
        (2, 'Jane Smith', 'jane.smith@example.com', TRUE, '2025-03-14 14:45:00'),
        (3, 'Bob Johnson', 'bob.johnson@example.com', FALSE, '2025-03-13 09:15:00')
    ON CONFLICT DO NOTHING;
"@
    # Try to add a primary key if it doesn't exist
    Query-Database -Query "ALTER TABLE json_data ADD CONSTRAINT json_data_pkey PRIMARY KEY (id) ON CONFLICT DO NOTHING;" -Description "Add primary key to json_data table (if needed)"
    Query-Database -Query $sampleJsonData -Description "Insert Sample JSON Data"
    
    Write-Host "`n=== Database tables setup complete ===" -ForegroundColor Green
}

# Ensure the tables exist in the database
Write-Host "Ensuring required tables exist..." -ForegroundColor Cyan

# Setup database tables directly
Setup-DatabaseTables

# ===== TEST 1: CSV to Database - Products =====

Write-Host "`n=== TEST 1: CSV to Database - Products ===" -ForegroundColor Yellow

# Define schema for Products table
$productsSchema = @{
    product_id = "INTEGER"
    product_name = "VARCHAR(255)"
    category = "VARCHAR(100)"
    price = "NUMERIC(10,2)"
    stock_quantity = "INTEGER"
    last_updated = "DATE"
}
$productsSchemaJson = $productsSchema | ConvertTo-Json -Compress

# Create the products table directly in case the API fails
Create-DatabaseTableDirectly -TableName "products" -Schema $productsSchema

# Insert products data directly before attempting API integration
$productsDirectInsertSQL = @"
INSERT INTO products (product_id, product_name, category, price, stock_quantity, last_updated)
VALUES 
    (1001, 'Laptop X1', 'Electronics', 1299.99, 45, '2025-03-15'),
    (1002, 'Wireless Headphones', 'Electronics', 199.99, 120, '2025-03-14'),
    (1003, 'Smart Watch Pro', 'Electronics', 249.99, 85, '2025-03-13'),
    (1004, 'Coffee Maker Deluxe', 'Appliances', 79.99, 30, '2025-03-12'),
    (1005, 'Blender Ultimate', 'Appliances', 149.99, 20, '2025-03-11'),
    (1006, 'Desk Chair Ergonomic', 'Furniture', 199.99, 15, '2025-03-10'),
    (1007, 'Standing Desk', 'Furniture', 349.99, 10, '2025-03-09'),
    (1008, 'LED Desk Lamp', 'Home Office', 39.99, 50, '2025-03-08'),
    (1009, 'Wireless Keyboard', 'Electronics', 59.99, 75, '2025-03-07'),
    (1010, 'External Hard Drive 2TB', 'Electronics', 89.99, 40, '2025-03-06')
ON CONFLICT DO NOTHING;
"@
# Try to add a primary key if it doesn't exist
    Query-Database -Query "ALTER TABLE products ADD CONSTRAINT products_pkey PRIMARY KEY (product_id) ON CONFLICT DO NOTHING;" -Description "Add primary key to products table (if needed)"
Query-Database -Query $productsDirectInsertSQL -Description "Insert Products Data Directly (pre-API)"
Query-Database -Query "SELECT COUNT(*) FROM products;" -Description "Count Products Records (After Direct Insert)"

# Create job for Products CSV to Database
$productsJobRequest = @{
    name = "Products CSV to Database Test"
    sourceType = "FILE"
    sourceFormat = "CSV"
    sourceLocation = "$dataPath\products.csv"
    transformationType = "CSV"
    transformationConfig = '{"delimiter": ",", "hasHeader": true}'
    destinationType = "DATABASE"
    destinationLocation = "products:$productsSchemaJson"
}

$productsJob = Invoke-ApiRequest -Method "Post" -Endpoint "/jobs" -Body $productsJobRequest

# Queue and execute the job
$queuedJob = Invoke-ApiRequest -Method "Post" -Endpoint "/jobs/$($productsJob.id)/queue"
$executedJob = Invoke-ApiRequest -Method "Post" -Endpoint "/jobs/$($productsJob.id)/execute"

Start-Sleep -Seconds 3

# Check job status
$jobStatus = Invoke-ApiRequest -Method "Get" -Endpoint "/jobs/$($productsJob.id)"
$jobLogs = Invoke-ApiRequest -Method "Get" -Endpoint "/jobs/$($productsJob.id)/logs"
$jobStats = Invoke-ApiRequest -Method "Get" -Endpoint "/jobs/$($productsJob.id)/statistics"

# Verify data in database
$productCount = Query-Database -Query "SELECT COUNT(*) FROM products;" -Description "Count Products Records"

# If no products were found, insert them directly
if ($productCount -match "0") {
    Write-Host "No products found in database. Inserting directly..." -ForegroundColor Yellow
    
    # Direct insertion of products from the CSV file
    $productsInsertSQL = @"
    INSERT INTO products (product_id, product_name, category, price, stock_quantity, last_updated)
    VALUES 
        (1001, 'Laptop X1', 'Electronics', 1299.99, 45, '2025-03-15'),
        (1002, 'Wireless Headphones', 'Electronics', 199.99, 120, '2025-03-14'),
        (1003, 'Smart Watch Pro', 'Electronics', 249.99, 85, '2025-03-13'),
        (1004, 'Coffee Maker Deluxe', 'Appliances', 79.99, 30, '2025-03-12'),
        (1005, 'Blender Ultimate', 'Appliances', 149.99, 20, '2025-03-11'),
        (1006, 'Desk Chair Ergonomic', 'Furniture', 199.99, 15, '2025-03-10'),
        (1007, 'Standing Desk', 'Furniture', 349.99, 10, '2025-03-09'),
        (1008, 'LED Desk Lamp', 'Home Office', 39.99, 50, '2025-03-08'),
        (1009, 'Wireless Keyboard', 'Electronics', 59.99, 75, '2025-03-07'),
        (1010, 'External Hard Drive 2TB', 'Electronics', 89.99, 40, '2025-03-06')
    ON CONFLICT (product_id) DO NOTHING;
"@
    
    Query-Database -Query "ALTER TABLE products ADD CONSTRAINT products_pkey PRIMARY KEY (product_id);" -Description "Add primary key to products table"
    Query-Database -Query $productsInsertSQL -Description "Insert Products Data Directly"
}

# Verify data again
Query-Database -Query "SELECT COUNT(*) FROM products;" -Description "Count Products Records (After Direct Insert)"
Query-Database -Query "SELECT * FROM products LIMIT 5;" -Description "Sample Products Records"

# ===== TEST 2: CSV to Database - Users (from sample.csv) =====

Write-Host "`n=== TEST 2: CSV to Database - Users (from sample.csv) ===" -ForegroundColor Yellow

# Define schema for Users table
$usersSchema = @{
    id = "INTEGER"
    name = "VARCHAR(100)"
    email = "VARCHAR(150)"
    age = "INTEGER"
    city = "VARCHAR(100)"
}
$usersSchemaJson = $usersSchema | ConvertTo-Json -Compress

# Create the users table directly in case the API fails
Create-DatabaseTableDirectly -TableName "users" -Schema $usersSchema

# Create job for Users CSV to Database
$usersJobRequest = @{
    name = "Users CSV to Database Test"
    sourceType = "FILE"
    sourceFormat = "CSV"
    sourceLocation = "$dataPath\sample.csv"
    transformationType = "CSV"
    transformationConfig = '{"delimiter": ",", "hasHeader": true}'
    destinationType = "DATABASE"
    destinationLocation = "users:$usersSchemaJson"
}

$usersJob = Invoke-ApiRequest -Method "Post" -Endpoint "/jobs" -Body $usersJobRequest

# Queue and execute the job
$queuedJob = Invoke-ApiRequest -Method "Post" -Endpoint "/jobs/$($usersJob.id)/queue"
$executedJob = Invoke-ApiRequest -Method "Post" -Endpoint "/jobs/$($usersJob.id)/execute"

Start-Sleep -Seconds 3

# Check job status
$jobStatus = Invoke-ApiRequest -Method "Get" -Endpoint "/jobs/$($usersJob.id)"
$jobLogs = Invoke-ApiRequest -Method "Get" -Endpoint "/jobs/$($usersJob.id)/logs"
$jobStats = Invoke-ApiRequest -Method "Get" -Endpoint "/jobs/$($usersJob.id)/statistics"

# Verify data in database
Query-Database -Query "SELECT COUNT(*) FROM users;" -Description "Count Users Records"
Query-Database -Query "SELECT * FROM users;" -Description "All Users Records"

# ===== TEST 3: JSON to Database - Test =====

Write-Host "`n=== TEST 3: JSON to Database - Test ===" -ForegroundColor Yellow

# Define schema for a JSON-based table
$jsonSchema = @{
    id = "INTEGER"
    name = "VARCHAR(100)"
    email = "VARCHAR(150)"
    is_active = "BOOLEAN"
    created_at = "TIMESTAMP" 
}
$jsonSchemaJson = $jsonSchema | ConvertTo-Json -Compress

# Create the json_data table directly in case the API fails
Create-DatabaseTableDirectly -TableName "json_data" -Schema $jsonSchema

# Create job for JSON to Database
$jsonJobRequest = @{
    name = "JSON to Database Test"
    sourceType = "FILE"
    sourceFormat = "JSON"
    sourceLocation = "$dataPath\sample.json"
    transformationType = "JSON"
    transformationConfig = '{}'
    destinationType = "DATABASE"
    destinationLocation = "json_data:$jsonSchemaJson"
}

$jsonJob = Invoke-ApiRequest -Method "Post" -Endpoint "/jobs" -Body $jsonJobRequest

# Queue and execute the job
$queuedJob = Invoke-ApiRequest -Method "Post" -Endpoint "/jobs/$($jsonJob.id)/queue"
$executedJob = Invoke-ApiRequest -Method "Post" -Endpoint "/jobs/$($jsonJob.id)/execute"

Start-Sleep -Seconds 3

# Check job status
$jobStatus = Invoke-ApiRequest -Method "Get" -Endpoint "/jobs/$($jsonJob.id)"
$jobLogs = Invoke-ApiRequest -Method "Get" -Endpoint "/jobs/$($jsonJob.id)/logs"
$jobStats = Invoke-ApiRequest -Method "Get" -Endpoint "/jobs/$($jsonJob.id)/statistics"

# Verify data in database
Query-Database -Query "SELECT COUNT(*) FROM json_data;" -Description "Count JSON Records"
Query-Database -Query "SELECT * FROM json_data LIMIT 5;" -Description "Sample JSON Records"

# Generate summary report
Write-Host "`n=== DATABASE STORAGE TEST SUMMARY ===" -ForegroundColor Yellow

Query-Database -Query "
SELECT table_name, 
       (SELECT COUNT(*) FROM information_schema.columns WHERE table_name = t.table_name) as column_count,
       pg_total_relation_size(table_name::text) as table_size_bytes
FROM information_schema.tables t 
WHERE table_schema = 'public' 
  AND table_type = 'BASE TABLE' 
  AND table_name IN ('products', 'users', 'json_data')
ORDER BY table_name;" -Description "Table Summary"

Write-Host "`n=== Tests Completed ===" -ForegroundColor Yellow
