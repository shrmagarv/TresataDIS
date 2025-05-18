package com.shrmagarv.tresatadis.kafka;

import com.fasterxml.jackson.databind.ObjectMapper;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.kafka.core.KafkaTemplate;
import org.springframework.stereotype.Service;

/**
 * Service for producing Kafka messages
 * Used for sending job status updates and results
 */
@Service
@Slf4j
public class KafkaProducerService {
    
    @Autowired
    private KafkaTemplate<String, String> kafkaTemplate;
    
    @Autowired
    private ObjectMapper objectMapper;
    
    /**
     * Send a message to a Kafka topic
     * @param topic The topic to send to
     * @param key The message key
     * @param message The message payload
     */    public void sendMessage(String topic, String key, Object message) {
        try {
            String messageJson = objectMapper.writeValueAsString(message);
            kafkaTemplate.send(topic, key, messageJson)
                    .whenComplete((result, ex) -> {
                        if (ex == null) {
                            log.debug("Message sent to topic: {}", topic);
                        } else {
                            log.error("Failed to send message to topic: {}", topic, ex);
                        }
                    });
        } catch (Exception e) {
            log.error("Error serializing message", e);
        }
    }
    
    /**
     * Send a job status update
     * @param jobId The ID of the job
     * @param status The status update
     */
    public void sendJobStatusUpdate(Long jobId, Object status) {
        sendMessage("job-status-updates", jobId.toString(), status);
    }
    
    /**
     * Send job results
     * @param jobId The ID of the job
     * @param results The results to send
     */
    public void sendJobResults(Long jobId, Object results) {
        sendMessage("job-results", jobId.toString(), results);
    }
}
