# Database Storage in TresataDIS

This document explains how to use the DATABASE destination type in the Tresata Data Ingestion Service.

## Overview

The DATABASE destination type allows you to store transformed data directly into a PostgreSQL database table. This feature is particularly useful for:

- Populating database tables from files
- Creating analytical tables from processed data
- Migrating data between formats with database as the destination

## How It Works

When using the DATABASE destination type, the ingestion service:

1. Creates a table in the database if it doesn't exist (based on the schema provided)
2. Transforms the input data according to the transformation configuration
3. Maps the transformed data to the database columns
4. Inserts the data in batches for optimal performance

## Configuration

To use the DATABASE destination type, configure a job with the following parameters:

```json
{
  "name": "CSV to Database Example",
  "sourceType": "FILE",
  "sourceFormat": "CSV",
  "sourceLocation": "/path/to/data.csv",
  "transformationType": "CSV",
  "transformationConfig": "{\"delimiter\": \",\", \"hasHeader\": true}",
  "destinationType": "DATABASE",
  "destinationLocation": "table_name:{\"column1\":\"TYPE\",\"column2\":\"TYPE\"}"
}
```

### destinationLocation Format

The `destinationLocation` parameter requires a specific format:

```
tableName:schemaJson
```

Where:
- `tableName` is the name of the database table to store data in
- `schemaJson` is a JSON object mapping column names to PostgreSQL data types

For example:
```
products:{"product_id":"INTEGER","product_name":"VARCHAR","price":"DOUBLE"}
```

### Supported Data Types

The following PostgreSQL data types are supported:

- `INTEGER`, `INT` - Integer values
- `BIGINT`, `LONG` - Large integer values
- `DOUBLE`, `FLOAT` - Floating point values
- `VARCHAR`, `TEXT` - Text values
- `BOOLEAN` - Boolean values (true/false)
- `DATE` - Date values (format: YYYY-MM-DD)
- `TIMESTAMP` - Timestamp values (format: YYYY-MM-DD HH:MM:SS)

## Examples

### CSV to Database

```json
{
  "name": "Products CSV to Database",
  "sourceType": "FILE",
  "sourceFormat": "CSV",
  "sourceLocation": "data/products.csv",
  "transformationType": "CSV",
  "transformationConfig": "{\"delimiter\": \",\", \"hasHeader\": true}",
  "destinationType": "DATABASE",
  "destinationLocation": "products:{\"product_id\":\"INTEGER\",\"product_name\":\"VARCHAR\",\"category\":\"VARCHAR\",\"price\":\"DOUBLE\",\"stock_quantity\":\"INTEGER\"}"
}
```

### JSON to Database

```json
{
  "name": "Users JSON to Database",
  "sourceType": "FILE",
  "sourceFormat": "JSON",
  "sourceLocation": "data/users.json",
  "transformationType": "JSON",
  "transformationConfig": "{\"fieldMappings\": {\"name\": \"full_name\"}}",
  "destinationType": "DATABASE",
  "destinationLocation": "users:{\"id\":\"INTEGER\",\"full_name\":\"VARCHAR\",\"email\":\"VARCHAR\",\"active\":\"BOOLEAN\"}"
}
```

## Testing

Use the provided test scripts to verify database storage functionality:

- `test-db-storage.ps1` - PowerShell script for Windows
- `test-db-storage.sh` - Bash script for Linux/Mac

Run these scripts to test different data formats being stored in the database.

## Limitations

1. XML format is not currently supported for database storage
2. Database schema creation is limited to basic column types
3. Primary keys, indexes, and constraints must be created separately
4. Large datasets may need to be split into multiple batches for optimal performance

## Troubleshooting

If you encounter issues with database storage, check the following:

1. Ensure PostgreSQL is running and accessible
2. Verify the schema JSON is properly formatted
3. Check job logs for detailed error messages
4. Ensure the data types match the actual data values
