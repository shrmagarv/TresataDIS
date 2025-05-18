package com.shrmagarv.tresatadis.service.transform.impl;

import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.shrmagarv.tresatadis.service.transform.DataTransformer;
import org.springframework.core.io.ByteArrayResource;
import org.springframework.core.io.Resource;
import org.springframework.stereotype.Service;

import java.io.BufferedReader;
import java.io.ByteArrayOutputStream;
import java.io.InputStreamReader;
import java.io.PrintWriter;
import java.nio.charset.StandardCharsets;
import java.util.*;
import java.util.stream.Collectors;

/**
 * Implementation of DataTransformer for CSV data
 * Handles transformation of CSV files based on configuration
 */
@Service
public class CsvDataTransformer implements DataTransformer {
    
    private static final String TRANSFORMATION_TYPE = "CSV";
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
        if (!"CSV".equalsIgnoreCase(sourceFormat)) {
            throw new IllegalArgumentException("This transformer only works with CSV data");
        }
        
        // Parse the CSV data
        List<String> headers;
        List<Map<String, String>> records = new ArrayList<>();
        
        try (BufferedReader reader = new BufferedReader(new InputStreamReader(data.getInputStream()))) {
            // Read headers
            String headerLine = reader.readLine();
            if (headerLine == null) {
                throw new IllegalArgumentException("CSV file is empty");
            }
            
            headers = parseCsvLine(headerLine);
            
            // Read records
            String line;
            while ((line = reader.readLine()) != null) {
                List<String> values = parseCsvLine(line);
                Map<String, String> record = new HashMap<>();
                
                // Map values to headers
                for (int i = 0; i < Math.min(headers.size(), values.size()); i++) {
                    record.put(headers.get(i), values.get(i));
                }
                
                records.add(record);
            }
        }
        
        // Parse transformation config
        JsonNode configNode = objectMapper.readTree(transformationConfig);
        
        // Apply transformations
        List<String> newHeaders;
        List<Map<String, String>> transformedRecords;
        
        if (configNode.has("fieldMappings")) {
            Map<String, String> fieldMappings = new HashMap<>();
            JsonNode mappings = configNode.get("fieldMappings");
            
            for (Iterator<String> it = mappings.fieldNames(); it.hasNext(); ) {
                String targetField = it.next();
                String sourceField = mappings.get(targetField).asText();
                fieldMappings.put(sourceField, targetField);
            }
            
            // Get new headers from mappings
            newHeaders = new ArrayList<>();
            for (String oldHeader : headers) {
                if (fieldMappings.containsKey(oldHeader)) {
                    newHeaders.add(fieldMappings.get(oldHeader));
                } else if (!configNode.has("fieldsToRemove") || 
                        !containsField(configNode.get("fieldsToRemove"), oldHeader)) {
                    newHeaders.add(oldHeader);
                }
            }
            
            // Transform records
            transformedRecords = records.stream()
                    .map(record -> {
                        Map<String, String> newRecord = new HashMap<>();
                        for (Map.Entry<String, String> entry : record.entrySet()) {
                            String oldHeader = entry.getKey();
                            String value = entry.getValue();
                            
                            if (fieldMappings.containsKey(oldHeader)) {
                                newRecord.put(fieldMappings.get(oldHeader), value);
                            } else if (!configNode.has("fieldsToRemove") || 
                                    !containsField(configNode.get("fieldsToRemove"), oldHeader)) {
                                newRecord.put(oldHeader, value);
                            }
                        }
                        return newRecord;
                    })
                    .collect(Collectors.toList());
        } else {
            // No field mappings, just filter out removed fields
            if (configNode.has("fieldsToRemove")) {
                newHeaders = headers.stream()
                        .filter(header -> !containsField(configNode.get("fieldsToRemove"), header))
                        .collect(Collectors.toList());
                
                transformedRecords = records.stream()
                        .map(record -> {
                            Map<String, String> newRecord = new HashMap<>();
                            for (Map.Entry<String, String> entry : record.entrySet()) {
                                String header = entry.getKey();
                                if (!containsField(configNode.get("fieldsToRemove"), header)) {
                                    newRecord.put(header, entry.getValue());
                                }
                            }
                            return newRecord;
                        })
                        .collect(Collectors.toList());
            } else {
                // No transformations
                newHeaders = headers;
                transformedRecords = records;
            }
        }
        
        // Convert back to CSV
        ByteArrayOutputStream outputStream = new ByteArrayOutputStream();
        try (PrintWriter writer = new PrintWriter(outputStream)) {
            // Write headers
            writer.println(String.join(",", newHeaders));
            
            // Write records
            for (Map<String, String> record : transformedRecords) {
                List<String> values = newHeaders.stream()
                        .map(header -> {
                            String value = record.getOrDefault(header, "");
                            // Escape commas in values
                            return value.contains(",") ? "\"" + value + "\"" : value;
                        })
                        .collect(Collectors.toList());
                
                writer.println(String.join(",", values));
            }
        }
        
        return new ByteArrayResource(outputStream.toByteArray());
    }
    
    private List<String> parseCsvLine(String line) {
        List<String> result = new ArrayList<>();
        boolean inQuotes = false;
        StringBuilder field = new StringBuilder();
        
        for (int i = 0; i < line.length(); i++) {
            char c = line.charAt(i);
            
            if (c == '"') {
                inQuotes = !inQuotes;
            } else if (c == ',' && !inQuotes) {
                result.add(field.toString());
                field.setLength(0);
            } else {
                field.append(c);
            }
        }
        
        result.add(field.toString());
        return result;
    }
    
    private boolean containsField(JsonNode fieldsArray, String fieldName) {
        for (JsonNode field : fieldsArray) {
            if (field.asText().equals(fieldName)) {
                return true;
            }
        }
        return false;
    }
}
