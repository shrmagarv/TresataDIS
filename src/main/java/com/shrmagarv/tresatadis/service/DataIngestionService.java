package com.shrmagarv.tresatadis.service;

import com.shrmagarv.tresatadis.model.DataStatistics;
import com.shrmagarv.tresatadis.model.Job;
import com.shrmagarv.tresatadis.model.JobLog;
import com.shrmagarv.tresatadis.model.JobStatus;
import com.shrmagarv.tresatadis.repository.DataStatisticsRepository;
import com.shrmagarv.tresatadis.repository.JobLogRepository;
import com.shrmagarv.tresatadis.repository.JobRepository;
import com.shrmagarv.tresatadis.service.source.DataSourceConnector;
import com.shrmagarv.tresatadis.service.source.DataSourceConnectorFactory;
import com.shrmagarv.tresatadis.service.storage.DataStorage;
import com.shrmagarv.tresatadis.service.storage.DataStorageFactory;
import com.shrmagarv.tresatadis.service.transform.DataTransformer;
import com.shrmagarv.tresatadis.service.transform.DataTransformerFactory;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.core.io.Resource;
import org.springframework.retry.annotation.Backoff;
import org.springframework.retry.annotation.Retryable;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDateTime;
import java.util.List;
import java.util.Optional;
import java.util.concurrent.CompletableFuture;

/**
 * Core service for data ingestion
 * Handles the end-to-end process of extracting, transforming, and storing data
 */
@Service
@Slf4j
public class DataIngestionService {
    
    @Autowired
    private JobRepository jobRepository;
    
    @Autowired
    private JobLogRepository jobLogRepository;
    
    @Autowired
    private DataStatisticsRepository dataStatisticsRepository;
    
    @Autowired
    private DataSourceConnectorFactory sourceConnectorFactory;
    
    @Autowired
    private DataTransformerFactory transformerFactory;
    
    @Autowired
    private DataStorageFactory storageFactory;
    
    /**
     * Create a new ingestion job
     * @param job The job details
     * @return The created job
     */
    @Transactional
    public Job createJob(Job job) {
        // Set default values if not provided
        if (job.getStatus() == null) {
            job.setStatus(JobStatus.CREATED);
        }
        
        job.setCreatedAt(LocalDateTime.now());
        job.setUpdatedAt(LocalDateTime.now());
        
        if (job.getRetryCount() == null) {
            job.setRetryCount(0);
        }
        
        if (job.getMaxRetries() == null) {
            job.setMaxRetries(3);
        }
        
        log.info("Creating new ingestion job: {}", job.getName());
        return jobRepository.save(job);
    }
    
    /**
     * Queue a job for processing
     * @param jobId The ID of the job to queue
     * @return The updated job
     */
    @Transactional
    public Job queueJob(Long jobId) {
        Job job = findJobById(jobId);
        job.setStatus(JobStatus.QUEUED);
        job.setUpdatedAt(LocalDateTime.now());
        
        log.info("Queueing job: {} (ID: {})", job.getName(), job.getId());
        return jobRepository.save(job);
    }
    
    /**
     * Execute a job asynchronously
     * @param jobId The ID of the job to execute
     * @return CompletableFuture of the job execution
     */
    public CompletableFuture<Job> executeJob(Long jobId) {
        return CompletableFuture.supplyAsync(() -> {
            Job job = findJobById(jobId);
            
            try {
                // Process the job
                processJob(job);
                return job;
            } catch (Exception e) {
                // Handle exception
                handleJobError(job, e);
                throw new RuntimeException("Job execution failed", e);
            }
        });
    }
    
    /**
     * Process a job with retry logic
     * @param jobId The ID of the job to process
     * @return The processed job
     */
    @Retryable(
            value = {Exception.class},
            maxAttemptsExpression = "${app.retry.max-attempts:3}",
            backoff = @Backoff(
                    delayExpression = "${app.retry.initial-interval:1000}",
                    multiplierExpression = "${app.retry.multiplier:2.0}")
    )
    @Transactional
    public Job processJobWithRetry(Long jobId) {
        Job job = findJobById(jobId);
        
        try {
            return processJob(job);
        } catch (Exception e) {
            // Log error
            log.error("Error processing job: {} (ID: {})", job.getName(), job.getId(), e);
            
            // Increment retry count
            job.setRetryCount(job.getRetryCount() + 1);
            
            if (job.getRetryCount() >= job.getMaxRetries()) {
                job.setStatus(JobStatus.FAILED);
                job.setUpdatedAt(LocalDateTime.now());
                jobRepository.save(job);
                
                // Log failure
                logJobEvent(job, "ERROR", "Job failed after " + job.getRetryCount() + " retry attempts: " + e.getMessage(), e);
                
                throw new RuntimeException("Job failed after max retries", e);
            } else {
                job.setStatus(JobStatus.RETRYING);
                job.setUpdatedAt(LocalDateTime.now());
                jobRepository.save(job);
                
                // Log retry attempt
                logJobEvent(job, "WARN", "Retrying job, attempt " + job.getRetryCount() + " of " + job.getMaxRetries() + ": " + e.getMessage(), null);
                
                throw new RuntimeException("Job failed, will retry", e);
            }
        }
    }
    
    /**
     * Process a job
     * This method handles the full ETL pipeline
     * @param job The job to process
     * @return The processed job
     * @throws Exception If processing fails
     */
    @Transactional
    public Job processJob(Job job) throws Exception {
        // Mark job as running
        job.setStatus(JobStatus.RUNNING);
        job.setUpdatedAt(LocalDateTime.now());
        jobRepository.save(job);
        
        logJobEvent(job, "INFO", "Started processing job", null);
        
        long startTime = System.currentTimeMillis();
        long bytesProcessed = 0;
        int recordsProcessed = 0;
        int recordsFailed = 0;
        
        try {
            // 1. Extract data from source
            logJobEvent(job, "INFO", "Extracting data from source: " + job.getSourceType(), null);
            DataSourceConnector connector = sourceConnectorFactory.getConnector(job.getSourceType());
            Resource data = connector.extractData(job.getSourceLocation(), job.getSourceFormat());
            
            bytesProcessed = data.contentLength();
            
            // 2. Transform data if needed
            if (job.getTransformationType() != null && !job.getTransformationType().isEmpty()) {
                logJobEvent(job, "INFO", "Transforming data with: " + job.getTransformationType(), null);
                DataTransformer transformer = transformerFactory.getTransformer(job.getTransformationType());
                data = transformer.transform(data, job.getSourceFormat(), job.getTransformationConfig());
            }
            
            // 3. Store data
            logJobEvent(job, "INFO", "Storing data to: " + job.getDestinationType(), null);
            DataStorage storage = storageFactory.getStorage(job.getDestinationType());
            String result = storage.storeData(data, job.getSourceFormat(), job.getDestinationLocation());
            
            // Parse records count from result if available
            if (result.toLowerCase().contains("inserted")) {
                try {
                    String[] parts = result.split(" ");
                    for (int i = 0; i < parts.length; i++) {
                        if (parts[i].equalsIgnoreCase("inserted") && i + 1 < parts.length) {
                            recordsProcessed = Integer.parseInt(parts[i + 1]);
                            break;
                        }
                    }
                } catch (NumberFormatException e) {
                    // Ignore parsing error
                }
            }
            
            // 4. Mark job as complete
            job.setStatus(JobStatus.COMPLETED);
            job.setCompletedAt(LocalDateTime.now());
            job.setUpdatedAt(LocalDateTime.now());
            jobRepository.save(job);
            
            logJobEvent(job, "INFO", "Job completed successfully: " + result, null);
        } catch (Exception e) {
            recordsFailed = recordsProcessed;
            recordsProcessed = 0;
            throw e;
        } finally {
            // Record statistics
            long processingTime = System.currentTimeMillis() - startTime;
            DataStatistics statistics = DataStatistics.builder()
                    .job(job)
                    .recordsProcessed((long) recordsProcessed)
                    .recordsFailed((long) recordsFailed)
                    .bytesProcessed(bytesProcessed)
                    .processingTimeMs(processingTime)
                    .timestamp(LocalDateTime.now())
                    .build();
            
            dataStatisticsRepository.save(statistics);
            
            logJobEvent(job, "INFO", String.format("Job statistics: Records processed=%d, Records failed=%d, Bytes processed=%d, Processing time=%d ms", 
                    recordsProcessed, recordsFailed, bytesProcessed, processingTime), null);
        }
        
        return job;
    }
    
    /**
     * Handle an error during job processing
     * @param job The job that had an error
     * @param e The exception that occurred
     */
    private void handleJobError(Job job, Exception e) {
        try {
            job.setStatus(JobStatus.FAILED);
            job.setUpdatedAt(LocalDateTime.now());
            jobRepository.save(job);
            
            logJobEvent(job, "ERROR", "Job failed: " + e.getMessage(), e);
        } catch (Exception ex) {
            log.error("Error handling job failure", ex);
        }
    }
    
    /**
     * Log an event for a job
     * @param job The job to log for
     * @param level The log level
     * @param message The message to log
     * @param e The exception if any
     */
    private void logJobEvent(Job job, String level, String message, Exception e) {
        JobLog jobLog = JobLog.builder()
                .job(job)
                .logLevel(level)
                .message(message)
                .timestamp(LocalDateTime.now())
                .build();
        
        if (e != null) {
            StringBuilder stackTrace = new StringBuilder();
            for (StackTraceElement element : e.getStackTrace()) {
                stackTrace.append(element.toString()).append("\n");
            }
            jobLog.setStackTrace(stackTrace.toString());
        }
        
        jobLogRepository.save(jobLog);
        
        // Also log to application log
        switch (level) {
            case "ERROR":
                log.error("Job {}: {}", job.getId(), message, e);
                break;
            case "WARN":
                log.warn("Job {}: {}", job.getId(), message);
                break;
            case "INFO":
            default:
                log.info("Job {}: {}", job.getId(), message);
                break;
        }
    }
    
    /**
     * Find a job by its ID
     * @param jobId The job ID
     * @return The job
     * @throws IllegalArgumentException If the job is not found
     */
    public Job findJobById(Long jobId) {
        return jobRepository.findById(jobId)
                .orElseThrow(() -> new IllegalArgumentException("Job not found with ID: " + jobId));
    }
    
    /**
     * Get all jobs
     * @return List of all jobs
     */
    public List<Job> getAllJobs() {
        return jobRepository.findAll();
    }
    
    /**
     * Get jobs with a specific status
     * @param status The status to filter by
     * @return List of matching jobs
     */
    public List<Job> getJobsByStatus(JobStatus status) {
        return jobRepository.findByStatus(status);
    }
    
    /**
     * Get logs for a job
     * @param jobId The job ID
     * @return List of logs
     */
    public List<JobLog> getJobLogs(Long jobId) {
        // Verify job exists
        findJobById(jobId);
        return jobLogRepository.findByJobId(jobId);
    }
    
    /**
     * Get statistics for a job
     * @param jobId The job ID
     * @return List of statistics
     */
    public List<DataStatistics> getJobStatistics(Long jobId) {
        // Verify job exists
        findJobById(jobId);
        return dataStatisticsRepository.findByJobId(jobId);
    }
}
