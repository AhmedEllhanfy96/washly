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
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
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

-- Default admin (password: admin123) — change in production
INSERT INTO users (email, password_hash, name, role)
VALUES ('admin@washly.com', crypt('admin123', gen_salt('bf')), 'Admin', 'admin')
ON CONFLICT (email) DO NOTHING;

-- Example worker account (password: worker123) — add more via admin or direct DB
INSERT INTO users (email, password_hash, name, phone, role)
VALUES ('worker1@washly.com', crypt('worker123', gen_salt('bf')), 'Ahmed Worker', '01000000000', 'worker')
ON CONFLICT (email) DO NOTHING;
