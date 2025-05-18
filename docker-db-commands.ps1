# Tresata Data Ingestion Service - Quick Docker Database Commands
# This file contains common docker exec commands for database operations

# PostgreSQL container name
$dbContainerName = "tresata-dis-postgres"

# Database connection parameters
$dbName = "tresata_dis"
$dbUser = "postgres"

Write-Host "Tresata Data Ingestion Service - Quick Database Commands" -ForegroundColor Cyan
Write-Host "===================================================" -ForegroundColor Cyan
Write-Host "Copy and paste any of these commands to perform database operations:" -ForegroundColor Yellow

Write-Host "`n1. Check container status:" -ForegroundColor White
Write-Host "docker ps -a | Select-String tresata-dis-postgres" -ForegroundColor Gray

Write-Host "`n2. Start PostgreSQL container (if not running):" -ForegroundColor White
Write-Host "docker start $dbContainerName" -ForegroundColor Gray

Write-Host "`n3. Interactive PostgreSQL session:" -ForegroundColor White
Write-Host "docker exec -it $dbContainerName psql -d $dbName -U $dbUser" -ForegroundColor Gray

Write-Host "`n4. List all tables:" -ForegroundColor White
Write-Host "docker exec -it $dbContainerName psql -d $dbName -U $dbUser -c '\dt'" -ForegroundColor Gray

Write-Host "`n5. View ingestion jobs:" -ForegroundColor White
Write-Host "docker exec -it $dbContainerName psql -d $dbName -U $dbUser -c 'SELECT * FROM ingestion_jobs ORDER BY created_at DESC;'" -ForegroundColor Gray

Write-Host "`n6. View job logs:" -ForegroundColor White 
Write-Host "docker exec -it $dbContainerName psql -d $dbName -U $dbUser -c 'SELECT * FROM job_logs ORDER BY timestamp DESC LIMIT 50;'" -ForegroundColor Gray

Write-Host "`n7. View data statistics:" -ForegroundColor White
Write-Host "docker exec -it $dbContainerName psql -d $dbName -U $dbUser -c 'SELECT * FROM data_statistics ORDER BY timestamp DESC;'" -ForegroundColor Gray

Write-Host "`n8. View database schema:" -ForegroundColor White
Write-Host "docker exec -it $dbContainerName psql -d $dbName -U $dbUser -c 'SELECT table_name, column_name, data_type FROM information_schema.columns WHERE table_schema = ''public'' ORDER BY table_name, ordinal_position;'" -ForegroundColor Gray

Write-Host "`n9. Create a database backup:" -ForegroundColor White
Write-Host "docker exec -it $dbContainerName pg_dump -U $dbUser $dbName > backup_\$(Get-Date -Format 'yyyy-MM-dd').sql" -ForegroundColor Gray

Write-Host "`n10. Execute SQL from file:" -ForegroundColor White
Write-Host "Get-Content ./your-script.sql | docker exec -i $dbContainerName psql -d $dbName -U $dbUser" -ForegroundColor Gray

Write-Host "`nNote: For interactive script with more features, run:" -ForegroundColor Cyan
Write-Host "./docker-db-query.ps1" -ForegroundColor Yellow
