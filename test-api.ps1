# Tresata Data Ingestion Service - API Test Script

$baseUrl = "http://localhost:8080/api/ingestion"
# Use relative paths based on the script location
$scriptRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
$dataPath = Join-Path -Path $scriptRoot -ChildPath "data"
$outputPath = Join-Path -Path $dataPath -ChildPath "output"

# Create output directory if it doesn't exist
if (!(Test-Path -Path "$dataPath\output")) {
    New-Item -ItemType Directory -Path "$dataPath\output" -Force | Out-Null
    Write-Host "Created output directory: $dataPath\output" -ForegroundColor Gray
}

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

# ===== CSV PROCESSING TESTS =====

# Test 1: Create a new job for CSV file processing (Sample CSV)
Write-Host "=== TEST 1: Create a CSV File Processing Job (Sample) ===" -ForegroundColor Yellow
$csvJobRequest = @{
    name = "Sample CSV Processing"
    sourceType = "FILE"
    sourceFormat = "CSV"
    sourceLocation = "$dataPath\sample.csv"
    transformationType = "CSV"
    transformationConfig = '{"delimiter": ",", "hasHeader": true, "fieldMappings": {"name": "full_name", "email": "contact_email"}}'
    destinationType = "LOCAL"
    destinationLocation = "$dataPath\output\sample_processed.csv"
}

$csvJob = Invoke-ApiRequest -Method "Post" -Endpoint "/jobs" -Body $csvJobRequest

# Test 2: Create a job for Products CSV processing
Write-Host "`n=== TEST 2: Create a CSV File Processing Job (Products) ===" -ForegroundColor Yellow
$productsJobRequest = @{
    name = "Products CSV Processing"
    sourceType = "FILE"
    sourceFormat = "CSV"
    sourceLocation = "$dataPath\products.csv"
    transformationType = "CSV"
    transformationConfig = '{"delimiter": ",", "hasHeader": true, "fieldsToRemove": ["last_updated"]}'
    destinationType = "LOCAL"
    destinationLocation = "$dataPath\output\products_processed.csv"
}

$productsJob = Invoke-ApiRequest -Method "Post" -Endpoint "/jobs" -Body $productsJobRequest

# Test 2.1: Create a job for Products CSV to PostgreSQL Database
Write-Host "`n=== TEST 2.1: Create a CSV to Database Processing Job ===" -ForegroundColor Yellow
$dbSchemaConfig = @{
    product_id = "INTEGER"
    product_name = "VARCHAR"
    category = "VARCHAR"
    price = "DOUBLE"
    stock_quantity = "INTEGER"
    last_updated = "DATE"  # Added this column which is present in the CSV
}

# Properly escape the JSON schema to ensure it works with the destination format
$dbSchema = $dbSchemaConfig | ConvertTo-Json -Compress
# The schema needs to be properly escaped as it's inserted into the destinationLocation string
# Replace any double quotes with escaped quotes (\")
$dbSchemaEscaped = $dbSchema.Replace('"', '\"')

$productsDbJobRequest = @{
    name = "Products CSV to Database Processing"
    sourceType = "FILE"
    sourceFormat = "CSV"
    sourceLocation = "$dataPath\products.csv"
    transformationType = "CSV"
    transformationConfig = '{"delimiter": ",", "hasHeader": true}'
    destinationType = "DATABASE"
    destinationLocation = "products:$dbSchemaEscaped"
}

$productsDbJob = Invoke-ApiRequest -Method "Post" -Endpoint "/jobs" -Body $productsDbJobRequest

# ===== JSON PROCESSING TESTS =====

# Test 3: Create a job for JSON file processing
Write-Host "`n=== TEST 3: Create a JSON File Processing Job ===" -ForegroundColor Yellow
$jsonJobRequest = @{
    name = "Sample JSON Processing"
    sourceType = "FILE"
    sourceFormat = "JSON"
    sourceLocation = "$dataPath\sample.json"
    transformationType = "JSON"
    transformationConfig = '{"fieldMappings": {"name": "full_name", "email": "contact_email"}, "addFields": {"source": "sample_data"}}'
    destinationType = "LOCAL"
    destinationLocation = "$dataPath\output\sample_processed.json"
}

$jsonJob = Invoke-ApiRequest -Method "Post" -Endpoint "/jobs" -Body $jsonJobRequest

# Test 3.1: Create a job for JSON to Database processing - Users table
Write-Host "`n=== TEST 3.1: Create a JSON to Database Processing Job ===" -ForegroundColor Yellow
$jsonDbSchemaConfig = @{
    id = "INTEGER"
    name = "VARCHAR(100)"
    email = "VARCHAR(150)"
    age = "INTEGER"
    city = "VARCHAR(100)"
}

# Properly escape the JSON schema for database insertion
$jsonDbSchema = $jsonDbSchemaConfig | ConvertTo-Json -Compress
# Replace any double quotes with escaped quotes for proper JSON schema formatting
$jsonDbSchemaEscaped = $jsonDbSchema.Replace('"', '\"')

$jsonToDbJobRequest = @{
    name = "JSON to Database - Users Table"
    sourceType = "FILE"
    sourceFormat = "JSON"
    sourceLocation = "$dataPath\sample.json"
    transformationType = "JSON"
    transformationConfig = '{}'  # Empty transformation to preserve the original data
    destinationType = "DATABASE"
    destinationLocation = "users:$jsonDbSchemaEscaped"  # Insert into users table instead of json_test
}

$jsonToDbJob = Invoke-ApiRequest -Method "Post" -Endpoint "/jobs" -Body $jsonToDbJobRequest

# ===== XML PROCESSING TESTS =====

# Test 4: Create a job for XML file processing
Write-Host "`n=== TEST 4: Create an XML File Processing Job ===" -ForegroundColor Yellow
$xmlJobRequest = @{
    name = "Orders XML Processing"
    sourceType = "FILE"
    sourceFormat = "XML"
    sourceLocation = "$dataPath\orders.xml"
    transformationType = "XML"
    transformationConfig = '{"elementMappings": {"/orders/order/items/item/product_id": "product_code"}, "elementsToRemove": ["/orders/order/payment_method"]}'
    destinationType = "LOCAL"
    destinationLocation = "$dataPath\output\orders_processed.xml"
}

$xmlJob = Invoke-ApiRequest -Method "Post" -Endpoint "/jobs" -Body $xmlJobRequest

# ===== JOB MANAGEMENT TESTS =====

# Test 5: Get all jobs
Write-Host "`n=== TEST 5: Get All Jobs ===" -ForegroundColor Yellow
$allJobs = Invoke-ApiRequest -Method "Get" -Endpoint "/jobs"

# Test 6: Queue all jobs for processing
Write-Host "`n=== TEST 6: Queue All Jobs for Processing ===" -ForegroundColor Yellow
$queuedCsvJob = Invoke-ApiRequest -Method "Post" -Endpoint "/jobs/$($csvJob.id)/queue"
$queuedProductsJob = Invoke-ApiRequest -Method "Post" -Endpoint "/jobs/$($productsJob.id)/queue"
$queuedProductsDbJob = Invoke-ApiRequest -Method "Post" -Endpoint "/jobs/$($productsDbJob.id)/queue"
$queuedJsonJob = Invoke-ApiRequest -Method "Post" -Endpoint "/jobs/$($jsonJob.id)/queue"
$queuedJsonToDbJob = Invoke-ApiRequest -Method "Post" -Endpoint "/jobs/$($jsonToDbJob.id)/queue"
$queuedXmlJob = Invoke-ApiRequest -Method "Post" -Endpoint "/jobs/$($xmlJob.id)/queue"

# Test 7: Execute all jobs in sequence
Write-Host "`n=== TEST 7: Execute All Jobs ===" -ForegroundColor Yellow
Write-Host "Executing CSV job..." -ForegroundColor Gray
$executedCsvJob = Invoke-ApiRequest -Method "Post" -Endpoint "/jobs/$($csvJob.id)/execute"
Start-Sleep -Seconds 2

Write-Host "Executing Products job..." -ForegroundColor Gray
$executedProductsJob = Invoke-ApiRequest -Method "Post" -Endpoint "/jobs/$($productsJob.id)/execute"
Start-Sleep -Seconds 2

Write-Host "Executing Products DB job..." -ForegroundColor Gray
$executedProductsDbJob = Invoke-ApiRequest -Method "Post" -Endpoint "/jobs/$($productsDbJob.id)/execute"
Start-Sleep -Seconds 2

Write-Host "Executing JSON job..." -ForegroundColor Gray
$executedJsonJob = Invoke-ApiRequest -Method "Post" -Endpoint "/jobs/$($jsonJob.id)/execute"
Start-Sleep -Seconds 2

Write-Host "Executing JSON to DB job..." -ForegroundColor Gray
$executedJsonToDbJob = Invoke-ApiRequest -Method "Post" -Endpoint "/jobs/$($jsonToDbJob.id)/execute"
Start-Sleep -Seconds 2

Write-Host "Executing XML job..." -ForegroundColor Gray
$executedXmlJob = Invoke-ApiRequest -Method "Post" -Endpoint "/jobs/$($xmlJob.id)/execute"
Start-Sleep -Seconds 5

# Test 8: Get job status for all jobs
Write-Host "`n=== TEST 8: Get Job Status for All Jobs ===" -ForegroundColor Yellow
$csvJobStatus = Invoke-ApiRequest -Method "Get" -Endpoint "/jobs/$($csvJob.id)"
$productsJobStatus = Invoke-ApiRequest -Method "Get" -Endpoint "/jobs/$($productsJob.id)"
$productsDbJobStatus = Invoke-ApiRequest -Method "Get" -Endpoint "/jobs/$($productsDbJob.id)"
$jsonJobStatus = Invoke-ApiRequest -Method "Get" -Endpoint "/jobs/$($jsonJob.id)"
$jsonToDbJobStatus = Invoke-ApiRequest -Method "Get" -Endpoint "/jobs/$($jsonToDbJob.id)"
$xmlJobStatus = Invoke-ApiRequest -Method "Get" -Endpoint "/jobs/$($xmlJob.id)"

# Test 9: Get job logs and statistics
Write-Host "`n=== TEST 9: Get Job Logs and Statistics ===" -ForegroundColor Yellow
Write-Host "CSV Job Logs:" -ForegroundColor Gray
$csvJobLogs = Invoke-ApiRequest -Method "Get" -Endpoint "/jobs/$($csvJob.id)/logs"
Write-Host "CSV Job Statistics:" -ForegroundColor Gray
$csvJobStats = Invoke-ApiRequest -Method "Get" -Endpoint "/jobs/$($csvJob.id)/statistics"

Write-Host "Products DB Job Logs:" -ForegroundColor Gray
$productsDbJobLogs = Invoke-ApiRequest -Method "Get" -Endpoint "/jobs/$($productsDbJob.id)/logs"
Write-Host "Products DB Job Statistics:" -ForegroundColor Gray
$productsDbJobStats = Invoke-ApiRequest -Method "Get" -Endpoint "/jobs/$($productsDbJob.id)/statistics"

Write-Host "JSON to DB Job Logs:" -ForegroundColor Gray
$jsonToDbJobLogs = Invoke-ApiRequest -Method "Get" -Endpoint "/jobs/$($jsonToDbJob.id)/logs"
Write-Host "JSON to DB Job Statistics:" -ForegroundColor Gray
$jsonToDbJobStats = Invoke-ApiRequest -Method "Get" -Endpoint "/jobs/$($jsonToDbJob.id)/statistics"

# Test 10: View processed data files
Write-Host "`n=== TEST 10: View Processed Data Files ===" -ForegroundColor Yellow
Write-Host "Displaying processed files in output directory:" -ForegroundColor Gray
Get-ChildItem -Path "$dataPath\output" | ForEach-Object {
    Write-Host $_.Name -ForegroundColor Cyan
}

# Test 11: Verify Database Import
Write-Host "`n=== TEST 11: Verify Database Import ===" -ForegroundColor Yellow
Write-Host "Running query to verify products were imported to database:" -ForegroundColor Gray
docker exec -i tresata-dis-postgres psql -d tresata_dis -U postgres -c "SELECT COUNT(*) FROM products;"
docker exec -i tresata-dis-postgres psql -d tresata_dis -U postgres -c "SELECT * FROM products LIMIT 5;"

Write-Host "`nRunning query to verify JSON data was imported to users table:" -ForegroundColor Gray
docker exec -i tresata-dis-postgres psql -d tresata_dis -U postgres -c "SELECT COUNT(*) FROM users;"
docker exec -i tresata-dis-postgres psql -d tresata_dis -U postgres -c "SELECT * FROM users LIMIT 5;"

Write-Host "`n=== Tests Completed ===" -ForegroundColor Yellow
Write-Host "Check the output directory for processed files: $dataPath\output" -ForegroundColor Green
Write-Host "Check the database for products and users tables data" -ForegroundColor Green



