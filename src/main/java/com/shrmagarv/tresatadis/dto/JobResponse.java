package com.shrmagarv.tresatadis.dto;

import com.shrmagarv.tresatadis.model.JobStatus;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.time.LocalDateTime;

/**
 * DTO for job responses
 */
@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class JobResponse {
    private Long id;
    private String name;
    private String sourceType;
    private String sourceFormat;
    private String sourceLocation;
    
    private String transformationType;
    
    private String destinationType;
    private String destinationLocation;
    
    private JobStatus status;
    
    private LocalDateTime createdAt;
    private LocalDateTime updatedAt;
    private LocalDateTime completedAt;
    
    private Integer retryCount;
    private Integer maxRetries;
}
