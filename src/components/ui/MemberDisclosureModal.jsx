import React, { useState } from 'react';
import { supabase } from '../../supabase';
import { Button } from './Button';

// Mandatory two-step disclosure gate shown to a logged-in member until both
// steps are acknowledged (each step is just a checkbox — same wording style
// on both). Driven entirely by members.investment_advice_ack_at /
// members.conflicts_ack_at (see migration 013) — not localStorage — so it
// reliably reappears "next login" for anyone who hasn't completed it yet,
// and resumes on whichever step is incomplete if they left mid-flow.
// No close/backdrop-dismiss: it's a mandatory gate, not a dismissible prompt.

export const MemberDisclosureModal = ({ currentUser, siteSettings, avTeam, onAcknowledged }) => {
  const [agreeStep1, setAgreeStep1] = useState(false);
  const [agree, setAgree] = useState(false);
  const [submitting, setSubmitting] = useState(false);
  const [error, setError] = useState('');

  if (!currentUser?.id) return null;

  // AV staff aren't Club members and don't need the investment-advice /
  // conflicts acknowledgement — skip for anyone with an @av.vc email or a
  // matching row in the av_team table (covers non-@av.vc AV staff too).
  const email = currentUser.email?.toLowerCase().trim();
  const isAvTeamMember = !!email && (
    email.endsWith('@av.vc') ||
    (avTeam || []).some((av) => av.email?.toLowerCase().trim() === email)
  );
  if (isAvTeamMember) return null;

  const step = !currentUser.investment_advice_ack_at
    ? 1
    : !currentUser.conflicts_ack_at
      ? 2
      : null;

  if (!step) return null;

  const clubName = siteSettings?.club_name || 'Athlete';
  const clubSubtitle = siteSettings?.club_subtitle || 'Venture Club';
  const clubDisplayName = `${clubName} ${clubSubtitle}`;

  const accountName = currentUser.full_name || '';

  const submitStep1 = async () => {
    if (!agreeStep1) return;
    setSubmitting(true);
    setError('');
    try {
      const { error: dbError } = await supabase
        .from('members')
        .update({
          investment_advice_ack_at: new Date().toISOString(),
          investment_advice_ack_name: accountName,
        })
        .eq('id', currentUser.id);
      if (dbError) throw dbError;
      onAcknowledged({
        investment_advice_ack_at: new Date().toISOString(),
        investment_advice_ack_name: accountName,
      });
    } catch (err) {
      console.error('Failed to record investment advice acknowledgement:', err);
      setError('Something went wrong saving your acknowledgement. Please try again.');
    } finally {
      setSubmitting(false);
    }
  };

  const submitStep2 = async () => {
    if (!agree) return;
    setSubmitting(true);
    setError('');
    try {
      const { error: dbError } = await supabase
        .from('members')
        .update({ conflicts_ack_at: new Date().toISOString() })
        .eq('id', currentUser.id);
      if (dbError) throw dbError;
      onAcknowledged({ conflicts_ack_at: new Date().toISOString() });
    } catch (err) {
      console.error('Failed to record conflicts acknowledgement:', err);
      setError('Something went wrong saving your acknowledgement. Please try again.');
    } finally {
      setSubmitting(false);
    }
  };

  return (
    <div className="fixed inset-0 bg-black/50 flex items-center justify-center z-[100] p-4">
      <div className="bg-white rounded-xl w-full max-w-2xl max-h-[90vh] overflow-y-auto shadow-xl">
        <div className="p-6 border-b border-gray-200 sticky top-0 bg-white">
          <h2 className="text-lg font-semibold text-gray-900">Required Acknowledgement</h2>
          <p className="text-xs text-gray-500 mt-1">Step {step} of 2</p>
        </div>

        <div className="p-6 space-y-5">
          {step === 1 && (
            <>
              <p className="text-sm text-gray-700 leading-relaxed">
                The {clubDisplayName} is not investment advice. No Club officer or member will
                provide personalized advice to any attendee, and discussions during Club meetings
                may not be relied on as personalized advice. Club members will make their own
                independent decisions with respect to any investment or other matters discussed,
                and are strongly encouraged to consult with their professional advisors and
                fiduciaries before making any investments.
              </p>
              <p className="text-sm text-gray-700 leading-relaxed">
                I understand and agree to the above terms. I will not rely on the Club or any
                information provided in connection with the Club as personalized advice. I am
                responsible for making my own independent decisions on all investment matters.
              </p>
              <label className="flex items-start gap-2.5 cursor-pointer">
                <input
                  type="checkbox"
                  checked={agreeStep1}
                  onChange={(e) => setAgreeStep1(e.target.checked)}
                  className="mt-0.5 w-4 h-4 rounded border-gray-300"
                  autoFocus
                />
                <span className="text-sm text-gray-700">
                  I have read and understand this disclosure.
                </span>
              </label>
              {error && <p className="text-sm text-red-600">{error}</p>}
              <div className="flex justify-end">
                <Button onClick={submitStep1} disabled={!agreeStep1 || submitting}>
                  {submitting ? 'Saving...' : 'Next'}
                </Button>
              </div>
            </>
          )}

          {step === 2 && (
            <>
              <p className="text-sm text-gray-700 leading-relaxed">
                The Club President and any other Alumni Ventures personnel that may attend Club
                meetings have certain conflicts of interest with respect to any investment
                opportunity discussed during the meeting. They are eligible to receive
                compensation for their work with the Club. In general, this compensation will
                consist of a portion of carried interest received by Alumni Ventures, which will
                likely include carried interest derived from any investments you make in venture
                capital opportunities presented during Club meetings. The specific amount will
                vary in Alumni Ventures' discretion.
              </p>
              <label className="flex items-start gap-2.5 cursor-pointer">
                <input
                  type="checkbox"
                  checked={agree}
                  onChange={(e) => setAgree(e.target.checked)}
                  className="mt-0.5 w-4 h-4 rounded border-gray-300"
                />
                <span className="text-sm text-gray-700">
                  I have read and understand this disclosure.
                </span>
              </label>
              {error && <p className="text-sm text-red-600">{error}</p>}
              <div className="flex justify-end">
                <Button onClick={submitStep2} disabled={!agree || submitting}>
                  {submitting ? 'Saving...' : 'Close'}
                </Button>
              </div>
            </>
          )}
        </div>
      </div>
    </div>
  );
};
