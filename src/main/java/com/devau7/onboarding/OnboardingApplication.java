package com.devau7.onboarding;

import io.camunda.client.annotation.Deployment;
import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;

@SpringBootApplication
@Deployment(resources = {
        "classpath:processes/employee-onboarding.bpmn",
        "classpath:processes/it-account-setup.bpmn",
        "classpath:decisions/determine-training-plan.dmn",
        "classpath:forms/employee-info.form",
        "classpath:forms/hr-approval.form",
        "classpath:forms/manual-it-setup.form",
        "classpath:forms/training.form"
})
public class OnboardingApplication {
    public static void main(String[] args) {
        SpringApplication.run(OnboardingApplication.class, args);
    }
}
