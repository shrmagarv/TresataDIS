# Testing the Tresata Data Ingestion Service

This document provides step-by-step instructions for testing all features of the Tresata Data Ingestion Service.

## Prerequisites

1. The application is running
2. Docker services (PostgreSQL, Kafka, etc.) are running
3. Sample data files have been created in the `data` directory

## Quick Start: Run All Tests

For the easiest testing experience, use the master test script that runs all tests in sequence:

```powershell
cd D:\Data_and_Docs\GitRepos\SpringbootProjects\TresataDataIngestionService\TresataDIS
.\run-tests.ps1
```

This script will:
1. Clean the output directory
2. Run all API tests
3. Run all Kafka tests
4. Summarize the test results
5. Check for errors in the log

## Test Scripts

Three PowerShell scripts have been prepared to test the functionality:
- `run-tests.ps1`: Master script that runs all tests and summarizes results
- `test-api.ps1`: Tests the REST API endpoints for all data formats
- `test-kafka.ps1`: Tests the Kafka integration with various data formats

## Testing Different Data Formats

The test scripts cover processing of multiple data formats:

### CSV Processing
- Simple CSV file processing
- Products data processing
- Field mapping transformations
- Field removal transformations

### JSON Processing
- JSON array processing
- Field mapping transformations
- Field addition transformations

### XML Processing
- Complex XML document processing 
- Element renaming transformations
- Element removal transformations

### Database Storage
- Storing CSV data directly to database tables
- Storing JSON data in database
- Schema definition and mapping
- Type conversion

### Kafka Topics
- Simple text messages
- JSON document messages
- CSV record messages
- XML document messages
- Batch data messages

## Output Files

After running the tests, you will find processed files in the output directory:
- `sample_processed.csv`: Transformed sample CSV file
- `products_processed.csv`: Transformed products CSV file
- `sample_processed.json`: Transformed sample JSON file
- `orders_processed.xml`: Transformed orders XML file
- `batch_data.csv`: Generated batch data file

## Database Storage

Some tests store data directly to the database. After running these tests, you'll find:
- `products` table: Contains product data imported from CSV
- `users` table: Contains user data imported from CSV
- `json_data` table: Contains data imported from JSON files

## Database Records

You can check the database to verify that jobs, logs, and statistics are correctly stored:

```sql
-- Connect to PostgreSQL
-- psql -h localhost -p 4020 -U postgres -d tresata_dis

-- List all jobs
SELECT * FROM ingestion_jobs;

-- Check job logs
SELECT * FROM job_logs;

-- Check processing statistics
SELECT * FROM data_statistics;

-- Count records by status
SELECT status, COUNT(*) FROM ingestion_jobs GROUP BY status;

-- Check data stored via DATABASE destination type
SELECT COUNT(*) FROM products;
SELECT COUNT(*) FROM users;
SELECT COUNT(*) FROM json_data;
```

For easier database access, you can use the included database query scripts:
```powershell
# PowerShell script using local psql client
.\db-query.ps1

# PowerShell script using Docker commands (no local PostgreSQL required)
.\docker-db-query.ps1

# Quick Docker database commands reference
.\docker-db-commands.ps1
```

Or the Bash equivalents for Linux/Mac:
```bash
# Bash script using Docker commands
./docker-db-query.sh

# Quick Docker database commands reference
./docker-db-commands.sh
```

## Kafka Topics

You can use the Kafka UI tool to check messages and topics:

1. Open http://localhost:8090 in your browser
2. Navigate to the "Topics" section
3. Check the following topics:
   - `data-ingestion`: Simple text messages
   - `data-ingestion-json`: JSON document messages
   - `data-ingestion-csv`: CSV record messages
   - `data-ingestion-xml`: XML document messages
   - `data-ingestion-batch`: Batch data messages

## REST API Endpoints

### Job Management
- POST /api/ingestion/jobs - Create a new job
- GET /api/ingestion/jobs - List all jobs
- GET /api/ingestion/jobs/{id} - Get a job by ID
- GET /api/ingestion/jobs/status/{status} - Get jobs by status
- POST /api/ingestion/jobs/{id}/queue - Queue a job
- POST /api/ingestion/jobs/{id}/execute - Execute a job

### Job Logs and Statistics
- GET /api/ingestion/jobs/{id}/logs - Get job logs
- GET /api/ingestion/jobs/{id}/statistics - Get job statistics

### Kafka Integration
- POST /api/kafka/publish - Publish a message to Kafka

## Testing Database Storage Specifically

To test only the database storage functionality:

```powershell
# Windows (PowerShell)
cd TresataDIS
.\test-db-storage.ps1

# Linux/Mac (Bash)
cd TresataDIS
./test-db-storage.sh
```

Alternative simpler test scripts are also available:
```powershell
# Windows
.\test-database-storage.bat

# Linux/Mac
./test-database-storage.sh
```

For detailed documentation on database storage, see `DATABASE-STORAGE.md`.

## Extending the Tests

You can easily extend the tests:

1. Add new data files to the `data` directory
2. Modify the test scripts to include new test cases
3. Add new transformers for additional data formats
4. Create new database schemas for additional data structures

## Troubleshooting

If you encounter issues:

1. Check application logs: `logs/tresata-dis.log`
2. Check Docker container logs: `.\manage-services.bat logs`
3. Verify Docker services are running: `.\manage-services.bat status`
4. Restart services if needed: `.\manage-services.bat restart`
5. Check the output of the test scripts for error messages
