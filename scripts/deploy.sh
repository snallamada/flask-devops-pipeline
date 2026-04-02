#!/usr/bin/env bash
# =============================================================================
# deploy.sh — Deploy the Flask app using docker-compose
# =============================================================================
set -euo pipefail

PROJECT_ROOT="$(dirname "$0")/.."
COMPOSE_FILE="${PROJECT_ROOT}/docker-compose.yml"

echo "========================================"
echo "  Flask DevOps App — Deploy"
echo "========================================"

# Check compose file exists
if [[ ! -f "${COMPOSE_FILE}" ]]; then
  echo "❌ docker-compose.yml not found at ${COMPOSE_FILE}"
  exit 1
fi

# Pull/build latest images
echo "Building images..."
docker compose -f "${COMPOSE_FILE}" build

# Start services in detached mode
echo "Starting services..."
docker compose -f "${COMPOSE_FILE}" up -d

# Wait for health check to pass
echo ""
echo "Waiting for the app to become healthy..."
MAX_RETRIES=12
RETRY_INTERVAL=5
for i in $(seq 1 $MAX_RETRIES); do
  STATUS=$(curl -s -o /dev/null -w "%{http_code}" http://localhost:5000/health 2>/dev/null || true)
  if [[ "${STATUS}" == "200" ]]; then
    echo "✅ App is healthy! (HTTP ${STATUS})"
    break
  fi
  echo "  Attempt ${i}/${MAX_RETRIES} — HTTP ${STATUS:-unreachable}, retrying in ${RETRY_INTERVAL}s..."
  sleep "${RETRY_INTERVAL}"
done

# Show running containers
echo ""
echo "Running containers:"
docker compose -f "${COMPOSE_FILE}" ps

echo ""
echo "========================================"
echo "  App is live at: http://localhost:5000"
echo "========================================"
