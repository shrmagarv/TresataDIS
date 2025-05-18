package com.shrmagarv.tresatadis.service.source.impl;

import com.shrmagarv.tresatadis.service.source.DataSourceConnector;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.core.io.ByteArrayResource;
import org.springframework.core.io.Resource;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.stereotype.Service;

import javax.sql.DataSource;
import java.io.ByteArrayOutputStream;
import java.nio.charset.StandardCharsets;
import java.util.List;
import java.util.Map;
import java.util.stream.Collectors;

/**
 * Implementation of DataSourceConnector for Database sources
 */
@Service
public class DatabaseDataSourceConnector implements DataSourceConnector {
    
    private static final String SOURCE_TYPE = "DATABASE";
    
    @Autowired
    private DataSource dataSource;
    
    @Override
    public String getSourceType() {
        return SOURCE_TYPE;
    }
    
    @Override
    public boolean canHandle(String sourceType) {
        return SOURCE_TYPE.equals(sourceType);
    }
    
    @Override
    public Resource extractData(String sourceLocation, String sourceFormat) throws Exception {
        // sourceLocation should be a SQL query
        JdbcTemplate jdbcTemplate = new JdbcTemplate(dataSource);
        List<Map<String, Object>> results = jdbcTemplate.queryForList(sourceLocation);
        
        ByteArrayOutputStream outputStream = new ByteArrayOutputStream();
        
        // Format depends on sourceFormat (CSV, JSON)
        if ("CSV".equalsIgnoreCase(sourceFormat)) {
            // Write CSV
            if (!results.isEmpty()) {
                // Headers
                String headers = String.join(",", results.get(0).keySet());
                outputStream.write((headers + "\n").getBytes(StandardCharsets.UTF_8));
                
                // Rows
                for (Map<String, Object> row : results) {
                    String line = row.values().stream()
                            .map(v -> v == null ? "" : v.toString().replace(",", "\\,"))
                            .collect(Collectors.joining(","));
                    outputStream.write((line + "\n").getBytes(StandardCharsets.UTF_8));
                }
            }
        } else if ("JSON".equalsIgnoreCase(sourceFormat)) {
            // Use a JSON library in a real implementation
            // This is a simplified representation
            outputStream.write("[".getBytes(StandardCharsets.UTF_8));
            boolean first = true;
            for (Map<String, Object> row : results) {
                if (!first) {
                    outputStream.write(",".getBytes(StandardCharsets.UTF_8));
                }
                first = false;
                
                outputStream.write("{".getBytes(StandardCharsets.UTF_8));
                boolean firstField = true;
                for (Map.Entry<String, Object> entry : row.entrySet()) {
                    if (!firstField) {
                        outputStream.write(",".getBytes(StandardCharsets.UTF_8));
                    }
                    firstField = false;
                    
                    String value = entry.getValue() == null ? "null" : "\"" + entry.getValue().toString() + "\"";
                    outputStream.write(("\"" + entry.getKey() + "\":" + value).getBytes(StandardCharsets.UTF_8));
                }
                outputStream.write("}".getBytes(StandardCharsets.UTF_8));
            }
            outputStream.write("]".getBytes(StandardCharsets.UTF_8));
        } else {
            throw new IllegalArgumentException("Unsupported format for database extraction: " + sourceFormat);
        }
        
        return new ByteArrayResource(outputStream.toByteArray());
    }
}
