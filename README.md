# Washly — On-Demand Car Washing Service

On-demand car washing platform for Egypt. Customers book a wash, admin assigns it to a team member, and workers complete it — all in real time.

## Apps

| App | Description | Web Port | APK |
|-----|-------------|----------|-----|
| **Customer** | Book car washes, track status | `localhost:80` | `washly_customer.apk` |
| **Admin** | Manage bookings, assign workers | `localhost:8081` | `washly_admin.apk` |
| **Worker** | See assigned jobs, start/complete wash | `localhost:8082` | `washly_worker.apk` |

## Project Structure

```
washly/
├── apps/
│   ├── customer_app/   Flutter — customer booking app
│   ├── admin_app/      Flutter — admin dashboard
│   └── worker_app/     Flutter — field worker app
├── backend/            Node.js + Fastify REST API + WebSocket
│   ├── src/
│   │   ├── index.js
│   │   ├── db.js
│   │   ├── ws.js
│   │   └── routes/     auth, bookings, team, slots
│   └── sql/
│       └── init.sql    PostgreSQL schema + seed data
├── nginx/              Reverse proxy config
├── docker-compose.yml  Full stack orchestration
├── build_apk.sh        Build Android APKs via Docker
└── .env.example        Environment variable template
```

## Stack

- **Backend**: Node.js (Fastify) + PostgreSQL 16
- **Real-time**: WebSocket — status changes push instantly to all connected apps
- **Flutter**: Riverpod state management, GoRouter, flutter_map (OpenStreetMap)
- **Auth**: JWT tokens stored in secure storage
- **Containerization**: Docker Compose

## Quick Start

### Prerequisites
- Docker + Docker Compose
- WSL2 (Ubuntu) or any Linux/Mac

### 1. Configure environment

```bash
cp .env.example .env
# Edit .env — set DB_PASSWORD, JWT_SECRET
# For VPS: also set API_URL=http://YOUR_SERVER_IP:3000
```

### 2. Run everything

```bash
sudo docker compose up --build -d
```

Services started:
- `localhost:80` — Customer web app
- `localhost:8081` — Admin web app
- `localhost:8082` — Worker web app
- `localhost:3000` — Backend API + WebSocket

### 3. Default accounts

| Role | Email | Password |
|------|-------|----------|
| Admin | `admin@washly.com` | `admin123` |
| Worker | `worker1@washly.com` | `worker123` |

> Change these in production via the database.

### 4. Build Android APKs

```bash
# Build all 3 APKs (saved to Windows Desktop)
bash build_apk.sh all

# Or build individually
bash build_apk.sh customer
bash build_apk.sh admin
bash build_apk.sh worker
```

For a **physical device** on your WiFi, find your PC's LAN IP first:
```bash
ip addr | grep "192.168"
# Then:
API_URL=http://192.168.x.x:3000 WS_URL=ws://192.168.x.x:3000/ws bash build_apk.sh all
```

## Features

### Customer App
- Email/password registration & login
- Book a wash: car details, map location picker, 2-hour time slots
- Services: Exterior Only (195 EGP) / Full Interior + Exterior (250 EGP)
- Real-time booking status — updates within seconds, no refresh needed
- Booking history

### Admin App
- All bookings dashboard with live status counts
- Approve / reject bookings
- Assign bookings to team members
- Update booking status (confirmed → in progress → completed)
- Team member management (add, toggle availability)
- Map view of customer location
- Copy booking summary to clipboard for WhatsApp/SMS to team

### Worker App
- Login with worker credentials
- Today's jobs highlighted separately from upcoming
- Pull-to-refresh + auto-poll every 30s for new assignments
- Job detail: customer info, car, map, address copy
- One-tap **Start Wash** and **Mark as Done** buttons

## Database Schema

```sql
users          — id, email, password_hash, name, phone, role (customer/admin/worker)
bookings       — id, user_id, customer_name, car (JSONB), service_type, address,
                 lat/lng, scheduled_at, time_slot, status, assigned_to, notes
team_members   — id, name, phone, is_available
```

## Real-time Architecture

```
Admin changes booking status
        ↓
PATCH /bookings/:id/status  →  PostgreSQL update
                            →  WebSocket broadcast to all clients
Customer / Worker app receives { type: "booking_updated", booking: {...} }
                            →  UI updates instantly (< 1 second)
Fallback: REST poll every 30s if WebSocket disconnected
```

## Creating More Worker Accounts

```bash
sudo docker compose exec postgres psql -U washly -c \
  "INSERT INTO users (email, password_hash, name, phone, role)
   VALUES ('worker2@washly.com', crypt('pass123', gen_salt('bf')), 'Mohamed', '01111111111', 'worker');"
```

## VPS Deployment

1. Copy the project to your VPS
2. Edit `.env` — set `API_URL=http://YOUR_VPS_IP:3000` and `WS_URL=ws://YOUR_VPS_IP:3000/ws`
3. Run `sudo docker compose up --build -d`
4. Rebuild APKs with the VPS URL so the mobile apps connect to the server

## License

Private — all rights reserved.
