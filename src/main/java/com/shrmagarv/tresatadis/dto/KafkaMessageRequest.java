package com.shrmagarv.tresatadis.dto;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

/**
 * DTO for Kafka message requests
 */
@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class KafkaMessageRequest {
    private String topic;
    private String key;
    private String message;
}
