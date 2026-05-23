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
#   3. Clone the repo (for docker-compose.prod.yml):
#        git clone https://github.com/AhmedEllhanfy96/washly.git
#        cd washly
#   4. Run this script:
#        bash vm-deploy.sh

set -e

GITHUB_USER="ahmedellhanfy96"
REPO="washly"
REGISTRY="ghcr.io/${GITHUB_USER}/${REPO}"

echo "=== Pulling latest images ==="
docker pull "${REGISTRY}/backend:latest"
docker pull "${REGISTRY}/customer-app:latest"
docker pull "${REGISTRY}/admin-app:latest"
docker pull "${REGISTRY}/worker-app:latest"

echo ""
echo "=== Restarting services ==="
docker compose -f docker-compose.prod.yml down
docker compose -f docker-compose.prod.yml up -d

echo ""
echo "=== Running containers ==="
docker compose -f docker-compose.prod.yml ps

echo ""
echo "Done!"
echo "  Customer web → http://150.230.53.189:80"
echo "  Admin web    → http://150.230.53.189:8081"
echo "  Worker web   → http://150.230.53.189:8082"
echo "  Backend API  → http://150.230.53.189:3000"
