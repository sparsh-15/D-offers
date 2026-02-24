-- Extensions
CREATE EXTENSION IF NOT EXISTS pgcrypto;
CREATE EXTENSION IF NOT EXISTS pg_trgm;

-- UUID v7-like function
CREATE OR REPLACE FUNCTION uuid_generate_v7()
RETURNS uuid
LANGUAGE plpgsql
AS $$
DECLARE
  v_unix_ts_ms bigint;
  v_rand bytea;
  v_a text;
  v_b text;
  v_c text;
  v_d text;
  v_e text;
  v_variant text;
BEGIN
  v_unix_ts_ms := floor(extract(epoch FROM clock_timestamp()) * 1000);
  v_rand := gen_random_bytes(10);

  v_a := lpad(to_hex(v_unix_ts_ms), 12, '0');
  v_b := '7' || substr(encode(v_rand, 'hex'), 1, 3);
  v_variant := substr('89ab', (get_byte(v_rand, 2) & 3) + 1, 1);
  v_c := v_variant || substr(encode(v_rand, 'hex'), 4, 3);
  v_d := substr(encode(v_rand, 'hex'), 7, 4);
  v_e := substr(encode(v_rand, 'hex'), 11, 12);

  RETURN (v_a || '-' || v_b || '-' || v_c || '-' || v_d || '-' || v_e)::uuid;
END;
$$;

-- Enums
CREATE TYPE role_enum AS ENUM (
  'super_admin',
  'subadmin',
  'company_sales_agent',
  'ssa',
  'shopkeeper',
  'customer'
);

CREATE TYPE approval_status_enum AS ENUM ('pending', 'approved', 'rejected');
CREATE TYPE offer_status_enum AS ENUM ('active', 'inactive', 'expired');
CREATE TYPE discount_type_enum AS ENUM ('percentage', 'fixed');
CREATE TYPE subscription_status_enum AS ENUM ('active', 'inactive', 'expired', 'cancelled', 'pending');
CREATE TYPE payment_status_enum AS ENUM ('pending', 'paid', 'failed', 'refunded');
CREATE TYPE payment_method_enum AS ENUM ('cash', 'upi', 'card', 'netbanking', 'other');
CREATE TYPE audit_action_enum AS ENUM (
  'user_activated',
  'user_deactivated',
  'user_approved',
  'user_rejected',
  'subscription_created',
  'subscription_updated',
  'subscription_cancelled',
  'subscription_renewed',
  'subscription_plan_created',
  'subscription_plan_updated',
  'subscription_plan_deleted',
  'shop_approved',
  'shop_rejected',
  'coupon_activated',
  'agent_assigned'
);

-- Tables
CREATE TABLE users (
  id uuid PRIMARY KEY DEFAULT uuid_generate_v7(),
  name text NOT NULL DEFAULT '',
  email text,
  phone text NOT NULL,
  password text,
  role role_enum NOT NULL,
  pincode text NOT NULL DEFAULT '',
  city text NOT NULL DEFAULT '',
  state text NOT NULL DEFAULT '',
  region text NOT NULL DEFAULT '',
  territory text NOT NULL DEFAULT '',
  address text NOT NULL DEFAULT '',
  approval_status approval_status_enum NOT NULL DEFAULT 'approved',
  permissions text[] NOT NULL DEFAULT '{}',
  is_active boolean NOT NULL DEFAULT true,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);

CREATE TABLE shopkeeper_profiles (
  id uuid PRIMARY KEY DEFAULT uuid_generate_v7(),
  user_id uuid NOT NULL UNIQUE REFERENCES users(id),
  shop_name text NOT NULL,
  address text,
  pincode text,
  city text,
  category text,
  description text,
  onboarded_by uuid REFERENCES users(id),
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);

CREATE TABLE offers (
  id uuid PRIMARY KEY DEFAULT uuid_generate_v7(),
  shopkeeper_id uuid NOT NULL REFERENCES users(id),
  title text NOT NULL,
  description text,
  photos text[] NOT NULL DEFAULT '{}',
  terms_and_conditions text,
  category text,
  discount_type discount_type_enum NOT NULL DEFAULT 'percentage',
  discount_value numeric(12,2),
  valid_from timestamptz,
  valid_to timestamptz,
  status offer_status_enum NOT NULL DEFAULT 'active',
  likes_count integer NOT NULL DEFAULT 0,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);

CREATE TABLE offer_likes (
  offer_id uuid NOT NULL REFERENCES offers(id) ON DELETE CASCADE,
  user_id uuid NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  created_at timestamptz NOT NULL DEFAULT now(),
  PRIMARY KEY (offer_id, user_id)
);

CREATE TABLE subscription_plans (
  id uuid PRIMARY KEY DEFAULT uuid_generate_v7(),
  name text NOT NULL,
  display_name text NOT NULL,
  description text NOT NULL DEFAULT '',
  monthly_price numeric(12,2) NOT NULL,
  duration_days integer NOT NULL DEFAULT 30,
  category text NOT NULL,
  features text[] NOT NULL DEFAULT '{}',
  max_offers integer NOT NULL DEFAULT -1,
  max_photos_per_offer integer NOT NULL DEFAULT 5,
  analytics_enabled boolean NOT NULL DEFAULT false,
  priority_support boolean NOT NULL DEFAULT false,
  is_active boolean NOT NULL DEFAULT true,
  sort_order integer NOT NULL DEFAULT 0,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);

CREATE TABLE subscription_plan_price_history (
  id uuid PRIMARY KEY DEFAULT uuid_generate_v7(),
  plan_id uuid NOT NULL REFERENCES subscription_plans(id) ON DELETE CASCADE,
  price numeric(12,2) NOT NULL,
  changed_by uuid REFERENCES users(id),
  changed_at timestamptz NOT NULL DEFAULT now(),
  reason text
);

CREATE TABLE subscriptions (
  id uuid PRIMARY KEY DEFAULT uuid_generate_v7(),
  shopkeeper_id uuid NOT NULL REFERENCES users(id),
  plan_id uuid NOT NULL REFERENCES subscription_plans(id),
  plan_snapshot jsonb NOT NULL,
  status subscription_status_enum NOT NULL DEFAULT 'pending',
  start_date timestamptz,
  end_date timestamptz,
  actual_price numeric(12,2) NOT NULL,
  auto_renew boolean NOT NULL DEFAULT false,
  payment_status payment_status_enum NOT NULL DEFAULT 'pending',
  payment_method payment_method_enum,
  transaction_id text,
  coupon_code text,
  discount_amount numeric(12,2) NOT NULL DEFAULT 0,
  renewal_count integer NOT NULL DEFAULT 0,
  last_renewal_date timestamptz,
  cancelled_at timestamptz,
  cancelled_by uuid REFERENCES users(id),
  cancellation_reason text,
  notes text,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);

CREATE TABLE coupons (
  id uuid PRIMARY KEY DEFAULT uuid_generate_v7(),
  code text NOT NULL,
  discount_type discount_type_enum NOT NULL,
  discount_value numeric(12,2) NOT NULL,
  agent_id uuid NOT NULL REFERENCES users(id),
  description text,
  expiry_date timestamptz,
  max_uses integer,
  current_uses integer NOT NULL DEFAULT 0,
  is_active boolean NOT NULL DEFAULT true,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);

CREATE TABLE onboarding_statuses (
  id uuid PRIMARY KEY DEFAULT uuid_generate_v7(),
  user_id uuid NOT NULL UNIQUE REFERENCES users(id),
  business_profile_completed boolean NOT NULL DEFAULT false,
  terms_accepted boolean NOT NULL DEFAULT false,
  terms_accepted_at timestamptz,
  subscription_activated boolean NOT NULL DEFAULT false,
  onboarding_completed boolean NOT NULL DEFAULT false,
  current_step integer NOT NULL DEFAULT 1,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);

CREATE TABLE otps (
  id uuid PRIMARY KEY DEFAULT uuid_generate_v7(),
  phone text NOT NULL,
  otp text NOT NULL,
  expires_at timestamptz NOT NULL,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);

CREATE TABLE audit_logs (
  id uuid PRIMARY KEY DEFAULT uuid_generate_v7(),
  admin_id uuid NOT NULL REFERENCES users(id),
  admin_role role_enum NOT NULL,
  action audit_action_enum NOT NULL,
  target_user_id uuid REFERENCES users(id),
  target_user_role role_enum,
  details jsonb NOT NULL DEFAULT '{}'::jsonb,
  ip_address text,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);

CREATE TABLE mongo_id_map (
  id uuid PRIMARY KEY DEFAULT uuid_generate_v7(),
  collection_name text NOT NULL,
  mongo_id text NOT NULL,
  pg_id uuid NOT NULL,
  created_at timestamptz NOT NULL DEFAULT now(),
  CONSTRAINT uq_mongo_id_map_collection_mongo_id UNIQUE (collection_name, mongo_id)
);

-- Base unique constraints
ALTER TABLE users ADD CONSTRAINT uq_users_phone UNIQUE (phone);
ALTER TABLE subscription_plans ADD CONSTRAINT uq_subscription_plans_name UNIQUE (name);
ALTER TABLE coupons ADD CONSTRAINT uq_coupons_code UNIQUE (code);

-- Indexes: users
CREATE UNIQUE INDEX uq_users_email_non_empty ON users (email) WHERE email IS NOT NULL AND email <> '';
CREATE INDEX idx_users_role_approval_created_desc ON users (role, approval_status, created_at DESC);
CREATE INDEX idx_users_role_active_created_desc ON users (role, is_active, created_at DESC);
CREATE INDEX idx_users_pincode ON users (pincode);
CREATE INDEX idx_users_city ON users (city);
CREATE INDEX idx_users_state ON users (state);
CREATE INDEX idx_users_name_trgm ON users USING gin (name gin_trgm_ops);
CREATE INDEX idx_users_phone_trgm ON users USING gin (phone gin_trgm_ops);

-- Indexes: shopkeeper_profiles
CREATE INDEX idx_shopkeeper_profiles_category ON shopkeeper_profiles (category);
CREATE INDEX idx_shopkeeper_profiles_onboarded_by ON shopkeeper_profiles (onboarded_by);
CREATE INDEX idx_shopkeeper_profiles_pincode ON shopkeeper_profiles (pincode);
CREATE INDEX idx_shopkeeper_profiles_city ON shopkeeper_profiles (city);

-- Indexes: offers
CREATE INDEX idx_offers_shopkeeper_created_desc ON offers (shopkeeper_id, created_at DESC);
CREATE INDEX idx_offers_status_created_desc ON offers (status, created_at DESC);
CREATE INDEX idx_offers_valid_to ON offers (valid_to);
CREATE INDEX idx_offers_category_created_desc ON offers (category, created_at DESC);
CREATE INDEX idx_offers_active_partial ON offers (status, created_at DESC) WHERE status = 'active';

-- Indexes: offer_likes
CREATE INDEX idx_offer_likes_user_created_desc ON offer_likes (user_id, created_at DESC);
CREATE INDEX idx_offer_likes_offer ON offer_likes (offer_id);

-- Indexes: subscription_plans
CREATE INDEX idx_subscription_plans_active_category_sort_price ON subscription_plans (is_active, category, sort_order, monthly_price);
CREATE INDEX idx_subscription_plans_category_active ON subscription_plans (category, is_active);

-- Indexes: subscription_plan_price_history
CREATE INDEX idx_plan_price_history_plan_changed_desc ON subscription_plan_price_history (plan_id, changed_at DESC);

-- Indexes: subscriptions
CREATE INDEX idx_subscriptions_shopkeeper_created_desc ON subscriptions (shopkeeper_id, created_at DESC);
CREATE INDEX idx_subscriptions_status_end_date ON subscriptions (status, end_date);
CREATE INDEX idx_subscriptions_plan_status ON subscriptions (plan_id, status);
CREATE INDEX idx_subscriptions_coupon_code_non_null ON subscriptions (coupon_code) WHERE coupon_code IS NOT NULL;
CREATE INDEX idx_subscriptions_created_desc ON subscriptions (created_at DESC);
CREATE INDEX idx_subscriptions_updated_desc ON subscriptions (updated_at DESC);
CREATE INDEX idx_subscriptions_active_expiry_partial ON subscriptions (status, end_date) WHERE status = 'active';

-- Indexes: coupons
CREATE INDEX idx_coupons_agent_created_desc ON coupons (agent_id, created_at DESC);
CREATE INDEX idx_coupons_active_created_desc ON coupons (is_active, created_at DESC);
CREATE INDEX idx_coupons_expiry_non_null ON coupons (expiry_date) WHERE expiry_date IS NOT NULL;

-- Indexes: onboarding_statuses
CREATE INDEX idx_onboarding_statuses_current_step ON onboarding_statuses (current_step);

-- Indexes: otps
CREATE INDEX idx_otps_phone_created_desc ON otps (phone, created_at DESC);
CREATE INDEX idx_otps_expires_at ON otps (expires_at);

-- Indexes: audit_logs
CREATE INDEX idx_audit_logs_admin_created_desc ON audit_logs (admin_id, created_at DESC);
CREATE INDEX idx_audit_logs_target_created_desc ON audit_logs (target_user_id, created_at DESC);
CREATE INDEX idx_audit_logs_action_created_desc ON audit_logs (action, created_at DESC);
CREATE INDEX idx_audit_logs_created_desc ON audit_logs (created_at DESC);
CREATE INDEX idx_audit_logs_created_at_brin ON audit_logs USING brin (created_at);

-- Indexes: mongo_id_map
CREATE INDEX idx_mongo_id_map_collection ON mongo_id_map (collection_name);
