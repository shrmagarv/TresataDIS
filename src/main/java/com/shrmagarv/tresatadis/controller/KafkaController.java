package com.shrmagarv.tresatadis.controller;

import com.shrmagarv.tresatadis.dto.KafkaMessageRequest;
import com.shrmagarv.tresatadis.kafka.KafkaProducerService;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.HashMap;
import java.util.Map;

/**
 * Controller for Kafka message publishing
 */
@RestController
@RequestMapping("/api/kafka")
@Slf4j
public class KafkaController {

    @Autowired
    private KafkaProducerService kafkaProducerService;

    /**
     * Publish a message to a Kafka topic
     * @param request The message request containing topic, key, and message
     * @return Response with status
     */
    @PostMapping("/publish")
    public ResponseEntity<Map<String, String>> publishMessage(@RequestBody KafkaMessageRequest request) {
        log.info("Publishing message to Kafka topic: {}", request.getTopic());
        
        try {
            kafkaProducerService.sendMessage(
                request.getTopic(),
                request.getKey(),
                request.getMessage()
            );
            
            Map<String, String> response = new HashMap<>();
            response.put("status", "success");
            response.put("message", "Message published to " + request.getTopic());
            
            return ResponseEntity.ok(response);
        } catch (Exception e) {
            log.error("Error publishing message to Kafka: {}", e.getMessage(), e);
            
            Map<String, String> response = new HashMap<>();
            response.put("status", "error");
            response.put("message", "Failed to publish message: " + e.getMessage());
            
            return ResponseEntity.internalServerError().body(response);
        }
    }
}
