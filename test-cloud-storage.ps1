# Tresata Data Ingestion Service - Cloud Storage Test Script
# This script tests the CLOUD destination type functionality

$baseUrl = "http://localhost:8080/api/ingestion"
# Use relative paths based on the script location
$scriptRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
$dataPath = Join-Path -Path $scriptRoot -ChildPath "data"
$outputPath = Join-Path -Path $dataPath -ChildPath "output"
$cloudMockPath = Join-Path -Path $dataPath -ChildPath "cloud-mock"

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

# Function to verify file exists in cloud-mock directory
function Test-CloudMockFile {
    param (
        [string]$Provider,
        [string]$Bucket,
        [string]$Key,
        [string]$Description
    )
    
    Write-Host "`n=== $Description ===" -ForegroundColor Yellow
    $filePath = Join-Path -Path $cloudMockPath -ChildPath "$Provider\$Bucket\$Key"
    
    Write-Host "Checking for file: $filePath" -ForegroundColor Gray
    
    if (Test-Path $filePath) {
        Write-Host "File exists in cloud-mock storage" -ForegroundColor Green
        return $true
    } else {
        Write-Host "File not found in cloud-mock storage" -ForegroundColor Red
        return $false
    }
}

# Create cloud-mock directory if it doesn't exist
if (-not (Test-Path $cloudMockPath)) {
    New-Item -ItemType Directory -Path $cloudMockPath -Force | Out-Null
    Write-Host "Created cloud-mock directory: $cloudMockPath" -ForegroundColor Green
}

# Enable cloud storage in application.properties
$appPropsPath = Join-Path -Path $scriptRoot -ChildPath "src\main\resources\application.properties"
if (Test-Path $appPropsPath) {
    $appProps = Get-Content $appPropsPath
    
    # Check if cloud storage is enabled
    $cloudEnabled = $false
    foreach ($line in $appProps) {
        if ($line -match "app\.storage\.cloud\.enabled=true") {
            $cloudEnabled = $true
            break
        }
    }
    
    if (-not $cloudEnabled) {
        Write-Host "Cloud storage is not enabled. Please set app.storage.cloud.enabled=true in application.properties." -ForegroundColor Yellow
        Write-Host "Tests will continue using local fallback." -ForegroundColor Yellow
    }
}

Write-Host "=== Starting Cloud Storage Tests ===" -ForegroundColor Cyan

# Test 1: CSV to AWS S3
Write-Host "`nTest 1: CSV to AWS S3" -ForegroundColor Magenta
$csvFilePath = Join-Path -Path $dataPath -ChildPath "sample.csv"

$awsS3Request = @{
    "source" = @{
        "type" = "FILE"
        "format" = "CSV"
        "location" = $csvFilePath
    }
    "destination" = @{
        "type" = "CLOUD"
        "format" = "CSV"
        "location" = "aws:testbucket:data/sample.csv"
    }
}

$awsResponse = Invoke-ApiRequest -Method "POST" -Endpoint "/process" -Body $awsS3Request
if ($awsResponse) {
    $awsVerify = Test-CloudMockFile -Provider "aws" -Bucket "testbucket" -Key "data/sample.csv" -Description "Verify CSV data stored in AWS S3 mock"
}

# Test 2: JSON to Azure Blob Storage
Write-Host "`nTest 2: JSON to Azure Blob Storage" -ForegroundColor Magenta
$jsonFilePath = Join-Path -Path $dataPath -ChildPath "sample.json"

$azureBlobRequest = @{
    "source" = @{
        "type" = "FILE"
        "format" = "JSON"
        "location" = $jsonFilePath
    }
    "destination" = @{
        "type" = "CLOUD"
        "format" = "JSON"
        "location" = "azure:testcontainer:data/sample.json"
    }
}

$azureResponse = Invoke-ApiRequest -Method "POST" -Endpoint "/process" -Body $azureBlobRequest
if ($azureResponse) {
    $azureVerify = Test-CloudMockFile -Provider "azure" -Bucket "testcontainer" -Key "data/sample.json" -Description "Verify JSON data stored in Azure Blob mock"
}

# Test 3: CSV to Google Cloud Storage
Write-Host "`nTest 3: CSV to Google Cloud Storage" -ForegroundColor Magenta
$productsFilePath = Join-Path -Path $dataPath -ChildPath "products.csv"

$gcpStorageRequest = @{
    "source" = @{
        "type" = "FILE"
        "format" = "CSV"
        "location" = $productsFilePath
    }
    "destination" = @{
        "type" = "CLOUD"
        "format" = "CSV"
        "location" = "gcp:testbucket:data/products.csv"
    }
}

$gcpResponse = Invoke-ApiRequest -Method "POST" -Endpoint "/process" -Body $gcpStorageRequest
if ($gcpResponse) {
    $gcpVerify = Test-CloudMockFile -Provider "gcp" -Bucket "testbucket" -Key "data/products.csv" -Description "Verify CSV data stored in GCP Storage mock"
}

# Summary
Write-Host "`n=== Cloud Storage Tests Summary ===" -ForegroundColor Cyan
$totalTests = 3
$passedTests = 0

if ($awsVerify) { $passedTests++ }
if ($azureVerify) { $passedTests++ }
if ($gcpVerify) { $passedTests++ }

Write-Host "Tests Passed: $passedTests / $totalTests" -ForegroundColor $(if ($passedTests -eq $totalTests) { "Green" } else { "Yellow" })

Write-Host "`nNOTE: These tests use local file storage as a mock for cloud storage." -ForegroundColor Yellow
Write-Host "To use actual cloud storage, configure the credentials in application.properties." -ForegroundColor Yellow
