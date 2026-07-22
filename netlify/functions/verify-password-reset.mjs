import { createClient } from '@supabase/supabase-js';
import { createHash } from 'crypto';

const MAX_ATTEMPTS = 5;
const MIN_PASSWORD_LEN = 6;

const hashCode = (code) => createHash('sha256').update(String(code)).digest('hex');

// Generic error string — never tell the caller *why* (anti-enumeration)
const GENERIC = JSON.stringify({ error: 'Invalid or expired code' });

export const handler = async (event) => {
  if (event.httpMethod !== 'POST') {
    return { statusCode: 405, body: JSON.stringify({ error: 'Method not allowed' }) };
  }
  let body;
  try { body = JSON.parse(event.body || '{}'); }
  catch { return { statusCode: 400, body: JSON.stringify({ error: 'Invalid JSON' }) }; }

  const email = String(body.email || '').trim().toLowerCase();
  const code = String(body.code || '').trim();
  const newPassword = String(body.newPassword || '');

  if (!email || !/^\d{6}$/.test(code) || newPassword.length < MIN_PASSWORD_LEN) {
    return { statusCode: 400, body: JSON.stringify({ error: `Password must be at least ${MIN_PASSWORD_LEN} characters and code must be 6 digits` }) };
  }

  const svc = createClient(process.env.SUPABASE_URL, process.env.SUPABASE_SERVICE_ROLE_KEY);

  // Look up the latest active code for this email
  const { data: row } = await svc
    .from('password_reset_codes')
    .select('id, code_hash, expires_at, attempts')
    .eq('email', email)
    .is('used_at', null)
    .gt('expires_at', new Date().toISOString())
    .order('created_at', { ascending: false })
    .limit(1)
    .maybeSingle();
  if (!row) return { statusCode: 400, body: GENERIC };

  // Too many attempts → invalidate and reject
  if (row.attempts >= MAX_ATTEMPTS) {
    await svc.from('password_reset_codes').update({ used_at: new Date().toISOString() }).eq('id', row.id);
    return { statusCode: 400, body: GENERIC };
  }

  // Constant-time-ish comparison via hash
  if (row.code_hash !== hashCode(code)) {
    await svc.from('password_reset_codes').update({ attempts: row.attempts + 1 }).eq('id', row.id);
    return { statusCode: 400, body: GENERIC };
  }

  // Code is valid. Find the auth user via member.auth_user_id.
  const { data: member } = await svc
    .from('members')
    .select('id, auth_user_id')
    .ilike('email', email)
    .maybeSingle();
  if (!member?.auth_user_id) return { statusCode: 400, body: GENERIC };

  // Reset the password through Auth admin (bypasses RLS, no JWT needed)
  const { error: upErr } = await svc.auth.admin.updateUserById(member.auth_user_id, { password: newPassword });
  if (upErr) {
    console.error('updateUserById failed:', upErr.message);
    return { statusCode: 500, body: JSON.stringify({ error: 'Could not update password' }) };
  }

  // Clear must_change_password if set
  await svc.from('members').update({ must_change_password: false }).eq('id', member.id);

  // Burn the code
  await svc.from('password_reset_codes').update({ used_at: new Date().toISOString() }).eq('id', row.id);

  return { statusCode: 200, body: JSON.stringify({ success: true }) };
};
