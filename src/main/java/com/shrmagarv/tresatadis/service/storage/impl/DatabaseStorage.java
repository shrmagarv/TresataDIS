package com.shrmagarv.tresatadis.service.storage.impl;

import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.shrmagarv.tresatadis.service.storage.DataStorage;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.core.io.Resource;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.stereotype.Service;

import javax.sql.DataSource;
import java.io.BufferedReader;
import java.io.InputStreamReader;
import java.nio.charset.StandardCharsets;
import java.sql.Connection;
import java.sql.PreparedStatement;
import java.util.*;

/**
 * Implementation of DataStorage for database storage
 * Stores data in a relational database
 */
@Service
public class DatabaseStorage implements DataStorage {
    
    private static final String STORAGE_TYPE = "DATABASE";
    
    @Autowired
    private DataSource dataSource;
    
    private final ObjectMapper objectMapper = new ObjectMapper();
    
    @Override
    public String getStorageType() {
        return STORAGE_TYPE;
    }
    
    @Override
    public boolean canHandle(String destinationType) {
        return STORAGE_TYPE.equals(destinationType);
    }    @Override
    public String storeData(Resource data, String sourceFormat, String destinationLocation) throws Exception {
        // destinationLocation should be in format "tableName:schema"
        // First find the first colon which separates the table name from the schema
        int colonIndex = destinationLocation.indexOf(':');
        if (colonIndex == -1 || colonIndex == destinationLocation.length() - 1) {
            throw new IllegalArgumentException("Destination location should be in format 'tableName:schemaJson'");
        }
        
        String tableName = destinationLocation.substring(0, colonIndex).trim();
        String schemaJson = destinationLocation.substring(colonIndex + 1).trim();
        
        Map<String, String> columnTypes = new HashMap<>();
        try {
            // Log the schema for debugging
            System.out.println("Raw schema received: " + schemaJson);
            
            // Multi-step robust parsing strategy for handling various JSON formats
            List<String> candidateSchemas = new ArrayList<>();
            
            // Candidate 1: Original schema as provided
            candidateSchemas.add(schemaJson);
            
            // Candidate 2: Handle PowerShell single-escaped quotes
            candidateSchemas.add(schemaJson.replace("\\\"", "\""));
            
            // Candidate 3: Handle PowerShell double-escaped quotes and backslashes
            String doubleUnescaped = schemaJson.replace("\\\"", "\"").replace("\\\\", "\\");
            candidateSchemas.add(doubleUnescaped);
            
            // Candidate 4: Remove all escapes for simple schema formats
            candidateSchemas.add(schemaJson.replaceAll("\\\\", ""));
            
            // Candidate 5: Handle triple-escaped quotes from nested PowerShell calls
            candidateSchemas.add(schemaJson.replace("\\\\\"", "\""));
            
            // Debug each candidate
            int candidateIndex = 0;
            for (String candidate : candidateSchemas) {
                System.out.println("Candidate " + (++candidateIndex) + ": " + candidate);
            }
            
            boolean parsed = false;
            // Try each candidate schema until one works
            for (String candidate : candidateSchemas) {
                try {
                    JsonNode schema = objectMapper.readTree(candidate);
                    for (Iterator<String> it = schema.fieldNames(); it.hasNext();) {
                        String column = it.next();
                        columnTypes.put(column, schema.get(column).asText());
                    }
                    // If we get here, parsing was successful
                    parsed = true;
                    System.out.println("Successfully parsed schema with candidate: " + candidate);
                    break;
                } catch (Exception e) {
                    // Log the error and continue to next candidate
                    System.out.println("Failed to parse candidate: " + e.getMessage());
                    continue;
                }
            }
            
            // If none of the candidates worked and the map is empty, try a manual approach
            if (!parsed && columnTypes.isEmpty()) {
                System.out.println("All standard parsing methods failed, trying manual parsing...");
                
                // Manual parsing as a last resort
                String strippedJson = schemaJson
                    .replaceAll("\\\\\"", "\"") // Replace escaped quotes
                    .replaceAll("\\\\", "") // Remove remaining backslashes
                    .replaceAll("^\"|\"$", ""); // Remove enclosing quotes if present
                
                System.out.println("Stripped JSON for manual parsing: " + strippedJson);
                
                // Check if it looks like a JSON object
                if (strippedJson.startsWith("{") && strippedJson.endsWith("}")) {
                    // Remove the braces
                    strippedJson = strippedJson.substring(1, strippedJson.length() - 1);
                    
                    // Split by commas not inside quotes
                    String[] pairs = strippedJson.split(",(?=(?:[^\"]*\"[^\"]*\")*[^\"]*$)");
                    for (String pair : pairs) {
                        // Split each pair by colon not inside quotes
                        String[] keyValue = pair.split(":(?=(?:[^\"]*\"[^\"]*\")*[^\"]*$)", 2);
                        if (keyValue.length == 2) {
                            String key = keyValue[0].trim().replaceAll("^\"|\"$", "");
                            String value = keyValue[1].trim().replaceAll("^\"|\"$", "");
                            columnTypes.put(key, value);
                            System.out.println("Manually parsed: " + key + " = " + value);
                        }
                    }
                }
                  // If even the manual parsing failed, try the raw key-value approach
                if (columnTypes.isEmpty()) {
                    System.out.println("Manual JSON parsing failed, trying raw key-value parsing...");
                    // Remove all JSON syntax and just extract key-value pairs
                    String rawText = schemaJson
                        .replaceAll("[{}\"]", "") // Remove JSON syntax
                        .replaceAll("\\\\", "");  // Remove backslashes
                    
                    String[] rawPairs = rawText.split(",");
                    for (String rawPair : rawPairs) {
                        String[] rawKeyValue = rawPair.split(":");
                        if (rawKeyValue.length == 2) {
                            String key = rawKeyValue[0].trim();
                            String value = rawKeyValue[1].trim();
                            columnTypes.put(key, value);
                            System.out.println("Raw parsed: " + key + " = " + value);
                        }
                    }
                }
                
                // Final attempt to handle missing commas in JSON (space-separated key-value pairs)
                if (columnTypes.isEmpty()) {
                    System.out.println("Trying space-delimited parsing for missing commas...");
                    // First, try to fix the schema by adding missing commas
                    String fixedJson = strippedJson;
                    // Ensure we have a closing brace
                    if (!fixedJson.endsWith("}")) {
                        fixedJson = fixedJson + "}";
                    }
                    
                    // Find key-value pairs by regex pattern "key":"value" with no comma
                    java.util.regex.Pattern pattern = java.util.regex.Pattern.compile("\"([^\"]+)\"\\s*:\\s*\"([^\"]+)\"\\s+\"");
                    java.util.regex.Matcher matcher = pattern.matcher(fixedJson);
                    
                    StringBuilder correctedJson = new StringBuilder(fixedJson);
                    int offset = 0;
                    
                    while (matcher.find()) {
                        // Insert a comma after each key-value pair that's missing one
                        int insertPosition = matcher.end(2) + 1 + offset;
                        if (insertPosition < correctedJson.length() && correctedJson.charAt(insertPosition) != ',') {
                            correctedJson.insert(insertPosition, ',');
                            offset++;
                        }
                    }
                    
                    System.out.println("Corrected JSON: " + correctedJson.toString());
                    
                    // Try to parse with standard JSON parser
                    try {
                        JsonNode schema = objectMapper.readTree(correctedJson.toString());
                        for (Iterator<String> it = schema.fieldNames(); it.hasNext();) {
                            String column = it.next();
                            columnTypes.put(column, schema.get(column).asText());
                            System.out.println("Comma-corrected parse: " + column + " = " + schema.get(column).asText());
                        }
                    } catch (Exception e) {
                        // If that fails, try a more aggressive space-splitting approach
                        System.out.println("Corrected JSON parsing failed, trying space-splitting: " + e.getMessage());
                        
                        // Remove braces and quotes, then split by spaces or colons
                        String spaceParsedText = strippedJson
                            .replaceAll("[{}]", "")
                            .trim();
                            
                        // Split by double quote patterns to extract key-value pairs
                        pattern = java.util.regex.Pattern.compile("\"([^\"]+)\"\\s*:\\s*\"([^\"]+)\"");
                        matcher = pattern.matcher(spaceParsedText);
                        
                        while (matcher.find()) {
                            String key = matcher.group(1);
                            String value = matcher.group(2);
                            columnTypes.put(key, value);
                            System.out.println("Space-split parsed: " + key + " = " + value);
                        }
                    }
                }
            }
            
            // If we still have no column types, we failed to parse
            if (columnTypes.isEmpty()) {
                throw new IllegalArgumentException("Failed to parse schema: " + schemaJson + 
                    ". Please ensure it's a valid JSON object with column names and types.");
            }
            
            System.out.println("Final schema parsed with " + columnTypes.size() + " columns: " + columnTypes);
        } catch (Exception e) {
            throw new IllegalArgumentException("Invalid schema JSON format: " + e.getMessage() + 
                ". Make sure the schema is properly formatted. Example: 'tableName:{\"column1\":\"VARCHAR\",\"column2\":\"INTEGER\"}'", e);
        }
        
        // Different handling based on source format
        if ("CSV".equalsIgnoreCase(sourceFormat)) {
            return storeCsvData(data, tableName, columnTypes);
        } else if ("JSON".equalsIgnoreCase(sourceFormat)) {
            return storeJsonData(data, tableName, columnTypes);
        } else {
            throw new IllegalArgumentException("Unsupported format for database storage: " + sourceFormat);
        }
    }
    
    private String storeCsvData(Resource data, String tableName, Map<String, String> columnTypes) throws Exception {
        try (BufferedReader reader = new BufferedReader(new InputStreamReader(data.getInputStream()))) {
            // Read headers
            String headerLine = reader.readLine();
            if (headerLine == null) {
                throw new IllegalArgumentException("CSV file is empty");
            }
            
            List<String> headers = parseCsvLine(headerLine);
            
            // Validate headers against column types
            for (String header : headers) {
                if (!columnTypes.containsKey(header)) {
                    throw new IllegalArgumentException("Header '" + header + "' not found in schema");
                }
            }
            
            // Create SQL for insert
            StringBuilder sql = new StringBuilder("INSERT INTO ")
                    .append(tableName)
                    .append(" (");
            
            for (int i = 0; i < headers.size(); i++) {
                if (i > 0) {
                    sql.append(", ");
                }
                sql.append(headers.get(i));
            }
            
            sql.append(") VALUES (");
            
            for (int i = 0; i < headers.size(); i++) {
                if (i > 0) {
                    sql.append(", ");
                }
                sql.append("?");
            }
            
            sql.append(")");
            
            // Insert data in batches
            int batchSize = 100;
            int totalRecords = 0;
            
            try (Connection conn = dataSource.getConnection();
                 PreparedStatement stmt = conn.prepareStatement(sql.toString())) {
                
                String line;
                int count = 0;
                
                while ((line = reader.readLine()) != null) {
                    List<String> values = parseCsvLine(line);
                    
                    for (int i = 0; i < Math.min(headers.size(), values.size()); i++) {
                        String value = values.get(i);
                        String type = columnTypes.get(headers.get(i));
                        
                        // Set parameter based on type
                        setParameter(stmt, i + 1, value, type);
                    }
                    
                    stmt.addBatch();
                    count++;
                    totalRecords++;
                    
                    if (count >= batchSize) {
                        stmt.executeBatch();
                        count = 0;
                    }
                }
                
                if (count > 0) {
                    stmt.executeBatch();
                }
            }
            
            return "Inserted " + totalRecords + " records into table " + tableName;
        }
    }
    
    private String storeJsonData(Resource data, String tableName, Map<String, String> columnTypes) throws Exception {
        // Parse JSON
        JsonNode rootNode = objectMapper.readTree(data.getInputStream());
        
        if (!rootNode.isArray()) {
            throw new IllegalArgumentException("JSON data must be an array of objects");
        }
        
        // Get all field names from the first object
        List<String> fields = new ArrayList<>();
        if (rootNode.size() > 0) {
            JsonNode firstObject = rootNode.get(0);
            for (Iterator<String> it = firstObject.fieldNames(); it.hasNext(); ) {
                String field = it.next();
                if (columnTypes.containsKey(field)) {
                    fields.add(field);
                }
            }
        }
        
        if (fields.isEmpty()) {
            return "No matching fields found in schema";
        }
        
        // Create SQL for insert
        StringBuilder sql = new StringBuilder("INSERT INTO ")
                .append(tableName)
                .append(" (");
        
        for (int i = 0; i < fields.size(); i++) {
            if (i > 0) {
                sql.append(", ");
            }
            sql.append(fields.get(i));
        }
        
        sql.append(") VALUES (");
        
        for (int i = 0; i < fields.size(); i++) {
            if (i > 0) {
                sql.append(", ");
            }
            sql.append("?");
        }
        
        sql.append(")");
        
        // Insert data in batches
        int batchSize = 100;
        int totalRecords = 0;
        
        try (Connection conn = dataSource.getConnection();
             PreparedStatement stmt = conn.prepareStatement(sql.toString())) {
            
            int count = 0;
            
            for (JsonNode record : rootNode) {
                for (int i = 0; i < fields.size(); i++) {
                    String field = fields.get(i);
                    JsonNode valueNode = record.get(field);
                    String type = columnTypes.get(field);
                    
                    // Set parameter based on type
                    setParameter(stmt, i + 1, valueNode == null ? null : valueNode.asText(), type);
                }
                
                stmt.addBatch();
                count++;
                totalRecords++;
                
                if (count >= batchSize) {
                    stmt.executeBatch();
                    count = 0;
                }
            }
            
            if (count > 0) {
                stmt.executeBatch();
            }
        }
        
        return "Inserted " + totalRecords + " records into table " + tableName;
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
    
    private void setParameter(PreparedStatement stmt, int index, String value, String type) throws Exception {
        if (value == null || value.isEmpty()) {
            stmt.setNull(index, java.sql.Types.NULL);
            return;
        }
        
        switch (type.toUpperCase()) {
            case "INTEGER":
            case "INT":
                stmt.setInt(index, Integer.parseInt(value));
                break;
            case "LONG":
            case "BIGINT":
                stmt.setLong(index, Long.parseLong(value));
                break;
            case "DOUBLE":
            case "FLOAT":
                stmt.setDouble(index, Double.parseDouble(value));
                break;
            case "BOOLEAN":
                stmt.setBoolean(index, Boolean.parseBoolean(value));
                break;
            case "DATE":
                stmt.setDate(index, java.sql.Date.valueOf(value));
                break;
            case "TIMESTAMP":
                stmt.setTimestamp(index, java.sql.Timestamp.valueOf(value));
                break;
            case "VARCHAR":
            case "TEXT":
            default:
                stmt.setString(index, value);
                break;
        }
    }
}
