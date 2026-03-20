package com.devau7.onboarding.controller;

import io.camunda.client.CamundaClient;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.HashMap;
import java.util.Map;

@Slf4j
@RestController
@RequestMapping("/api/onboarding")
@RequiredArgsConstructor
public class OnboardingController {

    private final CamundaClient camundaClient;

    @PostMapping("/background-check-result")
    public ResponseEntity<Map<String, Object>> submitBackgroundCheckResult(
            @RequestBody BackgroundCheckResultRequest request) {

        log.info("Received BG check result for: {} — passed: {}", request.employeeEmail(), request.passed());

        Map<String, Object> vars = new HashMap<>();
        vars.put("bgCheckPassed", request.passed());
        vars.put("bgCheckDetails", request.details());

        camundaClient.newPublishMessageCommand()
                .messageName("background-check-result")
                .correlationKey(request.employeeEmail())
                .variables(vars)
                .send().join();

        return ResponseEntity.ok(Map.of(
                "status", "Message published",
                "correlationKey", request.employeeEmail(),
                "bgCheckPassed", request.passed()
        ));
    }

    @GetMapping("/health")
    public ResponseEntity<Map<String, String>> health() {
        return ResponseEntity.ok(Map.of("status", "UP"));
    }

    public record BackgroundCheckResultRequest(String employeeEmail, boolean passed, String details) {}
}
