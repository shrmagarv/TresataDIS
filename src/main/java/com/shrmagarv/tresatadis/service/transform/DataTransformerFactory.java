package com.shrmagarv.tresatadis.service.transform;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;

import java.util.List;

/**
 * Factory for DataTransformers
 * Selects the appropriate transformer based on transformation type
 */
@Service
public class DataTransformerFactory {
    
    private final List<DataTransformer> transformers;
    
    @Autowired
    public DataTransformerFactory(List<DataTransformer> transformers) {
        this.transformers = transformers;
    }
    
    /**
     * Get a transformer for the given transformation type
     * @param transformationType The type of transformation to perform
     * @return The appropriate transformer
     * @throws IllegalArgumentException If no transformer is found
     */
    public DataTransformer getTransformer(String transformationType) {
        return transformers.stream()
                .filter(transformer -> transformer.canHandle(transformationType))
                .findFirst()
                .orElseThrow(() -> 
                        new IllegalArgumentException("No transformer found for type: " + transformationType));
    }
}
