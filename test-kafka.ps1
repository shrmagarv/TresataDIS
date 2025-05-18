# Tresata Data Ingestion Service - Kafka Test Script

# Function to send messages to Kafka
function Send-ToKafka {
    param (
        [string]$Topic,
        [string]$Key,
        [string]$Message
    )
    
    Write-Host "Sending message to Kafka topic: $Topic" -ForegroundColor Cyan
    Write-Host "Key: $Key" -ForegroundColor Gray
    Write-Host "Message length: $($Message.Length) characters" -ForegroundColor Gray
    
    # Invoke a REST API that publishes to Kafka
    $url = "http://localhost:8080/api/kafka/publish"
    $headers = @{
        "Content-Type" = "application/json"
        "Accept" = "application/json"
    }
    
    $body = @{
        topic = $Topic
        key = $Key
        message = $Message
    }
    
    try {
        $bodyJson = $body | ConvertTo-Json -Depth 10 -Compress
        $response = Invoke-RestMethod -Method "Post" -Uri $url  -Headers $headers -Body $bodyJson
        Write-Host "Message sent successfully" -ForegroundColor Green
        return $response
    }
    catch {
        Write-Host "Error sending message: $_" -ForegroundColor Red
        Write-Host $_.Exception.Message -ForegroundColor Red
        if ($_.ErrorDetails) {
            Write-Host $_.ErrorDetails.Message -ForegroundColor Red
        }
    }
}

# Path to data file
# Use relative paths based on the script location
$scriptRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
$dataPath = Join-Path -Path $scriptRoot -ChildPath "data"
$outputPath = Join-Path -Path $dataPath -ChildPath "output"

# Make sure output directory exists
if (!(Test-Path -Path $outputPath)) {
    New-Item -ItemType Directory -Path $outputPath -Force | Out-Null
    Write-Host "Created output directory: $outputPath" -ForegroundColor Gray
}

# ===== SIMPLE MESSAGES TESTS =====

# Test 1: Send a simple message to Kafka
Write-Host "=== TEST 1: Send Simple Message to Kafka ===" -ForegroundColor Yellow
$response = Send-ToKafka -Topic "data-ingestion" -Key "test1" -Message "This is a test message"
$response | ConvertTo-Json | Write-Host

# ===== JSON DATA TESTS =====

# Test 2: Send a JSON record to Kafka
Write-Host "`n=== TEST 2: Send JSON Record to Kafka ===" -ForegroundColor Yellow
$jsonContent = Get-Content -Path "$dataPath\sample.json" -Raw
$response = Send-ToKafka -Topic "data-ingestion-json" -Key "json-data" -Message $jsonContent
$response | ConvertTo-Json | Write-Host

# ===== CSV DATA TESTS =====

# Test 3: Send CSV records as individual messages
Write-Host "`n=== TEST 3: Send CSV Records as Individual Messages ===" -ForegroundColor Yellow
$csvContent = Get-Content -Path "$dataPath\sample.csv" -Raw
$csvLines = $csvContent -split "`n" 
$header = $csvLines[0]

Write-Host "CSV Header: $header" -ForegroundColor Gray
Write-Host "Sending individual CSV records..." -ForegroundColor Gray

$i = 0
foreach ($line in $csvLines | Select-Object -Skip 1) {
    if ($line.Trim() -ne "") {
        $response = Send-ToKafka -Topic "data-ingestion-csv" -Key "csv-line-$i" -Message $line
        $i++
        Start-Sleep -Milliseconds 500  # Small delay between messages
    }
}

Write-Host "Sent $i CSV records" -ForegroundColor Green

# ===== XML DATA TESTS =====

# Test 4: Send XML data to Kafka
Write-Host "`n=== TEST 4: Send XML Data to Kafka ===" -ForegroundColor Yellow
$xmlContent = Get-Content -Path "$dataPath\orders.xml" -Raw
$response = Send-ToKafka -Topic "data-ingestion-xml" -Key "xml-data" -Message $xmlContent
$response | ConvertTo-Json | Write-Host

# ===== BATCH DATA TESTS =====

# Test 5: Create a batch file with multiple records and send it
Write-Host "`n=== TEST 5: Create and Send Batch Data ===" -ForegroundColor Yellow

# Create a batch data file
$batchFilePath = "$outputPath\batch_data.csv"
$productsContent = Get-Content -Path "$dataPath\products.csv" -Raw
$sampleContent = Get-Content -Path "$dataPath\sample.csv" -Raw

$batchContent = @"
# Batch data file for testing
# Contains products and people data

## PRODUCTS DATA
$productsContent

## PEOPLE DATA
$sampleContent
"@

# Write batch file
$batchContent | Out-File -FilePath $batchFilePath -Encoding utf8
Write-Host "Created batch file: $batchFilePath" -ForegroundColor Gray

# Send the batch file content
$response = Send-ToKafka -Topic "data-ingestion-batch" -Key "batch-data" -Message $batchContent
$response | ConvertTo-Json | Write-Host

# Display Kafka topics on the UI
Write-Host "`n=== Kafka Topics Created ===" -ForegroundColor Yellow
Write-Host "The following Kafka topics have been used:" -ForegroundColor Gray
Write-Host "  - data-ingestion" -ForegroundColor Cyan
Write-Host "  - data-ingestion-json" -ForegroundColor Cyan
Write-Host "  - data-ingestion-csv" -ForegroundColor Cyan
Write-Host "  - data-ingestion-xml" -ForegroundColor Cyan
Write-Host "  - data-ingestion-batch" -ForegroundColor Cyan
Write-Host "`nView them at: http://localhost:8090" -ForegroundColor Green

Write-Host "`n=== Tests Completed ===" -ForegroundColor Yellow
