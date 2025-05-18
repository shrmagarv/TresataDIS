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
    }
    
    @Override
    public String storeData(Resource data, String sourceFormat, String destinationLocation) throws Exception {
        // destinationLocation should be in format "tableName:schema"
        String[] parts = destinationLocation.split(":");
        if (parts.length != 2) {
            throw new IllegalArgumentException("Destination location should be in format 'tableName:schemaJson'");
        }
        
        String tableName = parts[0];
        String schemaJson = parts[1];
        
        // Parse schema
        JsonNode schema = objectMapper.readTree(schemaJson);
        Map<String, String> columnTypes = new HashMap<>();
        for (Iterator<String> it = schema.fieldNames(); it.hasNext(); ) {
            String column = it.next();
            columnTypes.put(column, schema.get(column).asText());
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
