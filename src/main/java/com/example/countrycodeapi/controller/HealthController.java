package com.example.countrycodeapi.controller;

import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RestController;

import java.time.LocalDateTime;
import java.util.Map;
import java.util.HashMap;

@RestController
public class HealthController {

    @GetMapping("/health")
    public ResponseEntity<Map<String, Object>> health() {
        Map<String, Object> health = new HashMap<>();
        health.put("status", "UP");
        health.put("timestamp", LocalDateTime.now());
        health.put("service", "Country Code API");
        health.put("version", getClass().getPackage().getImplementationVersion());
        
        return ResponseEntity.ok(health);
    }

    @GetMapping("/info")
    public ResponseEntity<Map<String, String>> info() {
        Map<String, String> info = new HashMap<>();
        info.put("name", "Country Code API");
        info.put("description", "REST API for retrieving country calling codes");
        info.put("version", "1.4.0");
        info.put("build", "spring-boot-maven");
        
        return ResponseEntity.ok(info);
    }
}
