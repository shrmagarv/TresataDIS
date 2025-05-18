package com.shrmagarv.tresatadis.service.source.impl;

import com.shrmagarv.tresatadis.service.source.DataSourceConnector;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.core.io.ByteArrayResource;
import org.springframework.core.io.Resource;
import org.springframework.http.HttpMethod;
import org.springframework.http.ResponseEntity;
import org.springframework.stereotype.Service;
import org.springframework.web.client.RestTemplate;

/**
 * Implementation of DataSourceConnector for API sources
 */
@Service
public class ApiDataSourceConnector implements DataSourceConnector {
    
    private static final String SOURCE_TYPE = "API";
    
    @Autowired
    private RestTemplate restTemplate;
    
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
        // sourceLocation should be a URL
        ResponseEntity<byte[]> response = restTemplate.exchange(
                sourceLocation,
                HttpMethod.GET,
                null,
                byte[].class
        );
        
        if (response.getBody() == null) {
            throw new RuntimeException("Received empty response from API: " + sourceLocation);
        }
        
        return new ByteArrayResource(response.getBody());
    }
}
