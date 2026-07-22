-- 013_deals_archived.sql
-- Lets admins archive a deal to declutter the Manage Deals list without
-- touching anything else (deal_interests, portfolio_investments, etc. are
-- untouched — this is purely a visibility flag on the deals row itself).

ALTER TABLE deals
  ADD COLUMN IF NOT EXISTS archived_at TIMESTAMPTZ;
