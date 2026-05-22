# Washly — On-Demand Car Washing Service

Mobile app + web portal for booking car washes at your home or office.

## Project Structure

```
washly/
├── apps/
│   ├── customer_app/   # Flutter app for customers (iOS, Android, Web)
│   └── admin_app/      # Flutter app for admin & team (iOS, Android, Web)
├── firebase/
│   ├── firestore.rules
│   └── firestore.indexes.json
└── setup.sh            # One-command project bootstrap
```

## Quick Start

### Prerequisites
- Flutter SDK (`sudo snap install flutter --classic`)
- GitHub CLI (`sudo apt-get install gh`)
- Firebase account — https://console.firebase.google.com
- FlutterFire CLI (`dart pub global activate flutterfire_cli`)

### 1. Bootstrap the project

```bash
chmod +x setup.sh
./setup.sh
```

### 2. Create Firebase project

1. Go to https://console.firebase.google.com
2. Create project named **washly**
3. Enable: Authentication (Phone + Email), Firestore, Cloud Messaging
4. For each app:
   ```bash
   cd apps/customer_app && flutterfire configure
   cd apps/admin_app && flutterfire configure
   ```

### 3. Deploy Firestore rules

```bash
firebase deploy --only firestore
```

### 4. Run the apps

```bash
# Customer app
cd apps/customer_app && flutter run

# Admin app
cd apps/admin_app && flutter run
```

## Features

### Customer App
- Phone / email authentication
- Book a wash: car details, service type, location, time slot
- Service types: Exterior Only / Full Interior + Exterior
- Real-time booking status tracking
- Push notifications for booking updates

### Admin App
- View all pending / confirmed bookings
- Approve or reject booking requests
- Assign bookings to team members
- Update booking status through the workflow
- Team member management

## Firestore Data Model

```
users/{userId}
bookings/{bookingId}
team_members/{memberId}
time_slots/{date}
```
