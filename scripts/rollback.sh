#!/usr/bin/env bash
# =============================================================================
# rollback.sh — Stop current container and redeploy a previous image tag
# Usage: ./rollback.sh <previous-image-tag>
# =============================================================================
set -euo pipefail

IMAGE_NAME="flask-devops-app"
PROJECT_ROOT="$(dirname "$0")/.."
COMPOSE_FILE="${PROJECT_ROOT}/docker-compose.yml"

# ── Argument check ────────────────────────────────────────────────────────────
if [[ $# -lt 1 ]]; then
  echo "Usage: $0 <image-tag>"
  echo ""
  echo "Available tags:"
  docker images "${IMAGE_NAME}" --format "  {{.Tag}}\t{{.CreatedAt}}" 2>/dev/null || echo "  No images found"
  exit 1
fi

ROLLBACK_TAG="$1"
FULL_IMAGE="${IMAGE_NAME}:${ROLLBACK_TAG}"

echo "========================================"
echo "  Flask DevOps App — Rollback"
echo "========================================"
echo "  Rolling back to: ${FULL_IMAGE}"
echo "========================================"

# Verify the target image exists
if ! docker image inspect "${FULL_IMAGE}" &>/dev/null; then
  echo "❌ Image '${FULL_IMAGE}' not found locally."
  echo "   Pull it first: docker pull ${FULL_IMAGE}"
  exit 1
fi

# Stop the currently running containers
echo ""
echo "Stopping current containers..."
docker compose -f "${COMPOSE_FILE}" down --remove-orphans

# Update the compose file to use the rollback tag (in-memory via env var)
echo "Redeploying with tag: ${ROLLBACK_TAG}..."
IMAGE_TAG="${ROLLBACK_TAG}" docker compose -f "${COMPOSE_FILE}" up -d

# Wait for the rolled-back version to become healthy
echo ""
echo "Waiting for rolled-back app to become healthy..."
sleep 5
STATUS=$(curl -s -o /dev/null -w "%{http_code}" http://localhost:5000/health 2>/dev/null || true)
if [[ "${STATUS}" == "200" ]]; then
  echo "✅ Rollback successful! App is healthy (HTTP ${STATUS})"
else
  echo "⚠️  App health check returned HTTP ${STATUS:-unreachable}"
  echo "   Check logs: docker compose -f ${COMPOSE_FILE} logs web"
fi

echo ""
echo "Running containers:"
docker compose -f "${COMPOSE_FILE}" ps
