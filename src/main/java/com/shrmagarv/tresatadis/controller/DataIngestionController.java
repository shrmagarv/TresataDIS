package com.shrmagarv.tresatadis.controller;

import com.shrmagarv.tresatadis.dto.JobCreationRequest;
import com.shrmagarv.tresatadis.dto.JobResponse;
import com.shrmagarv.tresatadis.mapper.JobMapper;
import com.shrmagarv.tresatadis.model.DataStatistics;
import com.shrmagarv.tresatadis.model.Job;
import com.shrmagarv.tresatadis.model.JobLog;
import com.shrmagarv.tresatadis.model.JobStatus;
import com.shrmagarv.tresatadis.service.DataIngestionService;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;
import java.util.concurrent.CompletableFuture;

/**
 * REST controller for the Data Ingestion API
 */
@RestController
@RequestMapping("/api/ingestion")
@Slf4j
public class DataIngestionController {
    
    @Autowired
    private DataIngestionService ingestionService;
    
    @Autowired
    private JobMapper jobMapper;
    
    /**
     * Create a new ingestion job
     * @param request The job creation request
     * @return The created job
     */
    @PostMapping("/jobs")
    public ResponseEntity<JobResponse> createJob(@RequestBody JobCreationRequest request) {
        log.info("Creating new job: {}", request.getName());
        Job job = ingestionService.createJob(jobMapper.toJobEntity(request));
        return ResponseEntity.ok(jobMapper.toJobResponse(job));
    }
    
    /**
     * Get all jobs
     * @return List of jobs
     */
    @GetMapping("/jobs")
    public ResponseEntity<List<JobResponse>> getAllJobs() {
        log.info("Fetching all jobs");
        List<Job> jobs = ingestionService.getAllJobs();
        return ResponseEntity.ok(jobMapper.toJobResponseList(jobs));
    }
    
    /**
     * Get jobs by status
     * @param status The status to filter by
     * @return List of jobs with the given status
     */
    @GetMapping("/jobs/status/{status}")
    public ResponseEntity<List<JobResponse>> getJobsByStatus(@PathVariable JobStatus status) {
        log.info("Fetching jobs with status: {}", status);
        List<Job> jobs = ingestionService.getJobsByStatus(status);
        return ResponseEntity.ok(jobMapper.toJobResponseList(jobs));
    }
    
    /**
     * Get a job by ID
     * @param id The job ID
     * @return The job
     */
    @GetMapping("/jobs/{id}")
    public ResponseEntity<JobResponse> getJobById(@PathVariable Long id) {
        log.info("Fetching job with ID: {}", id);
        Job job = ingestionService.findJobById(id);
        return ResponseEntity.ok(jobMapper.toJobResponse(job));
    }
    
    /**
     * Queue a job for processing
     * @param id The job ID to queue
     * @return The updated job
     */
    @PostMapping("/jobs/{id}/queue")
    public ResponseEntity<JobResponse> queueJob(@PathVariable Long id) {
        log.info("Queueing job with ID: {}", id);
        Job job = ingestionService.queueJob(id);
        return ResponseEntity.ok(jobMapper.toJobResponse(job));
    }
    
    /**
     * Execute a job immediately
     * @param id The job ID to execute
     * @return The job being executed
     */
    @PostMapping("/jobs/{id}/execute")
    public ResponseEntity<JobResponse> executeJob(@PathVariable Long id) {
        log.info("Executing job with ID: {}", id);
        // Queue the job first
        Job job = ingestionService.queueJob(id);
        
        // Then execute it asynchronously
        CompletableFuture.runAsync(() -> {
            try {
                ingestionService.processJobWithRetry(id);
            } catch (Exception e) {
                log.error("Error executing job: {}", id, e);
            }
        });
        
        return ResponseEntity.ok(jobMapper.toJobResponse(job));
    }
    
    /**
     * Get logs for a job
     * @param id The job ID
     * @return List of logs
     */
    @GetMapping("/jobs/{id}/logs")
    public ResponseEntity<List<JobLog>> getJobLogs(@PathVariable Long id) {
        log.info("Fetching logs for job with ID: {}", id);
        List<JobLog> logs = ingestionService.getJobLogs(id);
        return ResponseEntity.ok(logs);
    }
    
    /**
     * Get statistics for a job
     * @param id The job ID
     * @return List of statistics
     */
    @GetMapping("/jobs/{id}/statistics")
    public ResponseEntity<List<DataStatistics>> getJobStatistics(@PathVariable Long id) {
        log.info("Fetching statistics for job with ID: {}", id);
        List<DataStatistics> statistics = ingestionService.getJobStatistics(id);
        return ResponseEntity.ok(statistics);
    }
}
