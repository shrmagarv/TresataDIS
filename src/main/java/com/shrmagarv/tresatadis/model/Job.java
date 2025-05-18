package com.shrmagarv.tresatadis.model;

import jakarta.persistence.*;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;
import java.time.LocalDateTime;

@Entity
@Table(name = "ingestion_jobs")
@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class Job {
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;
    
    private String name;
    private String sourceType; // FILE, API, DATABASE
    private String sourceFormat; // CSV, JSON, XML, etc.
    private String sourceLocation; // Path, URL, connection details
    
    private String transformationType; // The type of transformation to apply
    private String transformationConfig; // JSON configuration for the transformation
    
    private String destinationType; // LOCAL_STORAGE, CLOUD_STORAGE, DATABASE
    private String destinationLocation; // Path, connection details
    
    @Enumerated(EnumType.STRING)
    private JobStatus status;
    
    private LocalDateTime createdAt;
    private LocalDateTime updatedAt;
    private LocalDateTime completedAt;
    
    private Integer retryCount;
    private Integer maxRetries;
    
    @PrePersist
    protected void onCreate() {
        createdAt = LocalDateTime.now();
        updatedAt = LocalDateTime.now();
        if (status == null) {
            status = JobStatus.CREATED;
        }
        if (retryCount == null) {
            retryCount = 0;
        }
        if (maxRetries == null) {
            maxRetries = 3;
        }
    }
    
    @PreUpdate
    protected void onUpdate() {
        updatedAt = LocalDateTime.now();
    }
}
