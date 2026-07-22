import { createClient } from '@supabase/supabase-js';
import { randomInt, createHash } from 'crypto';

const CODE_TTL_MIN = 15;
const MAX_PER_HOUR = 3;

const hashCode = (code) => createHash('sha256').update(String(code)).digest('hex');

// Always return success — never reveal whether the email exists.
const SUCCESS = { statusCode: 200, body: JSON.stringify({ success: true }) };

export const handler = async (event) => {
  if (event.httpMethod !== 'POST') {
    return { statusCode: 405, body: JSON.stringify({ error: 'Method not allowed' }) };
  }
  let body;
  try { body = JSON.parse(event.body || '{}'); }
  catch { return { statusCode: 400, body: JSON.stringify({ error: 'Invalid JSON' }) }; }
  const email = String(body.email || '').trim().toLowerCase();
  if (!email) return { statusCode: 400, body: JSON.stringify({ error: 'Email required' }) };

  const svc = createClient(process.env.SUPABASE_URL, process.env.SUPABASE_SERVICE_ROLE_KEY);

  // Find the member (silent fail to prevent user enumeration)
  const { data: member } = await svc
    .from('members')
    .select('id, full_name, email, auth_user_id')
    .ilike('email', email)
    .maybeSingle();
  if (!member || !member.auth_user_id) return SUCCESS;

  // Rate limit: max N codes per email per hour
  const oneHourAgo = new Date(Date.now() - 60 * 60 * 1000).toISOString();
  const { count } = await svc
    .from('password_reset_codes')
    .select('id', { count: 'exact', head: true })
    .eq('email', email)
    .gte('created_at', oneHourAgo);
  if ((count || 0) >= MAX_PER_HOUR) return SUCCESS;

  // Invalidate any prior unused codes for this email
  await svc
    .from('password_reset_codes')
    .update({ used_at: new Date().toISOString() })
    .eq('email', email)
    .is('used_at', null);

  // Generate a fresh 6-digit code + store its hash
  const code = String(randomInt(100000, 1000000));
  const codeHash = hashCode(code);
  const expiresAt = new Date(Date.now() + CODE_TTL_MIN * 60 * 1000).toISOString();
  const { error: insErr } = await svc.from('password_reset_codes').insert({
    email,
    code_hash: codeHash,
    expires_at: expiresAt,
  });
  if (insErr) {
    console.error('password_reset_codes insert failed:', insErr.message);
    return SUCCESS;
  }

  // Look up club display name for the subject line
  let clubName = 'Your portal';
  try {
    const { data: ss } = await svc
      .from('site_settings')
      .select('club_name')
      .order('created_at', { ascending: false })
      .limit(1)
      .maybeSingle();
    if (ss?.club_name) clubName = ss.club_name;
  } catch {}

  // Send the code via the existing send-email function
  try {
    const base = process.env.URL || process.env.DEPLOY_URL || '';
    const sendUrl = base ? `${base}/.netlify/functions/send-email` : '/.netlify/functions/send-email';
    const subject = `${clubName} — Password reset code`;
    const html = `
      <div style="font-family:-apple-system,BlinkMacSystemFont,'Segoe UI',sans-serif;color:#1f2937;line-height:1.6;max-width:480px;margin:0 auto;padding:24px;">
        <p>Hi ${member.full_name || 'there'},</p>
        <p>Use this code to reset your password:</p>
        <div style="font-size:32px;font-weight:bold;letter-spacing:6px;text-align:center;padding:16px;background:#f3f4f6;border-radius:8px;margin:16px 0;">${code}</div>
        <p style="color:#6b7280;font-size:14px;">This code expires in ${CODE_TTL_MIN} minutes. If you didn't request a reset, you can ignore this email.</p>
      </div>`;
    const text = `Hi ${member.full_name || 'there'},\n\nYour password reset code is: ${code}\n\nThis code expires in ${CODE_TTL_MIN} minutes.`;
    await fetch(sendUrl, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ to: [email], subject, html, text }),
    });
  } catch (e) {
    console.error('send-email call failed:', e?.message || e);
    // Still return success — don't leak failure mode
  }

  return SUCCESS;
};
