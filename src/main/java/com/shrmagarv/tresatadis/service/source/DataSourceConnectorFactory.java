package com.shrmagarv.tresatadis.service.source;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;

import java.util.List;

/**
 * Factory for DataSourceConnectors
 * Selects the appropriate connector based on source type
 */
@Service
public class DataSourceConnectorFactory {
    
    private final List<DataSourceConnector> connectors;
    
    @Autowired
    public DataSourceConnectorFactory(List<DataSourceConnector> connectors) {
        this.connectors = connectors;
    }
    
    /**
     * Get a connector for the given source type
     * @param sourceType The type of source to connect to
     * @return The appropriate connector
     * @throws IllegalArgumentException If no connector is found
     */
    public DataSourceConnector getConnector(String sourceType) {
        return connectors.stream()
                .filter(connector -> connector.canHandle(sourceType))
                .findFirst()
                .orElseThrow(() -> new IllegalArgumentException("No connector found for source type: " + sourceType));
    }
}
