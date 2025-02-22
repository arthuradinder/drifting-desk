package com.arthur.drifting_desk;

import org.springframework.boot.CommandLineRunner;
import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;
import org.springframework.context.annotation.Bean;
import org.springframework.kafka.core.KafkaTemplate;

@SpringBootApplication
public class DriftingDeskApplication {

	public static void main(String[] args) {
		SpringApplication.run(DriftingDeskApplication.class, args);
	}

	@Bean
	CommandLineRunner commandLineRunner(KafkaTemplate<String, String> kafkaTemplate){
		return args -> {
			kafkaTemplate.send("arthur", "Hello Kafka :) Its nice to know you");
		};
	}

}
