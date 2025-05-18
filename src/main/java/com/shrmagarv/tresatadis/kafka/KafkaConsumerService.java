package com.shrmagarv.tresatadis.kafka;

import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.shrmagarv.tresatadis.dto.JobCreationRequest;
import com.shrmagarv.tresatadis.model.Job;
import com.shrmagarv.tresatadis.service.DataIngestionService;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.kafka.annotation.KafkaListener;
import org.springframework.stereotype.Service;

import java.io.IOException;
import java.util.concurrent.CompletableFuture;

/**
 * Service for handling Kafka messages
 * Listens for job creation requests and data records
 */
@Service
@Slf4j
public class KafkaConsumerService {
    
    @Autowired
    private DataIngestionService ingestionService;
    
    @Autowired
    private ObjectMapper objectMapper;
    
    /**
     * Listen for job creation requests
     * @param message The Kafka message
     */
    @KafkaListener(topics = "${app.kafka.topics.jobs:ingestion-jobs}", groupId = "${spring.kafka.consumer.group-id}")
    public void consumeJobRequests(String message) {
        try {
            log.info("Received job request from Kafka");
            JobCreationRequest request = objectMapper.readValue(message, JobCreationRequest.class);
            // Create job
            Job job = Job.builder()
                    .name(request.getName())
                    .sourceType(request.getSourceType())
                    .sourceFormat(request.getSourceFormat())
                    .sourceLocation(request.getSourceLocation())
                    .transformationType(request.getTransformationType())
                    .transformationConfig(request.getTransformationConfig())
                    .destinationType(request.getDestinationType())
                    .destinationLocation(request.getDestinationLocation())
                    .build();
            ingestionService.createJob(job);
            log.info("Job created successfully: {}", job.getName());
            
        } catch (IOException e) {
            log.error("Error processing job request from Kafka", e);
        }
    }
    
    /**
     * Listen for real-time data records
     * @param message The Kafka message
     */
    @KafkaListener(topics = "${app.kafka.topics.data:ingestion-data}", groupId = "${spring.kafka.consumer.group-id}")
    public void consumeData(String message) {
        try {
            JsonNode dataNode = objectMapper.readTree(message);
            
            // Extract metadata from the message
            if (dataNode.has("metadata")) {
                JsonNode metadata = dataNode.get("metadata");
                
                // Create a job request from the metadata
                JobCreationRequest request = JobCreationRequest.builder()
                        .name("Kafka-" + System.currentTimeMillis())
                        .sourceType("KAFKA")
                        .sourceFormat(metadata.has("format") ? metadata.get("format").asText() : "JSON")
                        .sourceLocation("KAFKA")
                        .transformationType(metadata.has("transformationType") ? 
                                metadata.get("transformationType").asText() : null)
                        .transformationConfig(metadata.has("transformationConfig") ? 
                                metadata.get("transformationConfig").toString() : null)
                        .destinationType(metadata.has("destinationType") ? 
                                metadata.get("destinationType").asText() : "DATABASE")
                        .destinationLocation(metadata.has("destinationLocation") ? 
                                metadata.get("destinationLocation").asText() : null)
                        .build();
                
                // Process the data
                // In a real implementation, you would store the data and then process it using the ingestion service
                log.info("Received real-time data from Kafka: {}", 
                        dataNode.has("data") ? dataNode.get("data").toString() : "No data");
            } else {
                log.warn("Received data message without metadata");
            }
            
        } catch (IOException e) {
            log.error("Error processing data from Kafka", e);
        }
    }
}
