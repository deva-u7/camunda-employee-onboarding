package com.devau7.onboarding.worker;

import io.camunda.client.annotation.JobWorker;
import io.camunda.client.api.response.ActivatedJob;
import io.camunda.client.api.worker.JobClient;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Component;

import java.util.Map;

@Slf4j
@Component
public class NotificationWorker {

    @JobWorker(type = "send-notification")
    public void sendNotification(JobClient client, ActivatedJob job) {
        Map<String, Object> vars = job.getVariablesAsMap();
        String type    = (String) vars.getOrDefault("notificationType", "GENERAL");
        String name    = (String) vars.getOrDefault("employeeName", "Unknown");
        String email   = (String) vars.getOrDefault("employeeEmail", "unknown@example.com");
        String message = (String) vars.getOrDefault("notificationMessage", "(no message)");

        log.info("[{}] → {} ({}): {}", type, name, email, message);
        client.newCompleteCommand(job.getKey()).send().join();
    }
}
