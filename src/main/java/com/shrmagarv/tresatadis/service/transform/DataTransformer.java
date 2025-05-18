package com.shrmagarv.tresatadis.service.transform;

import org.springframework.core.io.Resource;

/**
 * Interface for data transformers
 * Implementations will handle different transformation types
 */
public interface DataTransformer {
    /**
     * Get transformer type identifier string
     * @return The transformer type identifier
     */
    String getTransformationType();
    
    /**
     * Check if this transformer can handle the given transformation type
     * @param transformationType The transformation type to check
     * @return True if can handle, false otherwise
     */
    boolean canHandle(String transformationType);
    
    /**
     * Transform the data
     * @param data The data to transform
     * @param sourceFormat The format of the source data
     * @param transformationConfig Configuration for the transformation (JSON)
     * @return Transformed data
     * @throws Exception If transformation fails
     */
    Resource transform(Resource data, String sourceFormat, String transformationConfig) throws Exception;
}
