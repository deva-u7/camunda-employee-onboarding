package com.devau7.onboarding.worker;

import io.camunda.client.annotation.JobWorker;
import io.camunda.client.api.response.ActivatedJob;
import io.camunda.client.api.worker.JobClient;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Component;

import java.util.Map;

@Slf4j
@Component
public class ValidateEmployeeWorker {

    @JobWorker(type = "validate-employee-data")
    public void validateEmployee(JobClient client, ActivatedJob job) {
        Map<String, Object> vars = job.getVariablesAsMap();
        String name  = (String) vars.get("employeeName");
        String email = (String) vars.get("employeeEmail");
        String dept  = (String) vars.get("department");

        log.info("Validating: name='{}', email='{}', dept='{}'", name, email, dept);

        if (name == null || name.isBlank()) {
            fail(client, job, "Employee name must not be blank"); return;
        }
        if (email == null || !email.contains("@")) {
            fail(client, job, "Invalid email: " + email); return;
        }
        if (dept == null || dept.isBlank()) {
            fail(client, job, "Department must not be blank"); return;
        }

        log.info("Validation passed for {} <{}>", name, email);
        client.newCompleteCommand(job.getKey())
                .variables(Map.of("validationPassed", true))
                .send().join();
    }

    private void fail(JobClient client, ActivatedJob job, String msg) {
        log.warn("Validation failed: {}", msg);
        client.newThrowErrorCommand(job.getKey())
                .errorCode("VALIDATION_FAILED").errorMessage(msg)
                .send().join();
    }
}
