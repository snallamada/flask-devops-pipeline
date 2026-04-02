#!/usr/bin/env bash
# =============================================================================
# health-check.sh — Continuously poll /health every 5 seconds
# Usage: ./health-check.sh [host] [port]
#   Default: localhost:5000
# Press Ctrl+C to stop.
# =============================================================================
set -euo pipefail

HOST="${1:-localhost}"
PORT="${2:-5000}"
ENDPOINT="http://${HOST}:${PORT}/health"
INTERVAL=5

echo "========================================"
echo "  Flask Health Monitor"
echo "  Endpoint : ${ENDPOINT}"
echo "  Interval : ${INTERVAL}s"
echo "  Press Ctrl+C to stop"
echo "========================================"
echo ""

# Track consecutive failures for alerting
FAIL_COUNT=0
MAX_FAILS=3

while true; do
  TIMESTAMP=$(date '+%Y-%m-%d %H:%M:%S')

  # Make the request; capture HTTP code and body
  HTTP_CODE=$(curl -s -o /tmp/health_body.txt -w "%{http_code}" \
    --connect-timeout 3 --max-time 5 "${ENDPOINT}" 2>/dev/null || echo "000")
  BODY=$(cat /tmp/health_body.txt 2>/dev/null || echo "")

  if [[ "${HTTP_CODE}" == "200" ]]; then
    echo "[${TIMESTAMP}] ✅ HEALTHY   HTTP ${HTTP_CODE}  — ${BODY}"
    FAIL_COUNT=0
  else
    FAIL_COUNT=$((FAIL_COUNT + 1))
    echo "[${TIMESTAMP}] ❌ UNHEALTHY HTTP ${HTTP_CODE}  — ${BODY:-no response}"

    if [[ ${FAIL_COUNT} -ge ${MAX_FAILS} ]]; then
      echo ""
      echo "⚠️  ALERT: ${FAIL_COUNT} consecutive failures detected!"
      echo "   Check: docker compose ps"
      echo "   Logs : docker compose logs web --tail=50"
      echo ""
    fi
  fi

  sleep "${INTERVAL}"
done
