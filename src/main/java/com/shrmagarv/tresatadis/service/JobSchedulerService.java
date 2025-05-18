package com.shrmagarv.tresatadis.service;

import com.shrmagarv.tresatadis.model.Job;
import com.shrmagarv.tresatadis.model.JobStatus;
import com.shrmagarv.tresatadis.repository.JobRepository;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.scheduling.annotation.EnableScheduling;
import org.springframework.scheduling.annotation.Scheduled;
import org.springframework.stereotype.Service;

import java.util.List;
import java.util.concurrent.CompletableFuture;

/**
 * Service for scheduled batch processing of jobs
 */
@Service
@EnableScheduling
@Slf4j
public class JobSchedulerService {
    
    @Autowired
    private JobRepository jobRepository;
    
    @Autowired
    private DataIngestionService ingestionService;
    
    /**
     * Process queued jobs at a fixed rate
     * This method runs periodically to check for queued jobs and process them
     */
    @Scheduled(fixedDelayString = "${app.scheduler.check-interval:60000}")
    public void processQueuedJobs() {
        log.debug("Checking for queued jobs");
        
        List<Job> queuedJobs = jobRepository.findByStatus(JobStatus.QUEUED);
        
        if (!queuedJobs.isEmpty()) {
            log.info("Found {} queued jobs to process", queuedJobs.size());
            
            for (Job job : queuedJobs) {
                log.info("Processing queued job: {} (ID: {})", job.getName(), job.getId());
                
                // Process the job asynchronously
                CompletableFuture.runAsync(() -> {
                    try {
                        ingestionService.processJobWithRetry(job.getId());
                    } catch (Exception e) {
                        log.error("Error processing job: {}", job.getId(), e);
                    }
                });
            }
        }
    }
    
    /**
     * Check for failed jobs that need retrying
     */
    @Scheduled(fixedDelayString = "${app.scheduler.retry-interval:300000}")
    public void checkFailedJobsForRetry() {
        log.debug("Checking for failed jobs that need retrying");
        
        List<Job> retryingJobs = jobRepository.findByStatus(JobStatus.RETRYING);
        
        if (!retryingJobs.isEmpty()) {
            log.info("Found {} jobs to retry", retryingJobs.size());
            
            for (Job job : retryingJobs) {
                if (job.getRetryCount() < job.getMaxRetries()) {
                    log.info("Retrying job: {} (ID: {}), attempt {}/{}", 
                            job.getName(), job.getId(), job.getRetryCount() + 1, job.getMaxRetries());
                    
                    // Process the job with retry logic
                    CompletableFuture.runAsync(() -> {
                        try {
                            ingestionService.processJobWithRetry(job.getId());
                        } catch (Exception e) {
                            log.error("Error retrying job: {}", job.getId(), e);
                        }
                    });
                }
            }
        }
    }
}
