package com.shrmagarv.tresatadis.service.storage;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;

import java.util.List;

/**
 * Factory for DataStorage
 * Selects the appropriate storage implementation based on destination type
 */
@Service
public class DataStorageFactory {
    
    private final List<DataStorage> storages;
    
    @Autowired
    public DataStorageFactory(List<DataStorage> storages) {
        this.storages = storages;
    }
    
    /**
     * Get a storage implementation for the given destination type
     * @param destinationType The type of destination to store data in
     * @return The appropriate storage implementation
     * @throws IllegalArgumentException If no storage implementation is found
     */
    public DataStorage getStorage(String destinationType) {
        return storages.stream()
                .filter(storage -> storage.canHandle(destinationType))
                .findFirst()
                .orElseThrow(() -> 
                        new IllegalArgumentException("No storage found for destination type: " + destinationType));
    }
}
