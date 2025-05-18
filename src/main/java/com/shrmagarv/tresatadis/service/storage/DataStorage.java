package com.shrmagarv.tresatadis.service.storage;

import org.springframework.core.io.Resource;

/**
 * Interface for data storage operations
 * Implementations will handle different storage backends
 */
public interface DataStorage {
    /**
     * Get storage type identifier string
     * @return The storage type identifier
     */
    String getStorageType();
    
    /**
     * Check if this storage can handle the given destination type
     * @param destinationType The destination type to check
     * @return True if can handle, false otherwise
     */
    boolean canHandle(String destinationType);
    
    /**
     * Store data into the destination
     * @param data The data to store
     * @param sourceFormat The format of the data
     * @param destinationLocation The location to store the data
     * @return Path or identifier where the data was stored
     * @throws Exception If storage operation fails
     */
    String storeData(Resource data, String sourceFormat, String destinationLocation) throws Exception;
}
