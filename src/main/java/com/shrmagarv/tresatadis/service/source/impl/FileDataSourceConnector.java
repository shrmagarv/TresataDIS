package com.shrmagarv.tresatadis.service.source.impl;

import com.shrmagarv.tresatadis.service.source.DataSourceConnector;
import org.springframework.core.io.FileSystemResource;
import org.springframework.core.io.Resource;
import org.springframework.stereotype.Service;

import java.io.File;
import java.nio.file.Files;
import java.nio.file.Path;
import java.nio.file.Paths;

/**
 * Implementation of DataSourceConnector for File sources
 */
@Service
public class FileDataSourceConnector implements DataSourceConnector {
    
    private static final String SOURCE_TYPE = "FILE";
    
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
        Path path = Paths.get(sourceLocation);
        
        // Validate file exists and is readable
        if (!Files.exists(path)) {
            throw new IllegalArgumentException("File does not exist at: " + sourceLocation);
        }
        
        if (!Files.isReadable(path)) {
            throw new IllegalArgumentException("Cannot read file at: " + sourceLocation);
        }
        
        // Validate file format by extension
        String fileExtension = getExtension(path.toString()).toLowerCase();
        if (sourceFormat != null && !sourceFormat.toLowerCase().equals(fileExtension)) {
            throw new IllegalArgumentException(
                    "File format mismatch. Expected: " + sourceFormat + ", Found: " + fileExtension);
        }
        
        return new FileSystemResource(path);
    }
    
    private String getExtension(String filename) {
        int lastDot = filename.lastIndexOf('.');
        if (lastDot < 0) {
            return "";
        }
        return filename.substring(lastDot + 1);
    }
}
