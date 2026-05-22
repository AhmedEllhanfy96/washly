#!/bin/bash
set -e

APP=${1:-all}   # Usage: bash build_apk.sh [customer|admin|worker|all]

APK_API_URL="${API_URL:-http://10.0.2.2:3000}"
APK_WS_URL="${WS_URL:-ws://10.0.2.2:3000/ws}"
WIN_USER=$(cmd.exe /c "echo %USERNAME%" 2>/dev/null | tr -d '\r')

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
sudo service docker start

build_apk() {
  local NAME=$1
  local APP_DIR="/home/ahmedelhanafy/washly/apps/${NAME}_app"
  local OUT_APK="${APP_DIR}/build/app/outputs/flutter-apk/app-debug.apk"
  local DEST="/mnt/c/Users/${WIN_USER}/Desktop/washly_${NAME}.apk"

  echo ""
  echo "=== Building ${NAME} APK ==="
  sudo rm -rf "${APP_DIR}/.dart_tool" "${APP_DIR}/build" "${APP_DIR}/android/.gradle"
  rm -f "${APP_DIR}/pubspec.lock"

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
           flutter pub get && flutter build apk --debug \
           --dart-define=API_URL=${APK_API_URL} \
           --dart-define=WS_URL=${APK_WS_URL}"

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
echo "Done! APKs are on your Windows Desktop."
echo "NOTE: APKs connect to: ${APK_API_URL}"
echo "      For a physical device on your WiFi, run:"
echo "      API_URL=http://YOUR_PC_LAN_IP:3000 WS_URL=ws://YOUR_PC_LAN_IP:3000/ws bash build_apk.sh"
