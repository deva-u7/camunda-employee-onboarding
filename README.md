# Camunda 8 Employee Onboarding

A working demonstration of Camunda 8 process automation patterns using a realistic Employee Onboarding workflow. Built with Spring Boot 3 and Camunda 8.8 self-managed (single JAR).

---

## What This Demonstrates

| Pattern | Where Used |
|---|---|
| Start Event with embedded Form | Employee submits onboarding request via Tasklist |
| Service Task + Job Worker | Validate data, request BG check, send notifications |
| Exclusive Gateway | Data valid? / BG check passed? |
| Event-Based Gateway | Wait for BG result message OR 72h timeout |
| Expanded Sub-Process | Background Verification scoped boundary |
| Parallel Gateway (split + join) | HR Approval and IT Account Setup run concurrently |
| Call Activity | IT Account Setup as a separate deployable child process |
| XOR Gateway (post-HR) | Rejected → terminate, Approved → continue |
| Error Boundary Event | Legacy system failure routed to Manual IT task |
| Non-Interrupting Timer Boundary | 24h HR reminder fires without cancelling the task |
| Business Rule Task + DMN | Training plan determined by department |
| Multi-Instance User Task (sequential) | One training module at a time |
| Message Correlation | BG check result correlated by employee email |
| Role-Based Task Visibility | Each user sees only their relevant tasks |

---

## Prerequisites

| Tool | Version |
|---|---|
| Java | 21+ |
| Docker + Docker Compose | Latest |
| Make | Pre-installed on macOS/Linux |

---

## Quick Start

```bash
# 1. Start Elasticsearch + Camunda
make up

# 2. Wait ~90s, then start the Spring Boot app
./mvnw spring-boot:run

# 3. Set up users and role-based access
make setup-users
```

Open http://localhost:8080 — log in as `demo / demo`.

---

## Demo Users

> Local development only.

| Role | Username | Password | Access |
|---|---|---|---|
| Admin | `demo` | `demo` | Tasklist + Operate + everything |
| HR Manager | `hr.manager` | `hr123` | HR Approval task only |
| IT Support | `it.support` | `it123` | Manual IT Setup task only |
| New Employee | `new.employee` | `emp123` | Start process + Training tasks |

---

## Running the Demo

**Step 1** — Log in as `new.employee` → Tasklist → Processes → **Employee Onboarding** → fill and submit.

Select at least one system. Include `legacy` to trigger the error boundary → manual IT task.

**Step 2** — Simulate the background check:

```bash
make demo-bg-pass   # PASSED
make demo-bg-fail   # FAILED
make bg-check       # interactive
```

**Step 3** — Log in as `hr.manager` → Tasks → **HR Approval** → Approved or Rejected.

**Step 4** — If `legacy` selected: log in as `it.support` → **Manual IT Account Setup**.

**Step 5** — Log in as `new.employee` → complete each **Training** module.

---

## Make Commands

```
make up            Start Docker stack
make down          Stop Docker stack
make nuke          Remove all containers + volumes
make build         Build the JAR (skip tests)
make run           Run the app
make setup-users   Create users, groups, authorizations
make bg-check      Interactive BG check simulator
make demo-bg-pass  Simulate BG PASSED
make demo-bg-fail  Simulate BG FAILED
```

---

## Project Structure

```
camunda-employee-onboarding/
├── docker-compose.yml
├── Makefile
├── scripts/
│   ├── setup-users.sh
│   └── bg-check.sh
└── src/main/
    ├── java/com/devau7/onboarding/
    │   ├── OnboardingApplication.java
    │   ├── controller/
    │   │   └── OnboardingController.java
    │   └── worker/
    │       ├── ValidateEmployeeWorker.java
    │       ├── BackgroundCheckWorker.java
    │       ├── CreateAccountsWorker.java
    │       └── NotificationWorker.java
    └── resources/
        ├── processes/
        │   ├── employee-onboarding.bpmn
        │   └── it-account-setup.bpmn
        ├── decisions/
        │   └── determine-training-plan.dmn
        └── forms/
            ├── employee-info.form
            ├── hr-approval.form
            ├── manual-it-setup.form
            └── training.form
```

---

## Architecture

See [architecture.md](architecture.md) for process flow, BPMN patterns, DMN decision table, and authorization model.
