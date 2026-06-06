#!/bin/bash
# One-time SSL certificate initialization using Let's Encrypt.
# Run this ONCE on the VM after first deploying with HTTP-only.
#
# Usage: bash ssl-init.sh your@email.com

set -e

DOMAIN="washly.duckdns.org"
EMAIL="${1:-}"

if [ -z "$EMAIL" ]; then
  echo "Usage: bash ssl-init.sh your@email.com"
  exit 1
fi

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

echo "=== Washly SSL init for $DOMAIN ==="

# 1. Create directories
mkdir -p "${SCRIPT_DIR}/nginx/certbot/conf"
mkdir -p "${SCRIPT_DIR}/nginx/certbot/www"

# 2. Start only the services needed for HTTP challenge (no nginx yet)
#    Use a temporary HTTP-only nginx config so certbot challenge can be served
cat > /tmp/nginx-init.conf << 'EOF'
events { worker_connections 256; }
http {
  server {
    listen 80;
    server_name washly.duckdns.org;
    location /.well-known/acme-challenge/ {
      root /var/www/certbot;
    }
    location / {
      return 200 'Washly SSL init in progress...';
      add_header Content-Type text/plain;
    }
  }
}
EOF

echo "→ Starting temporary HTTP nginx for ACME challenge..."
docker run -d --rm --name washly-ssl-init \
  -p 80:80 \
  -v /tmp/nginx-init.conf:/etc/nginx/nginx.conf:ro \
  -v "${SCRIPT_DIR}/nginx/certbot/www:/var/www/certbot" \
  nginx:alpine

sleep 2

echo "→ Requesting Let's Encrypt certificate for $DOMAIN..."
docker run --rm \
  -v "${SCRIPT_DIR}/nginx/certbot/conf:/etc/letsencrypt" \
  -v "${SCRIPT_DIR}/nginx/certbot/www:/var/www/certbot" \
  certbot/certbot certonly \
    --webroot \
    --webroot-path=/var/www/certbot \
    --email "$EMAIL" \
    --agree-tos \
    --no-eff-email \
    -d "$DOMAIN"

echo "→ Stopping temporary nginx..."
docker stop washly-ssl-init

echo "→ Certificate obtained! Files are in ${SCRIPT_DIR}/nginx/certbot/conf/live/${DOMAIN}/"
echo ""
echo "✓ Done. Now restart the full stack:"
echo "  sudo docker compose -f docker-compose.prod.yml up -d"
