@echo off
echo Tresata Data Ingestion Service Management Script
echo ----------------------------------------------

if "%1"=="" goto help
if "%1"=="help" goto help
if "%1"=="start" goto start
if "%1"=="stop" goto stop
if "%1"=="restart" goto restart
if "%1"=="logs" goto logs
if "%1"=="status" goto status
goto help

:help
echo Usage: manage-services.bat [command]
echo Available commands:
echo   start   - Start all services
echo   stop    - Stop all services
echo   restart - Restart all services
echo   logs    - View logs from all services
echo   status  - Check status of services
goto end

:start
echo Starting services...
docker-compose up -d
goto end

:stop
echo Stopping services...
docker-compose down
goto end

:restart
echo Restarting services...
docker-compose down
docker-compose up -d
goto end

:logs
echo Showing logs...
if "%2"=="" (
    docker-compose logs -f
) else (
    docker-compose logs -f %2
)
goto end

:status
echo Checking service status...
docker-compose ps
goto end

:end
