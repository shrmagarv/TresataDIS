package com.shrmagarv.tresatadis.dto;

import com.shrmagarv.tresatadis.model.JobStatus;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

/**
 * DTO for job creation requests
 */
@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class JobCreationRequest {
    private String name;
    private String sourceType; // FILE, API, DATABASE
    private String sourceFormat; // CSV, JSON, XML, etc.
    private String sourceLocation; // Path, URL, connection details
    
    private String transformationType; // The type of transformation to apply
    private String transformationConfig; // JSON configuration for the transformation
    
    private String destinationType; // LOCAL_STORAGE, CLOUD_STORAGE, DATABASE
    private String destinationLocation; // Path, connection details
    
    private Integer maxRetries;
}
