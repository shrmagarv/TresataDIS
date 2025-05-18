# Tresata Data Ingestion Service - Database Query Script Launcher
# This wrapper script helps run the database query script with execution policy bypass

Write-Host "=== Tresata Data Ingestion Service - Database Query Tool Launcher ===" -ForegroundColor Cyan
Write-Host "This wrapper script will launch the database query tool with proper execution policy." -ForegroundColor Gray

# Determine the path to the docker script first (preferred)
$dockerScriptPath = Join-Path -Path $PSScriptRoot -ChildPath "docker-db-query.ps1"
$regularScriptPath = Join-Path -Path $PSScriptRoot -ChildPath "db-query.ps1"

# Check if docker script exists
if (Test-Path $dockerScriptPath) {
    $scriptPath = $dockerScriptPath
    Write-Host "Using Docker-based database query tool (recommended)." -ForegroundColor Green
} elseif (Test-Path $regularScriptPath) {
    $scriptPath = $regularScriptPath
    Write-Host "Using regular database query tool (requires local PostgreSQL client)." -ForegroundColor Yellow
} else {
    Write-Host "ERROR: Could not find any database query scripts in the current directory." -ForegroundColor Red
    Write-Host "Please make sure you're running this script from the TresataDIS directory." -ForegroundColor Red
    exit 1
}

Write-Host "`nLaunching database query tool ($scriptPath)..." -ForegroundColor Green

# Execute the script with Bypass execution policy
try {
    & PowerShell -ExecutionPolicy Bypass -File $scriptPath
}
catch {
    Write-Host "Error launching the database query tool: $_" -ForegroundColor Red
    Write-Host "Try running with administrator privileges or manually set the execution policy:" -ForegroundColor Yellow
    Write-Host "PowerShell -ExecutionPolicy Bypass -File $scriptPath" -ForegroundColor White
    exit 1
}
