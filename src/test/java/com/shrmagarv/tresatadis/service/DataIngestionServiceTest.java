package com.shrmagarv.tresatadis.service;

import com.shrmagarv.tresatadis.model.Job;
import com.shrmagarv.tresatadis.model.JobStatus;
import com.shrmagarv.tresatadis.repository.JobRepository;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.MockitoAnnotations;

import java.time.LocalDateTime;
import java.util.Arrays;
import java.util.List;
import java.util.Optional;

import static org.junit.jupiter.api.Assertions.*;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.*;

/**
 * Unit tests for DataIngestionService
 */
class DataIngestionServiceTest {
    
    @Mock
    private JobRepository jobRepository;
    
    @InjectMocks
    private DataIngestionService ingestionService;
    
    private Job testJob;
    
    @BeforeEach
    void setUp() {
        MockitoAnnotations.openMocks(this);
        
        // Setup test job
        testJob = Job.builder()
                .id(1L)
                .name("Test Job")
                .sourceType("FILE")
                .sourceFormat("CSV")
                .sourceLocation("/path/to/file.csv")
                .destinationType("LOCAL_STORAGE")
                .destinationLocation("/path/to/destination")
                .status(JobStatus.CREATED)
                .createdAt(LocalDateTime.now())
                .updatedAt(LocalDateTime.now())
                .retryCount(0)
                .maxRetries(3)
                .build();
    }
    
    @Test
    void testCreateJob() {
        when(jobRepository.save(any(Job.class))).thenReturn(testJob);
        
        Job createdJob = ingestionService.createJob(testJob);
        
        assertNotNull(createdJob);
        assertEquals(testJob.getId(), createdJob.getId());
        assertEquals(testJob.getName(), createdJob.getName());
        assertEquals(JobStatus.CREATED, createdJob.getStatus());
        
        verify(jobRepository, times(1)).save(any(Job.class));
    }
    
    @Test
    void testQueueJob() {
        when(jobRepository.findById(1L)).thenReturn(Optional.of(testJob));
        when(jobRepository.save(any(Job.class))).thenAnswer(invocation -> invocation.getArgument(0));
        
        Job queuedJob = ingestionService.queueJob(1L);
        
        assertNotNull(queuedJob);
        assertEquals(JobStatus.QUEUED, queuedJob.getStatus());
        
        verify(jobRepository, times(1)).findById(1L);
        verify(jobRepository, times(1)).save(any(Job.class));
    }
    
    @Test
    void testFindJobById() {
        when(jobRepository.findById(1L)).thenReturn(Optional.of(testJob));
        
        Job foundJob = ingestionService.findJobById(1L);
        
        assertNotNull(foundJob);
        assertEquals(1L, foundJob.getId());
        
        verify(jobRepository, times(1)).findById(1L);
    }
    
    @Test
    void testFindJobById_NotFound() {
        when(jobRepository.findById(999L)).thenReturn(Optional.empty());
        
        assertThrows(IllegalArgumentException.class, () -> {
            ingestionService.findJobById(999L);
        });
        
        verify(jobRepository, times(1)).findById(999L);
    }
    
    @Test
    void testGetAllJobs() {
        Job job1 = Job.builder().id(1L).name("Job 1").build();
        Job job2 = Job.builder().id(2L).name("Job 2").build();
        
        when(jobRepository.findAll()).thenReturn(Arrays.asList(job1, job2));
        
        List<Job> jobs = ingestionService.getAllJobs();
        
        assertNotNull(jobs);
        assertEquals(2, jobs.size());
        
        verify(jobRepository, times(1)).findAll();
    }
    
    @Test
    void testGetJobsByStatus() {
        Job job1 = Job.builder().id(1L).name("Job 1").status(JobStatus.COMPLETED).build();
        Job job2 = Job.builder().id(2L).name("Job 2").status(JobStatus.COMPLETED).build();
        
        when(jobRepository.findByStatus(JobStatus.COMPLETED)).thenReturn(Arrays.asList(job1, job2));
        
        List<Job> jobs = ingestionService.getJobsByStatus(JobStatus.COMPLETED);
        
        assertNotNull(jobs);
        assertEquals(2, jobs.size());
        
        verify(jobRepository, times(1)).findByStatus(JobStatus.COMPLETED);
    }
}
