package com.arthur.drifting_desk;

import org.springframework.kafka.annotation.KafkaListener;
import org.springframework.stereotype.Component;

@Component
public class KafkaListeners {
    @KafkaListener(topics = "arthur", groupId = "groupId")
    void Listener(String data){
        System.out.println("Listener received: " + data + " :)");
    }
}
