#!/usr/bin/env bash
# setup-users.sh — Creates groups, assigns users, and configures authorizations
# Run after: make up

CAMUNDA_URL="http://localhost:8080"
ADMIN_USER="demo"
ADMIN_PASS="demo"

echo ""
echo "=== Camunda User & Authorization Setup ==="
echo ""

api() {
  curl -s -u "${ADMIN_USER}:${ADMIN_PASS}" -H "Content-Type: application/json" "$@"
}

authz() {
  local OWNER_ID="$1" OWNER_TYPE="$2" RESOURCE_TYPE="$3" RESOURCE_ID="$4" PERMISSIONS="$5"
  RESP=$(api -X POST "${CAMUNDA_URL}/v2/authorizations" \
    -d "{\"ownerId\":\"${OWNER_ID}\",\"ownerType\":\"${OWNER_TYPE}\",\"resourceType\":\"${RESOURCE_TYPE}\",\"resourceId\":\"${RESOURCE_ID}\",\"permissionTypes\":${PERMISSIONS}}")
  echo "$RESP" | grep -q '"authorizationKey"' \
    && echo "  ✓ ${OWNER_ID} → ${RESOURCE_TYPE}/${RESOURCE_ID}" \
    || echo "  ~ ${OWNER_ID} → ${RESOURCE_TYPE}/${RESOURCE_ID} (exists)"
}

echo "1. Creating groups..."
for G in "hr-managers|HR Managers" "it-team|IT Team" "employees|Employees"; do
  GID="${G%%|*}"; GNAME="${G##*|}"
  RESP=$(api -X POST "${CAMUNDA_URL}/v2/groups" -d "{\"groupId\":\"${GID}\",\"name\":\"${GNAME}\"}")
  echo "$RESP" | grep -q '"groupId"' && echo "  ✓ ${GID}" || echo "  ~ ${GID} exists"
done
echo ""

echo "2. Assigning users..."
api -X PUT "${CAMUNDA_URL}/v2/groups/hr-managers/users/hr.manager" > /dev/null && echo "  ✓ hr.manager → hr-managers"
api -X PUT "${CAMUNDA_URL}/v2/groups/it-team/users/it.support"     > /dev/null && echo "  ✓ it.support → it-team"
api -X PUT "${CAMUNDA_URL}/v2/groups/employees/users/new.employee"  > /dev/null && echo "  ✓ new.employee → employees"
echo ""

echo "3. Authorizations..."
echo ""
echo "  [demo]"
authz "demo" "USER" "COMPONENT"           "tasklist"  '["ACCESS"]'
authz "demo" "USER" "COMPONENT"           "operate"   '["ACCESS"]'
authz "demo" "USER" "COMPONENT"           "identity"  '["ACCESS"]'
authz "demo" "USER" "PROCESS_DEFINITION"  "*"         '["CREATE_PROCESS_INSTANCE","READ_PROCESS_DEFINITION","READ_PROCESS_INSTANCE","READ_USER_TASK","UPDATE_USER_TASK","UPDATE_PROCESS_INSTANCE","CANCEL_PROCESS_INSTANCE","DELETE_PROCESS_INSTANCE"]'
authz "demo" "USER" "DECISION_DEFINITION" "*"         '["CREATE_DECISION_INSTANCE","READ_DECISION_DEFINITION","READ_DECISION_INSTANCE"]'
authz "demo" "USER" "DEPLOYMENT"          "*"         '["CREATE","READ","DELETE"]'
authz "demo" "USER" "USER"                "*"         '["CREATE","READ","UPDATE","DELETE"]'
authz "demo" "USER" "GROUP"               "*"         '["CREATE","READ","UPDATE","DELETE"]'
authz "demo" "USER" "AUTHORIZATION"       "*"         '["CREATE","READ","UPDATE","DELETE"]'
echo ""
echo "  [hr-managers / hr.manager]"
authz "hr-managers" "GROUP" "COMPONENT"          "tasklist"             '["ACCESS"]'
authz "hr-managers" "GROUP" "PROCESS_DEFINITION" "employee-onboarding" '["READ_USER_TASK","UPDATE_USER_TASK"]'
authz "hr.manager"  "USER"  "COMPONENT"          "tasklist"             '["ACCESS"]'
authz "hr.manager"  "USER"  "PROCESS_DEFINITION" "employee-onboarding" '["READ_USER_TASK","UPDATE_USER_TASK"]'
echo ""
echo "  [it-team / it.support]"
authz "it-team"    "GROUP" "COMPONENT"          "tasklist"         '["ACCESS"]'
authz "it-team"    "GROUP" "PROCESS_DEFINITION" "it-account-setup" '["READ_PROCESS_DEFINITION","READ_PROCESS_INSTANCE","READ_USER_TASK","UPDATE_USER_TASK"]'
authz "it.support" "USER"  "COMPONENT"          "tasklist"         '["ACCESS"]'
authz "it.support" "USER"  "PROCESS_DEFINITION" "it-account-setup" '["READ_USER_TASK","UPDATE_USER_TASK"]'
echo ""
echo "  [employees / new.employee]"
authz "employees"    "GROUP" "COMPONENT"          "tasklist"             '["ACCESS"]'
authz "employees"    "GROUP" "PROCESS_DEFINITION" "employee-onboarding" '["CREATE_PROCESS_INSTANCE","READ_PROCESS_DEFINITION","READ_PROCESS_INSTANCE","READ_USER_TASK","UPDATE_USER_TASK"]'
authz "new.employee" "USER"  "COMPONENT"          "tasklist"             '["ACCESS"]'
authz "new.employee" "USER"  "PROCESS_DEFINITION" "employee-onboarding" '["CREATE_PROCESS_INSTANCE","READ_PROCESS_DEFINITION","READ_PROCESS_INSTANCE","READ_USER_TASK","UPDATE_USER_TASK"]'
echo ""

echo "=== Done ==="
echo ""
printf "  %-14s %-22s %s\n" "ROLE" "LOGIN" "TASKS"
echo "  ──────────────────────────────────────────────────"
printf "  %-14s %-22s %s\n" "Admin"        "demo / demo"          "Everything"
printf "  %-14s %-22s %s\n" "HR Manager"   "hr.manager / hr123"   "HR Approval"
printf "  %-14s %-22s %s\n" "IT Support"   "it.support / it123"   "Manual IT Setup"
printf "  %-14s %-22s %s\n" "New Employee" "new.employee / emp123" "Start + Training"
echo ""
echo "  http://localhost:8080"
echo ""
