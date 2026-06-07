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

CREATE TABLE IF NOT EXISTS app_settings (
  key TEXT PRIMARY KEY,
  value JSONB NOT NULL,
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

INSERT INTO app_settings (key, value) VALUES
  ('price_exterior_only', '195'),
  ('price_interior_only', '220'),
  ('price_full_service',  '250'),
  ('instapay_number',     '""'),
  ('instapay_link',       '""'),
  ('support_phone',       '""')
ON CONFLICT (key) DO NOTHING;

-- Payment tracking on bookings
ALTER TABLE bookings ADD COLUMN IF NOT EXISTS payment_method TEXT NOT NULL DEFAULT 'cash';
ALTER TABLE bookings ADD COLUMN IF NOT EXISTS payment_status TEXT NOT NULL DEFAULT 'pending';

-- Worker wallet (money workers owe to company after collecting from customers)
CREATE TABLE IF NOT EXISTS worker_wallet (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  worker_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  booking_id UUID UNIQUE REFERENCES bookings(id) ON DELETE SET NULL,
  amount INTEGER NOT NULL,
  payment_method TEXT NOT NULL DEFAULT 'cash',
  status TEXT NOT NULL DEFAULT 'pending',
  note TEXT NOT NULL DEFAULT '',
  settled_at TIMESTAMPTZ,
  settled_by UUID REFERENCES users(id),
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Company wallet — money received by the company
-- source: 'instapay' (customer paid digitally) | 'cash_collected' (collected from worker)
CREATE TABLE IF NOT EXISTS company_wallet (
  id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  source      TEXT NOT NULL,
  booking_id  UUID REFERENCES bookings(id) ON DELETE SET NULL,
  worker_id   UUID REFERENCES users(id)   ON DELETE SET NULL,
  amount      INTEGER NOT NULL,
  note        TEXT NOT NULL DEFAULT '',
  created_at  TIMESTAMPTZ DEFAULT NOW()
);
-- Prevent double-entry for the same booking+source combo
CREATE UNIQUE INDEX IF NOT EXISTS company_wallet_booking_source
  ON company_wallet (booking_id, source) WHERE booking_id IS NOT NULL;

CREATE TABLE IF NOT EXISTS password_reset_tokens (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  token TEXT UNIQUE NOT NULL,
  expires_at TIMESTAMPTZ NOT NULL,
  used BOOLEAN NOT NULL DEFAULT FALSE,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Services catalog — source of truth for prices and what's offered
-- category: 'wash' (main services) | 'addon' (future pay items)
CREATE TABLE IF NOT EXISTS services (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  key TEXT UNIQUE NOT NULL,
  name TEXT NOT NULL,
  description TEXT NOT NULL DEFAULT '',
  price INTEGER NOT NULL DEFAULT 0,
  is_active BOOLEAN DEFAULT true,
  sort_order INTEGER DEFAULT 0,
  category TEXT NOT NULL DEFAULT 'wash',
  image_url TEXT NOT NULL DEFAULT '',
  features JSONB NOT NULL DEFAULT '[]',
  badge TEXT NOT NULL DEFAULT '',
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

DROP TRIGGER IF EXISTS services_updated_at ON services;
CREATE TRIGGER services_updated_at
  BEFORE UPDATE ON services
  FOR EACH ROW EXECUTE FUNCTION update_updated_at();

INSERT INTO services (key, name, description, price, sort_order, features, badge) VALUES
  ('exterior_only', 'Exterior Only', 'Complete exterior wash and shine', 195, 1,
   '["Exterior Wash","Wheel Cleaning","Towel Dry","Window Cleaning"]', ''),
  ('interior_only', 'Interior Only', 'Deep interior cleaning and refresh', 220, 2,
   '["Vacuum","Dashboard Wipe","Window Interior","Air Freshener"]', ''),
  ('full_service',  'Full Service',  'Complete inside and outside wash',  250, 3,
   '["Exterior Wash","Wheel Cleaning","Vacuum","Dashboard Wipe","Window Interior","Air Freshener"]', 'BEST VALUE')
ON CONFLICT (key) DO NOTHING;

-- Promo codes with percentage discounts on wash services
CREATE TABLE IF NOT EXISTS promos (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  code TEXT UNIQUE NOT NULL,
  discount_percent INTEGER NOT NULL CHECK (discount_percent > 0 AND discount_percent <= 100),
  valid_from TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  valid_until TIMESTAMPTZ NOT NULL,
  is_active BOOLEAN DEFAULT true,
  max_uses INTEGER DEFAULT NULL,
  max_uses_per_user INTEGER DEFAULT NULL,
  used_count INTEGER DEFAULT 0,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

ALTER TABLE promos ADD COLUMN IF NOT EXISTS max_uses_per_user INTEGER DEFAULT NULL;

-- Per-user promo usage tracking
CREATE TABLE IF NOT EXISTS promo_uses (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  promo_id UUID NOT NULL REFERENCES promos(id) ON DELETE CASCADE,
  user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  booking_id UUID REFERENCES bookings(id) ON DELETE SET NULL,
  used_at TIMESTAMPTZ DEFAULT NOW()
);

-- Promo tracking on bookings
ALTER TABLE bookings ADD COLUMN IF NOT EXISTS promo_code TEXT DEFAULT NULL;
ALTER TABLE bookings ADD COLUMN IF NOT EXISTS discount_percent INTEGER DEFAULT 0;
ALTER TABLE bookings ADD COLUMN IF NOT EXISTS original_price INTEGER DEFAULT 0;

-- Default admin (password: admin123) — change in production
INSERT INTO users (email, password_hash, name, role)
VALUES ('admin@washly.com', crypt('admin123', gen_salt('bf')), 'Admin', 'admin')
ON CONFLICT (email) DO NOTHING;

-- Example worker account (password: worker123) — add more via admin or direct DB
INSERT INTO users (email, password_hash, name, phone, role)
VALUES ('worker1@washly.com', crypt('worker123', gen_salt('bf')), 'Ahmed Worker', '01000000000', 'worker')
ON CONFLICT (email) DO NOTHING;
