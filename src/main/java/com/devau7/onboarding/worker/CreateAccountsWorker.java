package com.devau7.onboarding.worker;

import io.camunda.client.annotation.JobWorker;
import io.camunda.client.api.response.ActivatedJob;
import io.camunda.client.api.worker.JobClient;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Component;

import java.util.Map;

@Slf4j
@Component
public class CreateAccountsWorker {

    @JobWorker(type = "create-system-account")
    public void createSystemAccount(JobClient client, ActivatedJob job) {
        Map<String, Object> vars = job.getVariablesAsMap();
        String system = (String) vars.get("system");
        String name   = (String) vars.get("employeeName");
        String email  = (String) vars.get("employeeEmail");

        log.info("Provisioning {} account for {} ({})", system, name, email);

        if ("legacy".equalsIgnoreCase(system)) {
            log.error("Legacy provisioning failed for {}", name);
            client.newThrowErrorCommand(job.getKey())
                    .errorCode("ACCOUNT_CREATION_FAILED")
                    .errorMessage("Legacy system unavailable for " + name)
                    .variables(Map.of("failedSystem", system, "failedEmployee", name))
                    .send().join();
            return;
        }

        log.info("[SIMULATED] {} account provisioned for {} <{}>", system, name, email);
        client.newCompleteCommand(job.getKey())
                .variables(Map.of("accountCreated", true))
                .send().join();
    }
}
