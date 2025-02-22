//This class will be responsible for creating topics
package com.arthur.drifting_desk.config;

import org.apache.kafka.clients.admin.NewTopic;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.kafka.config.TopicBuilder;

@Configuration
public class KafkaTopicConfig {

    @Bean //so it can get instantiated and we get a new topic
    public NewTopic arthurTopic() {
        return TopicBuilder.name("arthur").build();
    }
}
