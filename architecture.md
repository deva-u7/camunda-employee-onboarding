# Architecture — Employee Onboarding

## Stack

| Component | Technology |
|---|---|
| Process Engine | Camunda 8.8.3 (self-managed, single JAR) |
| Search / Export | Elasticsearch 8.16 |
| Application | Spring Boot 3, Java 21 |
| Build | Maven (wrapper included) |
| Infrastructure | Docker Compose |

---

## Process Flow

```
[new.employee] → fills form → [Start Event]
                                      |
                          [validate-employee-data]
                                      |
                              [Data Valid? XOR]
                             /               \
                          invalid            valid
                             |                 |
                      [End: Rejected]  [SubProcess: BG Verification]
                                              |
                                  [request-background-check]
                                              |
                                  [Event-Based Gateway]
                                  /                   \
                         message received           72h timeout
                                |                       |
                    [Message: background-check-result] [End: Timed Out]
                         (correlated by employeeEmail)
                                |
                        [BG Passed? XOR]
                        /             \
                     failed           passed
                        |               |
                 [End: Rejected]  [Parallel Split]
                                  /           \
                        [HR Approval]    [Call: IT Account Setup]
                        hr.manager        (it-account-setup process)
                        24h reminder      parallel multi-instance per system
                             |            if "legacy" → Error Boundary
                     [HR Decision]               → [Manual IT Setup] (it.support)
                     /           \                          |
                Rejected       Approved          [Parallel Join]
                    |               \             /
             [End: Rejected]    [DMN: Training Plan]
                                        |
                              [Training tasks] (new.employee)
                              sequential multi-instance
                                        |
                              [send-notification]
                                        |
                              [End: Onboarding Complete]
```

---

## Job Workers

| Class | Job Type | Purpose |
|---|---|---|
| `ValidateEmployeeWorker` | `validate-employee-data` | Validates name, email, department |
| `BackgroundCheckWorker` | `request-background-check` | Generates BGC request ID |
| `CreateAccountsWorker` | `create-system-account` | Provisions system; throws error for `legacy` |
| `NotificationWorker` | `send-notification` | Logs welcome/reminder notifications |

---

## DMN — Training Plan

| Department | Risk | Level | Days |
|---|---|---|---|
| Finance / Legal | HIGH | ENHANCED | 5 |
| HR / Sales | MEDIUM | STANDARD | 3 |
| Engineering / IT | LOW | STANDARD | 2 |
| *(default)* | MEDIUM | STANDARD | 3 |

---

## Message Correlation

1. Process waits at Event-Based Gateway for `background-check-result` (key: `employeeEmail`)
2. `POST /api/onboarding/background-check-result` receives the external callback
3. App publishes Zeebe message → engine correlates to waiting instance
4. Variables `bgCheckPassed` + `bgCheckDetails` injected into process scope

`zeebe:subscription correlationKey="=employeeEmail"` is on the `<bpmn:message>` element — required for Camunda 8.6+.

---

## Authorization Model

| Who | Resource | Permissions |
|---|---|---|
| `demo` | All components + process definitions | Full admin |
| `hr-managers` group + `hr.manager` user | `employee-onboarding` | READ_USER_TASK, UPDATE_USER_TASK |
| `it-team` group + `it.support` user | `it-account-setup` | READ_USER_TASK, UPDATE_USER_TASK |
| `employees` group + `new.employee` user | `employee-onboarding` | CREATE_PROCESS_INSTANCE + task access |

**Note:** In Camunda 8.8, group grants alone are insufficient — matching USER-level grants are also required.
