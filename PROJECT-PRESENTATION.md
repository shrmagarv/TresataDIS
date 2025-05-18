# Tresata Data Ingestion Service - Project Summary

## Overview

The Tresata Data Ingestion Service (TresataDIS) is a versatile, scalable Spring Boot application designed to streamline data processing workflows. It provides a comprehensive solution for ingesting, transforming, and storing data from multiple sources in various formats.

> **Note**: This documentation was created with AI assistance. AI was utilized for generating documentation and comments in this project.

## Key Features

- **Multi-format Processing**: Handles CSV, JSON, and XML data formats
- **Flexible Sources and Destinations**:
  - Sources: Local files, APIs, databases, Kafka streams
  - Destinations: Local files, PostgreSQL database, cloud storage
- **Transformation Capabilities**:
  - Field mapping and renaming
  - Data validation
  - Field removal and addition
  - Custom transformations
- **Job Management**: Create, queue, execute, and monitor data processing jobs
- **Comprehensive REST API**: Full control via API endpoints
- **Detailed Monitoring**: Job statistics and logs for visibility

## Technology Stack

- **Backend**: Spring Boot with Java
- **Database**: PostgreSQL
- **Messaging**: Apache Kafka
- **Containerization**: Docker and Docker Compose
- **Testing**: PowerShell scripts for API testing

## How to Run the Project

### Quick Start (Docker)

```powershell
# Navigate to the project directory
cd TresataDIS

# Start all services
docker-compose up -d

# Run the test script (with execution policy bypass if needed)
PowerShell -ExecutionPolicy Bypass -File ./test-api.ps1
```

### Note on PowerShell Scripts

When running PowerShell scripts, you might encounter execution policy restrictions. Use one of these solutions:

```powershell
# Option 1: Run with bypass parameter (preferred for one-time execution)
PowerShell -ExecutionPolicy Bypass -File ./test-api.ps1

# Option 2: Change execution policy (requires Administrator privileges)
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser
```

### Detailed Steps

1. **Extract/Clone the Project**
   - Extract the provided ZIP file, or
   - Clone from GitHub: `git clone <repository-url>`

2. **Navigate to Project Directory**
   ```powershell
   cd TresataDIS
   ```

3. **Start the Application**
   ```powershell
   docker-compose up -d
   ```
   This starts PostgreSQL, Kafka, and the application itself.

4. **Test the API**
   ```powershell
   ./test-api.ps1
   ```
   This script runs comprehensive tests demonstrating all capabilities.

5. **Verify Results**
   - Check processed files in `data/output/`
   - Query the database with `./docker-db-query.ps1` or `./run-db-query.bat`

## Using the API

### Create a CSV Processing Job

```http
POST http://localhost:8080/api/ingestion/jobs
Content-Type: application/json

{
  "name": "Sample CSV Processing",
  "sourceType": "FILE",
  "sourceFormat": "CSV",
  "sourceLocation": "data/sample.csv",
  "transformationType": "CSV",
  "transformationConfig": "{\"delimiter\": \",\", \"hasHeader\": true, \"fieldMappings\": {\"name\": \"full_name\", \"email\": \"contact_email\"}}",
  "destinationType": "LOCAL",
  "destinationLocation": "data/output/sample_processed.csv"
}
```

### Create a Database Import Job

```http
POST http://localhost:8080/api/ingestion/jobs
Content-Type: application/json

{
  "name": "Products CSV to Database Processing",
  "sourceType": "FILE",
  "sourceFormat": "CSV",
  "sourceLocation": "data/products.csv",
  "transformationType": "CSV",
  "transformationConfig": "{\"delimiter\": \",\", \"hasHeader\": true}",
  "destinationType": "DATABASE",
  "destinationLocation": "products:{\"product_id\":\"INTEGER\",\"product_name\":\"VARCHAR\",\"category\":\"VARCHAR\",\"price\":\"DOUBLE\",\"stock_quantity\":\"INTEGER\"}"
}
```

### Execute a Job

```http
POST http://localhost:8080/api/ingestion/jobs/{job_id}/execute
```

### Get Job Status

```http
GET http://localhost:8080/api/ingestion/jobs/{job_id}
```

## Project Structure

```
TresataDIS/
├── data/                  # Test data files and output directory
├── src/
│   ├── main/java/         # Java source code
│   │   └── com/shrmagarv/tresatadis/
│   │       ├── config/    # Application configuration
│   │       ├── controller/# REST API controllers
│   │       ├── model/     # Data models
│   │       └── service/   # Business logic
│   └── resources/         # Configuration files
├── docker-compose.yml     # Docker configuration
├── test-api.ps1           # API test script
├── PROJECT-PRESENTATION.md # This document
└── RUNNING-GUIDE.md       # Detailed setup instructions
```

## Extending the Project

The modular architecture allows for easy extension:

1. **Add New Data Sources**:
   - Implement new source connectors in the service layer
   - Add support for additional formats

2. **Implement New Transformations**:
   - Create new transformation strategies
   - Add custom data processing logic

3. **Integrate Additional Destinations**:
   - Implement new storage handlers
   - Connect to additional database types or services

## Cloud Storage Support

The service supports multiple cloud providers:

- **AWS S3**: Store and retrieve from Amazon S3 buckets
- **Azure Blob Storage**: Integrate with Azure storage containers
- **Google Cloud Storage**: Use GCP buckets for data persistence

## Conclusion

The Tresata Data Ingestion Service is a robust, flexible solution for data processing needs. Its modular design, comprehensive API, and multiple integration options make it suitable for a wide range of data processing scenarios.

For more details, refer to:
- `README.md` - Project documentation and architecture
- `RUNNING-GUIDE.md` - Detailed setup instructions
- `TESTING.md` - Comprehensive testing guidelines
