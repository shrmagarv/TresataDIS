package com.shrmagarv.tresatadis.service.source;

import org.springframework.core.io.Resource;

/**
 * Interface for data source connectors
 * Implementations will handle different source types (files, APIs, databases)
 */
public interface DataSourceConnector {
    /**
     * Get source type identifier string
     * @return The source type identifier
     */
    String getSourceType();
    
    /**
     * Check if this connector can handle the given source type
     * @param sourceType The source type to check
     * @return True if can handle, false otherwise
     */
    boolean canHandle(String sourceType);
    
    /**
     * Extract data from the source
     * @param sourceLocation The location of the source (path, URL, connection string)
     * @param sourceFormat The format of the source data (CSV, JSON, etc.)
     * @return Resource containing the data
     * @throws Exception If extraction fails
     */
    Resource extractData(String sourceLocation, String sourceFormat) throws Exception;
}
