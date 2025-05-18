# Cloud Storage Integration

This document provides details about the cloud storage functionality in the Tresata Data Ingestion Service (TresataDIS).

## Supported Cloud Storage Providers

TresataDIS supports the following cloud storage providers:

1. **AWS S3**
   - Amazon Simple Storage Service
   - Requires access key, secret key, and region

2. **Azure Blob Storage**
   - Microsoft Azure's object storage solution
   - Requires a connection string

3. **Google Cloud Storage**
   - Google Cloud's object storage service
   - Requires a project ID and credentials file

## Configuration

Cloud storage is configured in the `application.properties` file:

```properties
# Enable/disable cloud storage
app.storage.cloud.enabled=true

# Default cloud provider (aws, azure, gcp)
app.storage.cloud.provider=aws

# Whether to fall back to local storage if cloud storage fails
app.storage.cloud.local-fallback=true

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

## Usage

### API Requests

When making API requests, use the following format for cloud storage destinations:

```json
{
  "source": {
    "type": "FILE",
    "format": "CSV",
    "location": "/path/to/local/file.csv"
  },
  "destination": {
    "type": "CLOUD",
    "format": "CSV",
    "location": "aws:my-bucket:path/to/file.csv"
  }
}
```

The destination location follows this pattern:
- `provider:bucket:key` (e.g., `aws:my-bucket:data/file.csv`)
- If provider is omitted, the default provider from configuration is used: `bucket:key`

### Providers and Location Formats

| Provider | Location Format | Example |
|----------|----------------|---------|
| AWS S3 | `aws:bucket-name:object-key` | `aws:my-bucket:data/file.csv` |
| Azure Blob | `azure:container-name:blob-name` | `azure:my-container:data/file.csv` |
| GCP Storage | `gcp:bucket-name:object-name` | `gcp:my-bucket:data/file.csv` |

## Local Fallback

When `app.storage.cloud.local-fallback` is set to `true`, the service will fall back to local storage if:

1. Cloud provider credentials are not configured
2. There's an error connecting to the cloud provider
3. The upload to cloud storage fails

Local fallback files are stored in the structure:
```
${app.storage.local.base-path}/cloud-mock/${provider}/${bucket}/${key}
```

## Testing

Use the `test-cloud-storage.ps1` script to test cloud storage functionality. This script uses local fallback to simulate cloud storage if actual credentials are not configured.

```powershell
.\test-cloud-storage.ps1
```

## Implementation Details

The cloud storage functionality is implemented in the `CloudStorage.java` class, which implements the `DataStorage` interface. This class is conditionally enabled when `app.storage.cloud.enabled` is set to `true`.

Each cloud provider has its own implementation methods:
- `storeToAwsS3` for AWS S3
- `storeToAzureBlob` for Azure Blob Storage 
- `storeToGoogleStorage` for Google Cloud Storage
