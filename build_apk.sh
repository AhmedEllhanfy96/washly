#!/bin/bash
set -e

APP=${1:-all}   # Usage: bash build_apk.sh [customer|admin|worker|all]
# Server URL is now configured at runtime inside the app (Settings icon on login screen)

# Resolve the repo root relative to this script
REPO_DIR="$(cd "$(dirname "$0")" && pwd)"
APKS_DIR="${REPO_DIR}/apks"

# Detect WSL vs native Linux
is_wsl() { grep -qi microsoft /proc/version 2>/dev/null; }

if is_wsl; then
  WIN_USER=$(cmd.exe /c "echo %USERNAME%" 2>/dev/null | tr -d '\r')
  WIN_DESKTOP="/mnt/c/Users/${WIN_USER}/OneDrive/Desktop"
  if [ ! -d "$WIN_DESKTOP" ]; then
    WIN_DESKTOP="/mnt/c/Users/${WIN_USER}/Desktop"
  fi
  DEST_DIR="$WIN_DESKTOP"
else
  DEST_DIR="$APKS_DIR"
  mkdir -p "$DEST_DIR"
fi

echo "=== Step 1: Install Docker (skip if already installed) ==="
if ! command -v docker &>/dev/null; then
  sudo apt-get update -qq
  sudo apt-get install -y -qq ca-certificates curl
  sudo install -m 0755 -d /etc/apt/keyrings
  sudo curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc
  sudo chmod a+r /etc/apt/keyrings/docker.asc
  echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/ubuntu $(. /etc/os-release && echo "$VERSION_CODENAME") stable" \
    | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
  sudo apt-get update -qq
  sudo apt-get install -y -qq docker-ce docker-ce-cli containerd.io
  sudo usermod -aG docker "$USER"
fi
sudo service docker start 2>/dev/null || true

build_apk() {
  local NAME=$1
  local APP_DIR="${REPO_DIR}/apps/${NAME}_app"
  local OUT_APK="${APP_DIR}/build/app/outputs/flutter-apk/app-release.apk"
  local DEST="${DEST_DIR}/washly_${NAME}.apk"

  echo ""
  echo "=== Building ${NAME} APK ==="
  sudo rm -rf "${APP_DIR}/.dart_tool" "${APP_DIR}/build" "${APP_DIR}/android/.gradle"
  rm -f "${APP_DIR}/pubspec.lock"

  # Wipe stale Gradle wrapper lock/dist from the volume before building
  sudo docker run --rm \
    -v "washly-gradle-${NAME}:/root/.gradle" \
    alpine \
    sh -c "rm -rf /root/.gradle/wrapper/dists 2>/dev/null || true"

  sudo docker run --rm \
    -v "${APP_DIR}:/app" \
    -v washly-android-sdk:/opt/android-sdk-linux \
    -v "washly-gradle-${NAME}:/root/.gradle" \
    -v "washly-pub-${NAME}:/root/.pub-cache" \
    -v washly-android-home:/root/.android \
    --dns 8.8.8.8 --dns 8.8.4.4 \
    -w /app \
    ghcr.io/cirruslabs/flutter:stable \
    sh -c "find /app/android -name '*.lock' -delete 2>/dev/null; \
           rm -f /root/.gradle/caches/journal-1/journal-1.lock; \
           flutter pub get && flutter build apk --release"

  sudo cp "$OUT_APK" "$DEST"
  echo "✓ ${NAME} APK → $DEST"
}

case $APP in
  customer) build_apk customer ;;
  admin)    build_apk admin ;;
  worker)   build_apk worker ;;
  all)
    build_apk customer
    build_apk admin
    build_apk worker
    ;;
  *) echo "Usage: bash build_apk.sh [customer|admin|worker|all]"; exit 1 ;;
esac

echo ""
echo "Done! APKs saved to: ${DEST_DIR}"
echo "NOTE: Server URL is set at runtime — tap the server icon on the login screen."
echo "      Default: http://150.230.53.189:3000 (public VM)"
