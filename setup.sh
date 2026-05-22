#!/bin/bash
set -e

CYAN='\033[0;36m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo -e "${CYAN}🚗 Washly Project Setup${NC}"
echo "=================================="

# ── Flutter ──────────────────────────────────────────────────────────────────
if ! command -v flutter &>/dev/null; then
  echo -e "${YELLOW}Flutter not found. Installing via snap...${NC}"
  sudo snap install flutter --classic
fi
flutter config --enable-web --no-analytics
echo -e "${GREEN}✓ Flutter ready${NC}"

# ── GitHub CLI ───────────────────────────────────────────────────────────────
if ! command -v gh &>/dev/null; then
  echo -e "${YELLOW}GitHub CLI not found. Installing...${NC}"
  sudo apt-get install -y gh
fi
echo -e "${GREEN}✓ GitHub CLI ready${NC}"

# ── FlutterFire CLI ──────────────────────────────────────────────────────────
if ! command -v flutterfire &>/dev/null; then
  echo -e "${YELLOW}Installing FlutterFire CLI...${NC}"
  dart pub global activate flutterfire_cli
fi
echo -e "${GREEN}✓ FlutterFire CLI ready${NC}"

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

# ── Customer App ─────────────────────────────────────────────────────────────
echo ""
echo -e "${CYAN}Creating customer app...${NC}"
CUSTOMER_DIR="$SCRIPT_DIR/apps/customer_app"
CUSTOMER_TMP="$SCRIPT_DIR/apps/_customer_src_backup"

# Back up our source
cp -r "$CUSTOMER_DIR/lib" "$CUSTOMER_TMP" 2>/dev/null || true
cp "$CUSTOMER_DIR/pubspec.yaml" "$CUSTOMER_TMP/pubspec.yaml" 2>/dev/null || true

# Generate Flutter scaffold
flutter create \
  --org com.washly \
  --project-name washly_customer \
  --platforms android,ios,web \
  "$CUSTOMER_DIR"

# Restore our source
cp -r "$CUSTOMER_TMP/." "$CUSTOMER_DIR/"
rm -rf "$CUSTOMER_TMP"

cd "$CUSTOMER_DIR"
flutter pub get
echo -e "${GREEN}✓ Customer app ready${NC}"

# ── Admin App ─────────────────────────────────────────────────────────────────
echo ""
echo -e "${CYAN}Creating admin app...${NC}"
ADMIN_DIR="$SCRIPT_DIR/apps/admin_app"
ADMIN_TMP="$SCRIPT_DIR/apps/_admin_src_backup"

cp -r "$ADMIN_DIR/lib" "$ADMIN_TMP" 2>/dev/null || true
cp "$ADMIN_DIR/pubspec.yaml" "$ADMIN_TMP/pubspec.yaml" 2>/dev/null || true

flutter create \
  --org com.washly \
  --project-name washly_admin \
  --platforms android,ios,web \
  "$ADMIN_DIR"

cp -r "$ADMIN_TMP/." "$ADMIN_DIR/"
rm -rf "$ADMIN_TMP"

cd "$ADMIN_DIR"
flutter pub get
echo -e "${GREEN}✓ Admin app ready${NC}"

# ── Git ───────────────────────────────────────────────────────────────────────
cd "$SCRIPT_DIR"
if [ ! -d .git ]; then
  git init
  git add .
  git commit -m "feat: initial Washly project scaffold"
fi

# ── GitHub repo ───────────────────────────────────────────────────────────────
echo ""
echo -e "${CYAN}Creating GitHub repository...${NC}"
if ! gh auth status &>/dev/null; then
  echo -e "${YELLOW}Please log in to GitHub:${NC}"
  gh auth login
fi

gh repo create washly \
  --public \
  --description "On-demand car washing service — Flutter + Firebase" \
  --source=. \
  --remote=origin \
  --push || echo -e "${YELLOW}Repo may already exist — pushing to existing remote${NC}" && git push -u origin main

echo ""
echo -e "${GREEN}✅ All done!${NC}"
echo ""
echo "Next steps:"
echo "  1. Create Firebase project at https://console.firebase.google.com"
echo "  2. Enable Authentication (Phone + Email/Password), Firestore, Cloud Messaging"
echo "  3. cd apps/customer_app && flutterfire configure"
echo "  4. cd apps/admin_app   && flutterfire configure"
echo "  5. firebase deploy --only firestore"
echo "  6. flutter run"
