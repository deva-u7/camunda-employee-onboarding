package com.devau7.onboarding.worker;

import io.camunda.client.annotation.JobWorker;
import io.camunda.client.api.response.ActivatedJob;
import io.camunda.client.api.worker.JobClient;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Component;

import java.util.Map;

@Slf4j
@Component
public class BackgroundCheckWorker {

    @JobWorker(type = "request-background-check")
    public void requestBackgroundCheck(JobClient client, ActivatedJob job) {
        Map<String, Object> vars = job.getVariablesAsMap();
        String name  = (String) vars.get("employeeName");
        String email = (String) vars.get("employeeEmail");
        String requestId = "BGC-" + System.currentTimeMillis();

        log.info("BG check requested for {} <{}> — requestId: {}", name, email, requestId);

        client.newCompleteCommand(job.getKey())
                .variables(Map.of("bgCheckRequestId", requestId))
                .send().join();
    }
}
