@echo off
echo Cleaning up Docker environment and recreating services...

echo Stopping and removing containers...
docker-compose down

echo Removing unused Docker networks...
docker network prune -f

echo Removing unused Docker volumes...
docker volume prune -f

echo Recreating services with updated configuration...
docker-compose up -d

echo Docker environment has been reset and services started with port 4022 for PostgreSQL.
echo You can connect to the database at localhost:4022
