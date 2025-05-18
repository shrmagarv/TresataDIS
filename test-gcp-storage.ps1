# Tresata Data Ingestion Service - GCP Cloud Storage Test Script
# This script tests the GCP Cloud Storage functionality

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

# Check if the application is running
Write-Host "Checking if the application is running..." -ForegroundColor Cyan
try {
    $healthCheck = Invoke-RestMethod -Uri "$baseUrl/health" -Method Get -ErrorAction SilentlyContinue
    Write-Host "Application is running." -ForegroundColor Green
}
catch {
    Write-Host "Application doesn't appear to be running. Please start it before running this test." -ForegroundColor Red
    Write-Host "You can start the application with: ./mvnw spring-boot:run" -ForegroundColor Yellow
    exit 1
}

# Get bucket name and project ID from application.properties
$appPropsPath = Join-Path -Path $scriptRoot -ChildPath "src\main\resources\application.properties"
$bucketName = $null
$projectId = $null

if (Test-Path $appPropsPath) {
    $appProps = Get-Content $appPropsPath
    
    foreach ($line in $appProps) {
        if ($line -match "app\.storage\.cloud\.gcp\.bucket=(.+)") {
            $bucketName = $matches[1]
        }
        if ($line -match "app\.storage\.cloud\.gcp\.project-id=(.+)") {
            $projectId = $matches[1]
        }
    }
}

Write-Host "Using GCP Project: $projectId" -ForegroundColor Cyan
Write-Host "Using GCP Bucket: $bucketName" -ForegroundColor Cyan

if ([string]::IsNullOrEmpty($bucketName)) {
    $bucketName = Read-Host -Prompt "Enter your GCP bucket name"
}

# Test 1: Upload CSV file to GCP Cloud Storage
Write-Host "`nTest 1: Upload CSV file to GCP Cloud Storage" -ForegroundColor Magenta
$csvFilePath = Join-Path -Path $dataPath -ChildPath "sample.csv"

$gcpRequest = @{
    "source" = @{
        "type" = "FILE"
        "format" = "CSV"
        "location" = $csvFilePath
    }
    "destination" = @{
        "type" = "CLOUD"
        "format" = "CSV"
        "location" = "gcp:$bucketName:samples/sample_$(Get-Date -Format 'yyyyMMdd_HHmmss').csv"
    }
}

$gcpResponse = Invoke-ApiRequest -Method "POST" -Endpoint "/process" -Body $gcpRequest

# Test 2: Upload JSON file to GCP Cloud Storage
Write-Host "`nTest 2: Upload JSON file to GCP Cloud Storage" -ForegroundColor Magenta
$jsonFilePath = Join-Path -Path $dataPath -ChildPath "sample.json"

$gcpJsonRequest = @{
    "source" = @{
        "type" = "FILE"
        "format" = "JSON"
        "location" = $jsonFilePath
    }
    "destination" = @{
        "type" = "CLOUD"
        "format" = "JSON"
        "location" = "gcp:$bucketName:samples/sample_$(Get-Date -Format 'yyyyMMdd_HHmmss').json"
    }
}

$gcpJsonResponse = Invoke-ApiRequest -Method "POST" -Endpoint "/process" -Body $gcpJsonRequest

# Test 3: Upload CSV products file to GCP Cloud Storage
Write-Host "`nTest 3: Upload Products CSV file to GCP Cloud Storage" -ForegroundColor Magenta
$productsFilePath = Join-Path -Path $dataPath -ChildPath "products.csv"

if (Test-Path $productsFilePath) {
    $gcpProductsRequest = @{
        "source" = @{
            "type" = "FILE"
            "format" = "CSV"
            "location" = $productsFilePath
        }
        "destination" = @{
            "type" = "CLOUD"
            "format" = "CSV"
            "location" = "gcp:$bucketName:products/products_$(Get-Date -Format 'yyyyMMdd_HHmmss').csv"
        }
    }

    $gcpProductsResponse = Invoke-ApiRequest -Method "POST" -Endpoint "/process" -Body $gcpProductsRequest
} else {
    Write-Host "Products CSV file not found: $productsFilePath" -ForegroundColor Yellow
}

Write-Host "`n=== GCP Cloud Storage Tests Complete ===" -ForegroundColor Cyan
Write-Host "`nVerify files in your GCP bucket:" -ForegroundColor Green
Write-Host "https://console.cloud.google.com/storage/browser/$bucketName" -ForegroundColor Cyan
