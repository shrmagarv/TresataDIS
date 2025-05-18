# Simple script to verify that the storage fix works

$baseUrl = "http://localhost:8080/api/ingestion"
$dataPath = "D:\Data_and_Docs\GitRepos\SpringbootProjects\TresataDataIngestionService\TresataDIS\data"
$outputPath = "$dataPath\output"

# Create output directory if it doesn't exist
if (!(Test-Path -Path $outputPath)) {
    New-Item -ItemType Directory -Path $outputPath -Force | Out-Null
    Write-Host "Created output directory: $outputPath" -ForegroundColor Gray
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

# Test with a simple CSV file job
Write-Host "=== Testing Storage Fix: Create and Execute a CSV File Processing Job ===" -ForegroundColor Yellow
$csvJobRequest = @{
    name = "Storage Fix Test - CSV Processing"
    sourceType = "FILE"
    sourceFormat = "CSV"
    sourceLocation = "$dataPath\sample.csv"
    transformationType = "CSV"
    transformationConfig = '{"delimiter": ",", "hasHeader": true}'
    destinationType = "LOCAL"
    destinationLocation = "$outputPath\fix_test_output.csv"
}

# Create job
$csvJob = Invoke-ApiRequest -Method "Post" -Endpoint "/jobs" -Body $csvJobRequest

if ($csvJob -ne $null) {
    # Queue and execute job
    $queuedJob = Invoke-ApiRequest -Method "Post" -Endpoint "/jobs/$($csvJob.id)/queue"
    $executedJob = Invoke-ApiRequest -Method "Post" -Endpoint "/jobs/$($csvJob.id)/execute"
    
    # Wait for job to complete
    Write-Host "Waiting for job to complete..." -ForegroundColor Yellow
    Start-Sleep -Seconds 5
    
    # Check job status
    $jobStatus = Invoke-ApiRequest -Method "Get" -Endpoint "/jobs/$($csvJob.id)"
    
    # Check output file
    $outputFile = "$outputPath\fix_test_output.csv"
    if (Test-Path $outputFile) {
        Write-Host "SUCCESS! Output file created:" -ForegroundColor Green
        Write-Host $outputFile -ForegroundColor Green
        Write-Host "File contents:" -ForegroundColor Green
        Get-Content $outputFile | Write-Host
    } else {
        Write-Host "ERROR: Output file not created" -ForegroundColor Red
    }
    
    # Check job logs
    Write-Host "`nJob Logs:" -ForegroundColor Yellow
    $jobLogs = Invoke-ApiRequest -Method "Get" -Endpoint "/jobs/$($csvJob.id)/logs"
}

Write-Host "`n=== Test Completed ===" -ForegroundColor Yellow
