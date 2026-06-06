#!/bin/bash
# Run this script ON THE VM to pull latest images and restart services.
#
# First-time setup on the VM:
#   1. Install Docker:
#        curl -fsSL https://get.docker.com | sh
#        sudo usermod -aG docker $USER   # then re-login
#   2. Login to GitHub Container Registry:
#        docker login ghcr.io -u ahmedellhanfy96 --password YOUR_PAT
#        (PAT needs: read:packages)
#   3. Copy files to the VM:
#        scp docker-compose.vm.yml vm-deploy.sh ssl-init.sh .env user@vm:~/washly/
#        scp -r nginx/ user@vm:~/washly/nginx/
#   4. Get SSL certificate (one time only):
#        bash ssl-init.sh your@email.com
#   5. Run this script:
#        bash vm-deploy.sh

set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

# Load .env — must exist on the VM with real secrets
if [ -f "${SCRIPT_DIR}/.env" ]; then
  set -a; source "${SCRIPT_DIR}/.env"; set +a
else
  echo "ERROR: .env file not found."
  echo "Copy .env.example to .env and fill in your values, then re-run."
  exit 1
fi

GITHUB_USER="ahmedellhanfy96"
REPO="washly"
REGISTRY="ghcr.io/${GITHUB_USER}/${REPO}"

# Support both docker compose (v2 plugin) and docker-compose (v1)
if docker compose version &>/dev/null; then
  COMPOSE="docker compose"
else
  COMPOSE="docker-compose"
fi

echo "=== Pulling latest images ==="
$COMPOSE -f docker-compose.vm.yml pull

echo ""
echo "=== Restarting services ==="
$COMPOSE -f docker-compose.vm.yml down
$COMPOSE -f docker-compose.vm.yml up -d

echo ""
echo "=== Running containers ==="
$COMPOSE -f docker-compose.vm.yml ps

echo ""
echo "Done!"
echo "  Customer web → https://washly.duckdns.org"
echo "  Admin web    → https://washly.duckdns.org:8081"
echo "  Worker web   → https://washly.duckdns.org:8082"
echo "  Backend API  → https://washly.duckdns.org/api"
