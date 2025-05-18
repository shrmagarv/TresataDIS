package com.shrmagarv.tresatadis.mapper;

import com.shrmagarv.tresatadis.dto.JobCreationRequest;
import com.shrmagarv.tresatadis.dto.JobResponse;
import com.shrmagarv.tresatadis.model.Job;
import org.springframework.stereotype.Component;

import java.util.List;
import java.util.stream.Collectors;

/**
 * Mapper for converting between Job entities and DTOs
 */
@Component
public class JobMapper {
    
    /**
     * Convert a Job entity to a JobResponse DTO
     * @param job The entity to convert
     * @return The converted DTO
     */
    public JobResponse toJobResponse(Job job) {
        return JobResponse.builder()
                .id(job.getId())
                .name(job.getName())
                .sourceType(job.getSourceType())
                .sourceFormat(job.getSourceFormat())
                .sourceLocation(job.getSourceLocation())
                .transformationType(job.getTransformationType())
                .destinationType(job.getDestinationType())
                .destinationLocation(job.getDestinationLocation())
                .status(job.getStatus())
                .createdAt(job.getCreatedAt())
                .updatedAt(job.getUpdatedAt())
                .completedAt(job.getCompletedAt())
                .retryCount(job.getRetryCount())
                .maxRetries(job.getMaxRetries())
                .build();
    }
    
    /**
     * Convert a list of Job entities to JobResponse DTOs
     * @param jobs The list of entities to convert
     * @return The list of converted DTOs
     */
    public List<JobResponse> toJobResponseList(List<Job> jobs) {
        return jobs.stream()
                .map(this::toJobResponse)
                .collect(Collectors.toList());
    }
    
    /**
     * Convert a JobCreationRequest DTO to a Job entity
     * @param request The DTO to convert
     * @return The converted entity
     */
    public Job toJobEntity(JobCreationRequest request) {
        return Job.builder()
                .name(request.getName())
                .sourceType(request.getSourceType())
                .sourceFormat(request.getSourceFormat())
                .sourceLocation(request.getSourceLocation())
                .transformationType(request.getTransformationType())
                .transformationConfig(request.getTransformationConfig())
                .destinationType(request.getDestinationType())
                .destinationLocation(request.getDestinationLocation())
                .maxRetries(request.getMaxRetries())
                .build();
    }
}
