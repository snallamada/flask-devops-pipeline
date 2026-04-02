#!/usr/bin/env bash
# =============================================================================
# cleanup.sh — Stop all containers, remove dangling images and volumes
# Usage: ./cleanup.sh [--all]
#   --all  : also remove named volumes and the flask-devops-app images
# =============================================================================
set -euo pipefail

PROJECT_ROOT="$(dirname "$0")/.."
COMPOSE_FILE="${PROJECT_ROOT}/docker-compose.yml"
MONITORING_COMPOSE="${PROJECT_ROOT}/monitoring/docker-compose.monitoring.yml"
REMOVE_ALL="${1:-}"

echo "========================================"
echo "  Flask DevOps App — Cleanup"
echo "========================================"

# ── Stop compose services ────────────────────────────────────────────────────
if [[ -f "${COMPOSE_FILE}" ]]; then
  echo "Stopping app containers..."
  docker compose -f "${COMPOSE_FILE}" down --remove-orphans ${REMOVE_ALL:+--volumes} 2>/dev/null || true
fi

if [[ -f "${MONITORING_COMPOSE}" ]]; then
  echo "Stopping monitoring containers..."
  docker compose -f "${MONITORING_COMPOSE}" down --remove-orphans ${REMOVE_ALL:+--volumes} 2>/dev/null || true
fi

# ── Remove dangling images ────────────────────────────────────────────────────
echo ""
echo "Removing dangling (untagged) images..."
DANGLING=$(docker images -f "dangling=true" -q 2>/dev/null)
if [[ -n "${DANGLING}" ]]; then
  docker rmi ${DANGLING}
  echo "  Removed $(echo "${DANGLING}" | wc -l | tr -d ' ') dangling image(s)."
else
  echo "  No dangling images found."
fi

# ── Remove app images if --all ────────────────────────────────────────────────
if [[ "${REMOVE_ALL}" == "--all" ]]; then
  echo ""
  echo "Removing flask-devops-app images..."
  docker images "flask-devops-app" -q | xargs -r docker rmi -f && \
    echo "  flask-devops-app images removed." || \
    echo "  No flask-devops-app images to remove."
fi

# ── Remove dangling volumes ──────────────────────────────────────────────────
echo ""
echo "Removing dangling volumes..."
docker volume prune -f
echo ""

# ── Remove unused networks ────────────────────────────────────────────────────
echo "Removing unused networks..."
docker network prune -f
echo ""

echo "========================================"
echo "✅ Cleanup complete!"
if [[ "${REMOVE_ALL}" == "--all" ]]; then
  echo "   All resources removed (--all flag used)."
else
  echo "   Tip: run with --all to also remove named volumes and app images."
fi
echo "========================================"
