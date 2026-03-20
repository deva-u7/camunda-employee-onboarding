#!/usr/bin/env bash
# bg-check.sh — Simulate background check result
# Usage:
#   ./scripts/bg-check.sh              (interactive)
#   ./scripts/bg-check.sh pass <email>
#   ./scripts/bg-check.sh fail <email> [reason]

APP_URL="http://localhost:8081/api/onboarding/background-check-result"
MODE="${1:-}" EMAIL="${2:-}" DETAILS="${3:-}"

echo ""
echo "=== Background Check Simulator ==="
echo ""

[ -z "$EMAIL" ] && read -p "  Employee email : " EMAIL

if [ "$MODE" = "pass" ]; then
  PASSED="true"; [ -z "$DETAILS" ] && DETAILS="All checks passed"
elif [ "$MODE" = "fail" ]; then
  PASSED="false"
  if [ -z "$DETAILS" ]; then read -p "  Failure reason : " DETAILS; [ -z "$DETAILS" ] && DETAILS="Criminal record found"; fi
else
  echo "  [1] PASS  [2] FAIL"
  read -p "  Choose (1/2)   : " CHOICE
  if [ "$CHOICE" = "2" ]; then
    PASSED="false"; read -p "  Failure reason : " DETAILS; [ -z "$DETAILS" ] && DETAILS="Criminal record found"
  else
    PASSED="true"; [ -z "$DETAILS" ] && DETAILS="All checks passed"
  fi
fi

echo ""
echo "  Sending → passed=${PASSED}, email=${EMAIL}"
echo ""

RESP=$(curl -s -X POST "$APP_URL" \
  -H "Content-Type: application/json" \
  -d "{\"employeeEmail\":\"${EMAIL}\",\"passed\":${PASSED},\"details\":\"${DETAILS}\"}")

echo "$RESP" | python3 -m json.tool 2>/dev/null || echo "$RESP"
echo ""
[ "$PASSED" = "true" ] && echo "  ✓ PASSED — continues to HR Approval + IT Setup" || echo "  ✗ FAILED — routes to rejection"
echo ""
