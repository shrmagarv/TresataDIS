package com.shrmagarv.tresatadis.service.storage.impl;

import com.shrmagarv.tresatadis.service.storage.DataStorage;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.core.io.Resource;
import org.springframework.stereotype.Service;

import java.io.FileOutputStream;
import java.io.InputStream;
import java.nio.file.Files;
import java.nio.file.Path;
import java.nio.file.Paths;

/**
 * Implementation of DataStorage for local file storage
 * Stores data in the local file system
 */
@Service
public class LocalFileStorage implements DataStorage {
    
    private static final String STORAGE_TYPE = "LOCAL";
    
    @Value("${app.storage.local.base-path}")
    private String basePath;
    
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
        // Parse the destination location to a path
        Path filePath = Paths.get(destinationLocation);
        
        // If it's not absolute, assume it's relative to the base path
        if (!filePath.isAbsolute()) {
            filePath = Paths.get(basePath, destinationLocation);
        }
        
        // Ensure directory exists
        Files.createDirectories(filePath.getParent());
        
        // Write data to file
        try (InputStream inputStream = data.getInputStream();
             FileOutputStream outputStream = new FileOutputStream(filePath.toFile())) {
            
            byte[] buffer = new byte[8192];
            int bytesRead;
            while ((bytesRead = inputStream.read(buffer)) != -1) {
                outputStream.write(buffer, 0, bytesRead);
            }
        }
        
        return filePath.toString();
    }
}
