# Running the Tresata Data Ingestion Service

This guide provides detailed steps to run the Tresata Data Ingestion Service application after receiving it as a ZIP file or GitHub repository link.

> **Note**: Documentation and comments in this project were enhanced with AI assistance.

## Prerequisites

Before starting, ensure you have the following installed:

- **Docker** (20.10.x or newer) and **Docker Compose** (v2.x or newer)
- **Java Development Kit (JDK)** 17 or later (only needed for running without Docker)
- **PowerShell** 5.1 or newer (for Windows users)
- **Git** (only if cloning from GitHub)

## Option 1: Running from a ZIP File

1. **Extract the ZIP file** to a location of your choice
   ```
   Extract TresataDIS.zip to D:\path\to\destination
   ```

2. **Navigate to the project directory** in PowerShell or your terminal
   ```powershell
   cd D:\path\to\destination\TresataDIS
   ```

3. **Start the application using Docker Compose**
   ```powershell
   docker-compose up -d
   ```
   This will start PostgreSQL, Kafka, and the TresataDIS application.

4. **Wait for initialization** (about 30-60 seconds)

5. **Test the application** by running the provided test script
   ```powershell
   ./test-api.ps1
   ```
   
6. **Verify the results** in the output directory and database
   ```powershell
   # List processed files
   Get-ChildItem -Path "./data/output"
   
   # Query the database with Docker (recommended method)
   PowerShell -ExecutionPolicy Bypass -File ./docker-db-query.ps1
   
   # Or use the batch file wrapper for easier execution
   ./run-db-query.bat
   ```

## Option 2: Running from a GitHub Repository

1. **Clone the repository**
   ```powershell
   git clone https://github.com/username/TresataDataIngestionService.git
   ```

2. **Navigate to the project directory**
   ```powershell
   cd TresataDataIngestionService/TresataDIS
   ```

3. **Start the application using Docker Compose**
   ```powershell
   docker-compose up -d
   ```

4. **Test the application** by running the provided test script
   ```powershell
   ./test-api.ps1
   ```

## Option 3: Running without Docker (Development Mode)

1. **Start a PostgreSQL database** (if not already running)
   - Ensure it's running on port 5432
   - Create a database named `tresata_dis`
   - Set username and password to `postgres` or update the configuration

2. **Start Kafka** (if not already running)
   - Ensure it's running on port 9092 or update the configuration

3. **Configure the application**
   - Edit `src/main/resources/application.properties` to match your environment

4. **Build the application**
   ```powershell
   ./mvnw clean package
   ```

5. **Run the application**
   ```powershell
   ./mvnw spring-boot:run
   ```

## Verifying the Installation

1. **Check if the API is accessible**
   - Open a web browser and navigate to: http://localhost:8080/api/ingestion/jobs
   - You should see an empty array `[]` or a list of jobs if any exist

2. **Check Docker containers** (if using Docker)
   ```powershell
   docker ps
   ```
   You should see containers for:
   - tresata-dis-app
   - tresata-dis-postgres
   - tresata-dis-kafka
   - tresata-dis-zookeeper

## Using the Service

After installation, you can:

1. **Create data processing jobs** using the API endpoint:
   - POST http://localhost:8080/api/ingestion/jobs

2. **Monitor jobs** through:
   - GET http://localhost:8080/api/ingestion/jobs
   - GET http://localhost:8080/api/ingestion/jobs/{id}/logs
   - GET http://localhost:8080/api/ingestion/jobs/{id}/statistics

3. **Process various data formats**:
   - CSV files
   - JSON documents
   - XML files

4. **Store data in**:
   - Local file system
   - PostgreSQL database
   - Cloud storage (with proper configuration)

## Troubleshooting

### Common Issues

1. **PowerShell script execution policy restrictions**
   - If you encounter an error about script execution being disabled, open PowerShell as Administrator and run:
     ```powershell
     Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser
     ```
   - Or run the scripts with the bypass parameter:
     ```powershell
     PowerShell -ExecutionPolicy Bypass -File .\test-api.ps1
     ```

2. **Port conflicts**
   - Check if ports 8080, 5432, or 9092 are already in use
   - Modify the docker-compose.yml file to use different ports

3. **Permission issues**
   - Ensure the current user has write access to the project directory
   - For Linux/macOS, you may need to run with sudo

4. **Docker container failures**
   - Check container logs: `docker logs tresata-dis-app`
   - Restart containers: `docker-compose restart`

5. **Database connection errors**
   - Ensure PostgreSQL is running: `docker ps | grep postgres`
   - Check database logs: `docker logs tresata-dis-postgres`
   - Verify the PostgreSQL port in db-query.ps1 matches your configuration (default 5432)

## Additional Resources

For more information, refer to:

- `PROJECT-SUMMARY.md` - Complete project overview and features
- `README.md` - Project documentation and architecture
- `TESTING.md` - Comprehensive testing guidelines

## Support

For questions or issues:
1. Check the documentation and log files
2. Consult common troubleshooting steps above
3. Contact the project maintainer
