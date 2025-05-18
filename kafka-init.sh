#!/bin/bash

# Wait for Kafka to be ready
echo "Waiting for Kafka to be ready..."
until kafka-topics.sh --bootstrap-server kafka:9092 --list > /dev/null 2>&1; do
  sleep 5
done
echo "Kafka is ready"

# Create required topics
echo "Creating Kafka topics..."

# Topic for ingestion jobs
kafka-topics.sh --bootstrap-server kafka:9092 --create --if-not-exists \
  --topic ingestion-jobs \
  --partitions 3 \
  --replication-factor 1

# Topic for real-time data ingestion
kafka-topics.sh --bootstrap-server kafka:9092 --create --if-not-exists \
  --topic ingestion-data \
  --partitions 3 \
  --replication-factor 1

# Topic for job status updates
kafka-topics.sh --bootstrap-server kafka:9092 --create --if-not-exists \
  --topic job-status-updates \
  --partitions 3 \
  --replication-factor 1

# Topic for job results
kafka-topics.sh --bootstrap-server kafka:9092 --create --if-not-exists \
  --topic job-results \
  --partitions 3 \
  --replication-factor 1

echo "Topics created successfully"
echo "List of topics:"
kafka-topics.sh --bootstrap-server kafka:9092 --list
