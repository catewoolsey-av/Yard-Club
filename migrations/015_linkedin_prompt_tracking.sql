-- 015_linkedin_prompt_tracking.sql
-- Persist the "Connect LinkedIn" prompt's skip/dismiss decision to the member's
-- own row instead of localStorage, so it holds across devices/browsers the same
-- way the disclosure acknowledgements do (see 013_member_disclosures.sql).

ALTER TABLE members
  ADD COLUMN IF NOT EXISTS linkedin_prompt_skipped_at TIMESTAMPTZ,
  ADD COLUMN IF NOT EXISTS linkedin_prompt_dismissed_at TIMESTAMPTZ;
