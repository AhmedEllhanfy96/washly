#!/bin/bash
# Build all Washly Docker images and push to GitHub Container Registry.
# Run this on your laptop after code changes.
#
# Prerequisites:
#   1. docker login ghcr.io -u YOUR_GITHUB_USERNAME --password YOUR_PAT
#      (PAT needs: write:packages, read:packages)
#   2. Docker running locally (not the build-apk Docker — your regular daemon)
#
# Usage:
#   bash push_images.sh [backend|customer|admin|worker|all]   (default: all)

set -e

REPO_DIR="$(cd "$(dirname "$0")" && pwd)"

# Load .env from repo root
if [ -f "${REPO_DIR}/.env" ]; then
  set -a; source "${REPO_DIR}/.env"; set +a
else
  echo "ERROR: .env file not found at ${REPO_DIR}/.env"
  echo "Copy .env.example to .env and fill in your values."
  exit 1
fi

GITHUB_USER="ahmedellhanfy96"
REPO="washly"
REGISTRY="ghcr.io/${GITHUB_USER}/${REPO}"

TARGET=${1:-all}

build_and_push() {
  local NAME=$1
  local CONTEXT=$2
  local IMAGE="${REGISTRY}/${NAME}:latest"

  echo ""
  echo "=== Building & pushing ${NAME} ==="

  if [ "$NAME" = "backend" ]; then
    docker build -t "$IMAGE" "$CONTEXT"
  else
    docker build \
      --build-arg API_URL="$API_URL" \
      --build-arg WS_URL="$WS_URL" \
      -t "$IMAGE" "$CONTEXT"
  fi

  docker push "$IMAGE"
  echo "✓ ${NAME} → ${IMAGE}"
}

case $TARGET in
  backend)  build_and_push backend  "${REPO_DIR}/backend" ;;
  customer) build_and_push customer-app "${REPO_DIR}/apps/customer_app" ;;
  admin)    build_and_push admin-app    "${REPO_DIR}/apps/admin_app" ;;
  worker)   build_and_push worker-app  "${REPO_DIR}/apps/worker_app" ;;
  all)
    build_and_push backend      "${REPO_DIR}/backend"
    build_and_push customer-app "${REPO_DIR}/apps/customer_app"
    build_and_push admin-app    "${REPO_DIR}/apps/admin_app"
    build_and_push worker-app   "${REPO_DIR}/apps/worker_app"
    ;;
  *) echo "Usage: bash push_images.sh [backend|customer|admin|worker|all]"; exit 1 ;;
esac

echo ""
echo "Done! All images pushed to ${REGISTRY}"
echo "Now SSH into the VM and run: bash vm-deploy.sh"
