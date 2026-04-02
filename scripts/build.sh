#!/usr/bin/env bash
# =============================================================================
# build.sh — Build the Flask Docker image tagged with the git commit SHA
# =============================================================================
set -euo pipefail

# ── Configuration ─────────────────────────────────────────────────────────────
IMAGE_NAME="flask-devops-app"
DOCKERFILE_PATH="$(dirname "$0")/.."

# Get the current git commit SHA (short form)
GIT_SHA=$(git -C "$DOCKERFILE_PATH" rev-parse --short HEAD 2>/dev/null || echo "local")
TIMESTAMP=$(date +"%Y%m%d%H%M%S")
FULL_TAG="${IMAGE_NAME}:${GIT_SHA}"
LATEST_TAG="${IMAGE_NAME}:latest"

# ── Banner ────────────────────────────────────────────────────────────────────
echo "========================================"
echo "  Flask DevOps App — Docker Build"
echo "========================================"
echo "  Image name : ${FULL_TAG}"
echo "  Git SHA    : ${GIT_SHA}"
echo "  Timestamp  : ${TIMESTAMP}"
echo "========================================"

# ── Build ─────────────────────────────────────────────────────────────────────
echo ""
echo "Building Docker image..."
docker build \
  --tag "${FULL_TAG}" \
  --tag "${LATEST_TAG}" \
  --build-arg BUILD_DATE="${TIMESTAMP}" \
  --build-arg GIT_SHA="${GIT_SHA}" \
  --file "${DOCKERFILE_PATH}/Dockerfile" \
  "${DOCKERFILE_PATH}"

# ── Summary ───────────────────────────────────────────────────────────────────
echo ""
echo "✅ Build complete!"
echo "   Tagged as: ${FULL_TAG}"
echo "   Tagged as: ${LATEST_TAG}"
echo ""
echo "Run with:"
echo "   docker run -p 5000:5000 ${FULL_TAG}"
