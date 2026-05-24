CREATE EXTENSION IF NOT EXISTS "pgcrypto";

CREATE TABLE IF NOT EXISTS users (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  email TEXT UNIQUE NOT NULL,
  password_hash TEXT NOT NULL,
  name TEXT NOT NULL DEFAULT '',
  phone TEXT NOT NULL DEFAULT '',
  role TEXT NOT NULL DEFAULT 'customer',
  created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS bookings (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID REFERENCES users(id) ON DELETE CASCADE,
  customer_name TEXT NOT NULL DEFAULT '',
  customer_phone TEXT NOT NULL DEFAULT '',
  car JSONB NOT NULL DEFAULT '{}',
  service_type TEXT NOT NULL DEFAULT 'exterior_only',
  address TEXT NOT NULL DEFAULT '',
  latitude DOUBLE PRECISION DEFAULT 0,
  longitude DOUBLE PRECISION DEFAULT 0,
  scheduled_at TIMESTAMPTZ NOT NULL,
  time_slot TEXT NOT NULL DEFAULT '',
  status TEXT NOT NULL DEFAULT 'pending',
  assigned_to TEXT,
  notes TEXT DEFAULT '',
  source TEXT NOT NULL DEFAULT 'app',
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

ALTER TABLE bookings ADD COLUMN IF NOT EXISTS source TEXT NOT NULL DEFAULT 'app';

CREATE TABLE IF NOT EXISTS saved_cars (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  make TEXT NOT NULL,
  model TEXT NOT NULL,
  color TEXT NOT NULL,
  plate_number TEXT NOT NULL,
  year TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS saved_locations (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  label TEXT NOT NULL DEFAULT 'Home',
  address TEXT NOT NULL,
  latitude DOUBLE PRECISION NOT NULL DEFAULT 0,
  longitude DOUBLE PRECISION NOT NULL DEFAULT 0,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS team_members (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name TEXT NOT NULL,
  phone TEXT NOT NULL DEFAULT '',
  is_available BOOLEAN DEFAULT TRUE,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE OR REPLACE FUNCTION update_updated_at()
RETURNS TRIGGER AS $$
BEGIN NEW.updated_at = NOW(); RETURN NEW; END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS bookings_updated_at ON bookings;
CREATE TRIGGER bookings_updated_at
  BEFORE UPDATE ON bookings
  FOR EACH ROW EXECUTE FUNCTION update_updated_at();

CREATE TABLE IF NOT EXISTS schedule_config (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  config_date DATE UNIQUE NOT NULL,
  window_duration INT NOT NULL DEFAULT 2,
  capacity_per_window INT NOT NULL DEFAULT 3,
  day_start TIME NOT NULL DEFAULT '08:00',
  day_end TIME NOT NULL DEFAULT '18:00',
  is_closed BOOLEAN NOT NULL DEFAULT FALSE,
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Default admin (password: admin123) — change in production
INSERT INTO users (email, password_hash, name, role)
VALUES ('admin@washly.com', crypt('admin123', gen_salt('bf')), 'Admin', 'admin')
ON CONFLICT (email) DO NOTHING;

-- Example worker account (password: worker123) — add more via admin or direct DB
INSERT INTO users (email, password_hash, name, phone, role)
VALUES ('worker1@washly.com', crypt('worker123', gen_salt('bf')), 'Ahmed Worker', '01000000000', 'worker')
ON CONFLICT (email) DO NOTHING;
