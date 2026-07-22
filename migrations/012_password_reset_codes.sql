-- 012_password_reset_codes.sql
-- Self-service password reset via emailed 6-digit code.
-- Codes are hashed (SHA-256) — DB compromise cannot recover them.
-- Service-role only; no client/anon/authenticated access.

CREATE TABLE IF NOT EXISTS public.password_reset_codes (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  email TEXT NOT NULL,
  code_hash TEXT NOT NULL,
  expires_at TIMESTAMPTZ NOT NULL,
  used_at TIMESTAMPTZ,
  attempts INTEGER NOT NULL DEFAULT 0,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_pwr_email_active
  ON public.password_reset_codes (email, expires_at DESC)
  WHERE used_at IS NULL;

ALTER TABLE public.password_reset_codes ENABLE ROW LEVEL SECURITY;
-- No policies → default deny for anon/authenticated.
-- service_role bypasses RLS, which is what the Netlify functions use.
