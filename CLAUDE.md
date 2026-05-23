# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What This Is

Washly is an on-demand car washing platform for Egypt. It is a monorepo with three Flutter web/Android apps (customer, admin, worker), a Node.js/Fastify REST+WebSocket backend, and PostgreSQL 16 — all orchestrated via Docker Compose.

## Common Commands

### Run the full stack (local dev)
```bash
cp .env.example .env          # first time only — set DB_PASSWORD, JWT_SECRET
sudo docker compose up --build -d
```
- Customer app: `localhost:80`
- Admin app: `localhost:8081`
- Worker app: `localhost:8082`
- Backend API + WebSocket: `localhost:3000`

### Run a Flutter app in Chrome (faster iteration than Docker)
```bash
cd apps/admin_app
flutter run -d chrome --dart-define=API_URL=http://localhost:3000
```

### Run backend locally (requires a running Postgres)
```bash
cd backend
npm run dev    # node --watch src/index.js
```

### Database access
```bash
sudo docker compose exec postgres psql -U washly
```

### Build Android APKs (uses Docker internally)
```bash
bash build_apk.sh all          # customer + admin + worker
bash build_apk.sh admin        # single app
```
APKs are saved to Windows Desktop (WSL) or `./apks/` (native Linux).

### Deploy to VPS
```bash
bash push_images.sh   # build & push Docker images to GHCR
bash vm-deploy.sh     # SSH to VPS and pull + restart
```
Production uses `docker-compose.prod.yml` with pre-built images from GHCR.

## Architecture

### Backend (`backend/`)
- **Fastify** (ES modules — `"type": "module"`) with plugins: `@fastify/cors`, `@fastify/jwt`, `@fastify/websocket`
- Routes registered under `/auth`, `/bookings`, `/team`, `/slots`, `/profile`
- `src/ws.js` exports a `broadcast(data)` function — routes call it after any status-changing DB write to push updates to all connected WebSocket clients
- `app.decorate('authenticate', ...)` is the JWT guard; add `preHandler: [app.authenticate]` to protect a route

### Flutter apps (`apps/*/`)
All three apps share the same internal layout:
```
lib/
  core/
    models/       — plain Dart data classes (fromJson/toJson)
    providers/    — Riverpod StateNotifierProviders
    services/     — HTTP (Dio) and WebSocket clients
  features/       — one folder per screen/feature
  shared/
    router/       — GoRouter definition with auth redirect logic
    widgets/      — shared UI components
```

**State management**: Riverpod `StateNotifierProvider` with `AsyncValue<T>` states. The auth notifier (`AdminAuthNotifier` etc.) initialises from secure storage on startup and connects the WebSocket on login.

**Navigation**: GoRouter with a `refreshListenable` wired to the auth provider so routes redirect automatically on sign-in/sign-out.

**Server URL**: Configurable at runtime — stored in `flutter_secure_storage` under key `server_url`. The build-time `--dart-define=API_URL=...` sets the default only if no runtime value is saved. The WS URL is always derived from the API URL (http→ws, https→wss, appended with `/ws`). See `apps/*/lib/core/services/api_client.dart`.

### Real-time flow
1. Admin/worker calls a PATCH/POST endpoint
2. Route handler updates PostgreSQL, then calls `broadcast({ type: "booking_updated", booking: {...} })`
3. All connected Flutter clients receive the message over WebSocket and update Riverpod state
4. 30-second REST poll acts as fallback if WebSocket is disconnected

### Database
PostgreSQL 16. Schema is in `backend/sql/init.sql` (loaded automatically on first container start). Key tables: `users` (role: customer/admin/worker), `bookings` (JSONB `car` field, `status` enum-like text), `team_members`, `saved_cars`, `saved_locations`.

### Environment variables (`.env`)
| Variable | Purpose |
|---|---|
| `DB_PASSWORD` | Postgres password |
| `JWT_SECRET` | JWT signing secret |
| `API_URL` | Backend URL baked into Flutter web builds |
| `WS_URL` | WebSocket URL baked into Flutter web builds |

## Firebase
`firebase/` contains Firestore rules and indexes — the project has Firebase configured but the active backend uses PostgreSQL directly, not Firestore.
