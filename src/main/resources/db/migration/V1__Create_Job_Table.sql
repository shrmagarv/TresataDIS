-- Initial schema for Job table
CREATE TABLE ingestion_jobs (
    id SERIAL PRIMARY KEY,
    name VARCHAR(255) NOT NULL,
    source_type VARCHAR(50) NOT NULL,
    source_format VARCHAR(50) NOT NULL,
    source_location VARCHAR(500) NOT NULL,
    
    transformation_type VARCHAR(100),
    transformation_config TEXT,
    
    destination_type VARCHAR(50) NOT NULL,
    destination_location VARCHAR(500) NOT NULL,
    
    status VARCHAR(20) NOT NULL,
    
    created_at TIMESTAMP NOT NULL,
    updated_at TIMESTAMP NOT NULL,
    completed_at TIMESTAMP,
    
    retry_count INTEGER DEFAULT 0,
    max_retries INTEGER DEFAULT 3
);

-- Table for storing job execution logs
CREATE TABLE job_logs (
    id SERIAL PRIMARY KEY,
    job_id BIGINT NOT NULL REFERENCES ingestion_jobs(id),
    log_level VARCHAR(10) NOT NULL,
    message TEXT NOT NULL,
    timestamp TIMESTAMP NOT NULL,
    stack_trace TEXT
);

-- Table for storing data statistics
CREATE TABLE data_statistics (
    id SERIAL PRIMARY KEY,
    job_id BIGINT NOT NULL REFERENCES ingestion_jobs(id),
    records_processed BIGINT DEFAULT 0,
    records_failed BIGINT DEFAULT 0,
    bytes_processed BIGINT DEFAULT 0,
    processing_time_ms BIGINT DEFAULT 0,
    timestamp TIMESTAMP NOT NULL
);
