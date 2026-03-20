.PHONY: help init nuke up down build run logs ps setup-users bg-check demo-bg-pass demo-bg-fail

help:
	@echo ""
	@echo "  make init          Start Docker stack, wait for healthy"
	@echo "  make up            Start Docker stack"
	@echo "  make down          Stop Docker stack"
	@echo "  make nuke          Stop + remove all containers and volumes"
	@echo "  make build         Build the JAR (skip tests)"
	@echo "  make run           Run the app"
	@echo "  make logs          Tail Docker logs"
	@echo "  make ps            Show container status"
	@echo "  make setup-users   Create groups, users, authorizations (run after make up)"
	@echo "  make bg-check      Interactive BG check simulator"
	@echo "  make demo-bg-pass  Simulate BG check PASSED"
	@echo "  make demo-bg-fail  Simulate BG check FAILED"
	@echo ""
	@echo "  Tasklist → http://localhost:8080  (demo / demo)"
	@echo ""

init:
	docker-compose up -d
	@echo "Waiting for Camunda..."
	@until curl -sf http://localhost:9600/actuator/health > /dev/null; do sleep 3; printf '.'; done
	@echo ""
	@echo "Ready: http://localhost:8080  (demo/demo)"

up:
	docker-compose up -d

down:
	docker-compose down

nuke:
	docker-compose down -v --remove-orphans
	docker rmi camunda-employee-onboarding-app 2>/dev/null || true
	./mvnw clean -q 2>/dev/null || true

build:
	./mvnw clean package -DskipTests -q

run:
	./mvnw spring-boot:run

logs:
	docker-compose logs -f

ps:
	docker-compose ps

setup-users:
	@bash scripts/setup-users.sh

demo-bg-pass:
	@bash scripts/bg-check.sh pass

demo-bg-fail:
	@bash scripts/bg-check.sh fail

bg-check:
	@bash scripts/bg-check.sh
