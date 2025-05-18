package com.shrmagarv.tresatadis.service.transform.impl;

import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.fasterxml.jackson.databind.node.ObjectNode;
import com.shrmagarv.tresatadis.service.transform.DataTransformer;
import org.springframework.core.io.ByteArrayResource;
import org.springframework.core.io.Resource;
import org.springframework.stereotype.Service;

import java.io.InputStream;
import java.nio.charset.StandardCharsets;
import java.util.ArrayList;
import java.util.Iterator;
import java.util.List;

/**
 * Implementation of DataTransformer for JSON data
 */
@Service
public class JsonDataTransformer implements DataTransformer {
    
    private static final String TRANSFORMATION_TYPE = "JSON";
    private final ObjectMapper objectMapper = new ObjectMapper();
    
    @Override
    public String getTransformationType() {
        return TRANSFORMATION_TYPE;
    }
    
    @Override
    public boolean canHandle(String transformationType) {
        return TRANSFORMATION_TYPE.equals(transformationType);
    }
    
    @Override
    public Resource transform(Resource data, String sourceFormat, String transformationConfig) throws Exception {
        if (!"JSON".equalsIgnoreCase(sourceFormat)) {
            throw new IllegalArgumentException("This transformer only works with JSON data");
        }
        
        // Parse the JSON data
        try (InputStream inputStream = data.getInputStream()) {
            JsonNode rootNode;
            if (sourceFormat.equalsIgnoreCase("JSON")) {
                rootNode = objectMapper.readTree(inputStream);
            } else {
                throw new IllegalArgumentException("Unsupported source format: " + sourceFormat);
            }
            
            // Parse transformation config
            JsonNode configNode = objectMapper.readTree(transformationConfig);
            
            // Apply transformations
            JsonNode transformedNode = applyTransformations(rootNode, configNode);
            
            // Convert back to bytes
            byte[] transformedBytes = objectMapper.writeValueAsBytes(transformedNode);
            return new ByteArrayResource(transformedBytes);
        }
    }
    
    private JsonNode applyTransformations(JsonNode data, JsonNode config) {
        // Handle arrays
        if (data.isArray()) {
            List<JsonNode> transformedItems = new ArrayList<>();
            for (JsonNode item : data) {
                JsonNode transformedItem = applyTransformationsToObject(item, config);
                transformedItems.add(transformedItem);
            }
            return objectMapper.valueToTree(transformedItems);
        }
        
        // Handle objects
        return applyTransformationsToObject(data, config);
    }
    
    private JsonNode applyTransformationsToObject(JsonNode data, JsonNode config) {
        if (!data.isObject()) {
            return data; // Can't transform non-objects
        }
        
        ObjectNode result = objectMapper.createObjectNode();
        
        // Field mappings
        if (config.has("fieldMappings")) {
            JsonNode mappings = config.get("fieldMappings");
            for (Iterator<String> it = mappings.fieldNames(); it.hasNext(); ) {
                String targetField = it.next();
                String sourceField = mappings.get(targetField).asText();
                
                if (data.has(sourceField)) {
                    result.set(targetField, data.get(sourceField));
                }
            }
        }
        
        // Field removals
        if (config.has("fieldsToRemove")) {
            // For fields not in the mapping but in the original data, keep them unless specified to remove
            for (Iterator<String> it = data.fieldNames(); it.hasNext(); ) {
                String field = it.next();
                boolean shouldRemove = false;
                
                for (JsonNode fieldToRemove : config.get("fieldsToRemove")) {
                    if (field.equals(fieldToRemove.asText())) {
                        shouldRemove = true;
                        break;
                    }
                }
                
                if (!shouldRemove && !result.has(field)) {
                    result.set(field, data.get(field));
                }
            }
        } else {
            // Keep all fields that weren't mapped
            for (Iterator<String> it = data.fieldNames(); it.hasNext(); ) {
                String field = it.next();
                if (!result.has(field)) {
                    result.set(field, data.get(field));
                }
            }
        }
        
        return result;
    }
}
