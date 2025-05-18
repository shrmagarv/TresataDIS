# Tresata Data Ingestion Service

A scalable, extensible data ingestion service that can handle the ingestion, transformation, and storage of data from multiple sources. This service supports batch and real-time data processing with various formats (CSV, JSON, XML) and destinations (local storage, database, etc.).

> **Note**: This documentation was enhanced with AI assistance. AI was utilized for generating documentation and comments in this project.

## Project Summary

The Tresata Data Ingestion Service (TresataDIS) is a robust Spring Boot application designed to simplify the process of ingesting, transforming, and storing data from various sources. Key capabilities include:

- Processing multiple data formats (CSV, JSON, XML)
- Supporting different data sources (files, databases, Kafka streams)
- Transforming data with field mapping, validation, and custom transformations
- Storing data in various destinations (local files, databases, cloud storage)
- Managing jobs through a comprehensive REST API
- Providing detailed logs and statistics for monitoring

## Features

- **Data Source Integration**: Support for files, APIs, databases
- **Data Transformation**: Field mapping, validation, and customized transformations
- **Storage Options**: Local storage, database storage, cloud storage (AWS S3, Azure Blob Storage, Google Cloud Storage)
- **Real-time Processing**: Kafka integration for streaming data
- **Error Handling**: Comprehensive logging and retry mechanisms
- **Monitoring**: Track ingestion progress and statistics
- **REST API**: Manage ingestion jobs through a RESTful API

## Quick Start Guide for New Users

### Prerequisites

- Docker and Docker Compose
- JDK 21 (for local development without Docker)
- Maven (for local development)
- PowerShell (for Windows users running test scripts)

### Running the Application

#### Option 1: Using Docker Compose (Recommended)

1. Extract the ZIP file or clone the GitHub repository
2. Navigate to the project directory:
   ```powershell
   cd TresataDIS
   ```
3. Start all services with Docker Compose:
   ```powershell
   docker-compose up -d
   ```
4. The application will be available at http://localhost:8080
   The Kafka UI will be available at http://localhost:8090

#### Option 2: Local Development

1. Ensure you have PostgreSQL and Kafka running locally
2. Configure application properties in `src/main/resources/application.properties`
3. Build the project:
   ```powershell
   ./mvnw clean install
   ```
4. Run the application:
   ```powershell
   ./mvnw spring-boot:run
   ```

### Testing the API

Run the comprehensive test script that demonstrates all features:

```powershell
# Navigate to the project directory
cd TresataDIS

# Run the test script
./test-api.ps1
```

This script will:
1. Create sample data processing jobs for CSV, JSON, and XML formats
2. Queue and execute these jobs
3. Check job statuses and statistics
4. Verify the processed output files in the `data/output` directory

### Database Verification

After running the tests, you can verify the database content:

```powershell
# View products imported to the PostgreSQL database
./db-query.ps1
```

## Architecture

The service follows SOLID principles with a modular architecture:

- Source connectors for different data sources
- Transformers for data manipulation
- Storage handlers for different destinations (local, database, cloud)
- Retry and error handling mechanisms

## API Endpoints

### Job Management

- `POST /api/ingestion/jobs` - Create a new ingestion job
- `GET /api/ingestion/jobs` - List all jobs
- `GET /api/ingestion/jobs/{id}` - Get a specific job
- `POST /api/ingestion/jobs/{id}/queue` - Queue a job for processing
- `POST /api/ingestion/jobs/{id}/execute` - Execute a job immediately

### Monitoring

- `GET /api/ingestion/jobs/{id}/logs` - Get logs for a job
- `GET /api/ingestion/jobs/{id}/statistics` - Get statistics for a job

### Sample Job Request (CSV to Database)

```json
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

## Additional Configuration

### Database Setup

The application is configured to use PostgreSQL with the following default settings:

```properties
spring.datasource.url=jdbc:postgresql://localhost:5432/tresata_dis
spring.datasource.username=postgres
spring.datasource.password=postgres
```

These can be modified in the `application.properties` file.

### Database Query Tools

The project includes multiple database query tools to help you interact with the PostgreSQL database:

```powershell
# Docker-based database query tool (recommended, no local psql needed)
PowerShell -ExecutionPolicy Bypass -File ./docker-db-query.ps1

# Alternative: Use the batch file wrapper
.\run-db-query.bat

# For direct psql connection (requires local PostgreSQL client)
PowerShell -ExecutionPolicy Bypass -File ./db-query.ps1
```

These query tools provide these functions:
- List all ingestion jobs
- View jobs by status
- View job logs and statistics
- Run interactive queries
- Check database content

For detailed database documentation, see the `README-DB.md` file.

### Cloud Storage Configuration

Configure cloud storage in `application.properties`:

```properties
# Enable cloud storage
app.storage.cloud.enabled=true
app.storage.cloud.provider=aws  # Default provider (aws, azure, gcp)
app.storage.cloud.local-fallback=true  # Use local storage as fallback

# AWS S3 Configuration
app.storage.cloud.aws.region=us-east-1
app.storage.cloud.aws.access-key=your-access-key
app.storage.cloud.aws.secret-key=your-secret-key

# Azure Blob Storage Configuration
app.storage.cloud.azure.connection-string=your-connection-string

# Google Cloud Storage Configuration
app.storage.cloud.gcp.project-id=your-project-id
app.storage.cloud.gcp.credentials-file=/path/to/credentials.json
```

## Project Structure

```
TresataDIS/
├── data/               # Test data files
│   ├── output/         # Processed output files
│   ├── sample.csv      # Sample CSV file
│   ├── products.csv    # Products CSV file
│   ├── sample.json     # Sample JSON file
│   └── orders.xml      # Orders XML file
├── src/
│   ├── main/
│   │   ├── java/       # Java source code
│   │   └── resources/  # Configuration files
│   └── test/           # Unit and integration tests
├── docker-compose.yml  # Docker configuration
├── Dockerfile          # Application container definition
├── pom.xml             # Maven dependencies
├── test-api.ps1        # API test script
├── db-query.ps1        # Database query script
└── README.md           # Project documentation
```

## Troubleshooting

### Common Issues

1. **Database connection errors**:
   - Ensure Docker containers are running: `docker ps`
   - Check database logs: `docker logs tresata-dis-postgres`

2. **API request failures**:
   - Verify the application is running and accessible
   - Check request format and parameters
   - Review application logs for errors: `logs/tresata-dis.log`

3. **File processing errors**:
   - Ensure file paths are correct and files exist
   - Verify file permissions
   - Check transformation configurations for correct format

## Additional Resources

For more detailed information, refer to:

- `CLOUD-STORAGE.md` - Details about cloud storage integration
- `DATABASE-STORAGE.md` - Information about database storage options
- `TESTING.md` - Comprehensive testing guidelines
- `HELP.md` - Additional help and API documentation
