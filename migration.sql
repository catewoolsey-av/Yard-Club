--
-- PostgreSQL database dump
--

\restrict AtWhmXM6h5ef571Yq8nfRRTc0FnRHSPYrAfBby5Us9um3J6Uw3cfk4UWkLprjbm

-- Dumped from database version 17.6
-- Dumped by pg_dump version 17.8 (Homebrew)

SET statement_timeout = 0;
SET lock_timeout = 0;
SET idle_in_transaction_session_timeout = 0;
SET transaction_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SELECT pg_catalog.set_config('search_path', '', false);
SET check_function_bodies = false;
SET xmloption = content;
SET client_min_messages = warning;
SET row_security = off;

--
-- Name: public; Type: SCHEMA; Schema: -; Owner: -
--

CREATE SCHEMA public;


--
-- Name: SCHEMA public; Type: COMMENT; Schema: -; Owner: -
--

COMMENT ON SCHEMA public IS 'standard public schema';


--
-- Name: rls_auto_enable(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.rls_auto_enable() RETURNS event_trigger
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO 'pg_catalog'
    AS $$
DECLARE
  cmd record;
BEGIN
  FOR cmd IN
    SELECT *
    FROM pg_event_trigger_ddl_commands()
    WHERE command_tag IN ('CREATE TABLE', 'CREATE TABLE AS', 'SELECT INTO')
      AND object_type IN ('table','partitioned table')
  LOOP
     IF cmd.schema_name IS NOT NULL AND cmd.schema_name IN ('public') AND cmd.schema_name NOT IN ('pg_catalog','information_schema') AND cmd.schema_name NOT LIKE 'pg_toast%' AND cmd.schema_name NOT LIKE 'pg_temp%' THEN
      BEGIN
        EXECUTE format('alter table if exists %s enable row level security', cmd.object_identity);
        RAISE LOG 'rls_auto_enable: enabled RLS on %', cmd.object_identity;
      EXCEPTION
        WHEN OTHERS THEN
          RAISE LOG 'rls_auto_enable: failed to enable RLS on %', cmd.object_identity;
      END;
     ELSE
        RAISE LOG 'rls_auto_enable: skip % (either system schema or not in enforced list: %.)', cmd.object_identity, cmd.schema_name;
     END IF;
  END LOOP;
END;
$$;


--
-- Name: set_updated_at(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.set_updated_at() RETURNS trigger
    LANGUAGE plpgsql
    SET search_path TO 'pg_catalog', 'public'
    AS $$
begin
  new.updated_at = now();
  return new;
end;
$$;


--
-- Name: update_updated_at_column(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.update_updated_at_column() RETURNS trigger
    LANGUAGE plpgsql
    SET search_path TO 'pg_catalog', 'public'
    AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$;


SET default_tablespace = '';

SET default_table_access_method = heap;

--
-- Name: admin_sessions; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.admin_sessions (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    device_id text NOT NULL,
    is_active boolean DEFAULT true,
    created_at timestamp with time zone DEFAULT now()
);


--
-- Name: admin_settings; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.admin_settings (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    admin_password text NOT NULL
);


--
-- Name: announcements; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.announcements (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    title text NOT NULL,
    content text,
    author text,
    is_pinned boolean DEFAULT false,
    created_at timestamp with time zone DEFAULT now(),
    author_id uuid
);


--
-- Name: av_team; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.av_team (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    full_name text NOT NULL,
    email text NOT NULL,
    title text,
    company text DEFAULT 'Alumni Ventures'::text,
    club_role text DEFAULT 'Mentor'::text,
    bio text,
    emoji text DEFAULT '👤'::text,
    fun_fact text,
    linkedin_url text,
    phone text,
    location text,
    timezone text DEFAULT 'America/New_York'::text,
    is_active boolean DEFAULT true,
    is_visible_to_members boolean DEFAULT false,
    created_at timestamp with time zone DEFAULT now(),
    photo_url text
);


--
-- Name: content; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.content (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    title text NOT NULL,
    description text,
    type text DEFAULT 'article'::text,
    category text,
    url text,
    duration text,
    thumbnail_url text,
    author text,
    file_name text,
    featured boolean DEFAULT false,
    sort_order integer DEFAULT 0,
    created_at timestamp with time zone DEFAULT now()
);


--
-- Name: deal_interests; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.deal_interests (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    member_id uuid NOT NULL,
    deal_id uuid NOT NULL,
    interest_type text NOT NULL,
    investment_amount numeric,
    reason text,
    status text DEFAULT 'pending'::text,
    email_sent boolean DEFAULT false,
    email_sent_at timestamp with time zone,
    email_error text,
    created_at timestamp with time zone DEFAULT now(),
    updated_at timestamp with time zone DEFAULT now(),
    archived boolean DEFAULT false NOT NULL
);


--
-- Name: deals; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.deals (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    company_name text NOT NULL,
    headline text,
    sector text,
    stage text,
    description text,
    raise_amount text,
    valuation text,
    lead_investor text,
    av_allocation text,
    minimum_check text,
    status text DEFAULT 'new'::text,
    voting_deadline date,
    deal_deadline date,
    memo_url text,
    deck_url text,
    portal_url text,
    highlights jsonb DEFAULT '[]'::jsonb,
    risks jsonb DEFAULT '[]'::jsonb,
    created_at timestamp with time zone DEFAULT now(),
    company_logo text,
    company_url text,
    additional_media jsonb DEFAULT '[]'::jsonb,
    source_deal_id uuid,
    closes_at timestamp with time zone,
    interest_active boolean DEFAULT false NOT NULL,
    archived_at timestamp with time zone
);


--
-- Name: intro_requests; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.intro_requests (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    from_member_id uuid,
    to_member_id uuid,
    reason text,
    note text,
    proposed_format text,
    suggested_format text,
    status text DEFAULT 'pending'::text,
    email_shared boolean DEFAULT false,
    email_shared_at timestamp with time zone,
    created_at timestamp with time zone DEFAULT now(),
    responded_at timestamp with time zone
);


--
-- Name: member_blocks; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.member_blocks (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    blocker_id uuid,
    blocked_id uuid,
    created_at timestamp with time zone DEFAULT now()
);


--
-- Name: member_reports; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.member_reports (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    reporter_id uuid,
    reported_id uuid,
    reason text,
    note text,
    status text DEFAULT 'pending'::text,
    admin_notes text,
    reviewed_by text,
    reviewed_at timestamp with time zone,
    created_at timestamp with time zone DEFAULT now()
);


--
-- Name: member_sessions; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.member_sessions (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    member_id uuid,
    device_id text NOT NULL,
    is_active boolean DEFAULT true,
    created_at timestamp with time zone DEFAULT now()
);


--
-- Name: members; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.members (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    full_name text NOT NULL,
    email text NOT NULL,
    must_change_password boolean DEFAULT false,
    emoji text DEFAULT '👤'::text,
    headline text,
    photo_url text,
    phone text,
    location text,
    timezone text DEFAULT 'America/New_York'::text,
    linkedin_url text,
    whatsapp text,
    calendly_url text,
    preferred_contact text DEFAULT 'email'::text,
    member_role text,
    member_company text,
    sector_interests jsonb DEFAULT '[]'::jsonb,
    stage_interest jsonb DEFAULT '[]'::jsonb,
    geography_preference jsonb DEFAULT '[]'::jsonb,
    deal_role_preference jsonb DEFAULT '[]'::jsonb,
    theme_tags jsonb DEFAULT '[]'::jsonb,
    personal_statement text,
    why_joined text,
    hoping_to_get jsonb DEFAULT '[]'::jsonb,
    vc_experience_level text DEFAULT 'new'::text,
    learning_goals jsonb DEFAULT '[]'::jsonb,
    fun_fact text,
    outside_interests jsonb DEFAULT '[]'::jsonb,
    languages jsonb DEFAULT '[]'::jsonb,
    open_to_chats boolean DEFAULT true,
    chat_format text,
    best_times jsonb DEFAULT '[]'::jsonb,
    email_visible boolean DEFAULT false,
    whatsapp_visible boolean DEFAULT false,
    calendly_visible boolean DEFAULT false,
    onboarding_complete boolean DEFAULT false,
    code_of_conduct_accepted boolean DEFAULT false,
    is_manager boolean DEFAULT false,
    admin_accreditation_status text,
    admin_check_size_band text,
    admin_past_av_investments boolean DEFAULT false,
    admin_investment_count integer DEFAULT 0,
    admin_compliance_flags jsonb DEFAULT '[]'::jsonb,
    admin_restricted_notes text,
    admin_agreement_signed boolean DEFAULT false,
    admin_internal_owner text,
    admin_internal_notes text,
    admin_last_contact_date date,
    created_at timestamp with time zone DEFAULT now(),
    migration_status text DEFAULT 'pending'::text,
    auth_user_id uuid,
    linkedin_connected boolean DEFAULT false,
    linkedin_sub text,
    linkedin_photo_url text,
    linkedin_name text,
    linkedin_connected_at timestamp with time zone,
    deals_disclosure_accepted_at timestamp with time zone
);


--
-- Name: messages; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.messages (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    thread_id uuid,
    from_member_id uuid,
    to_member_id uuid,
    intro_request_id uuid,
    content text NOT NULL,
    read boolean DEFAULT false,
    read_at timestamp with time zone,
    created_at timestamp with time zone DEFAULT now()
);


--
-- Name: password_reset_codes; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.password_reset_codes (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    email text NOT NULL,
    code_hash text NOT NULL,
    expires_at timestamp with time zone NOT NULL,
    used_at timestamp with time zone,
    attempts integer DEFAULT 0 NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL
);


--
-- Name: portfolio_investments; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.portfolio_investments (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    member_id uuid,
    news text,
    investment_date date,
    dd_report_url text,
    amount_invested numeric,
    cost_basis numeric,
    current_value numeric,
    exit_status text DEFAULT 'Active'::text,
    created_at timestamp with time zone DEFAULT now(),
    deal_id uuid
);


--
-- Name: session_rsvps; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.session_rsvps (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    session_id uuid,
    member_id uuid,
    attending boolean NOT NULL,
    created_at timestamp with time zone DEFAULT now()
);


--
-- Name: sessions; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.sessions (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    title text NOT NULL,
    description text,
    type text DEFAULT 'seminar'::text,
    date date,
    "time" text,
    timezone text DEFAULT 'EST'::text,
    duration integer DEFAULT 60,
    host_name text,
    host_title text,
    host_linkedin text,
    zoom_link text,
    recording_url text,
    deal_id uuid,
    created_at timestamp with time zone DEFAULT now(),
    google_calendar_link text,
    attendees jsonb DEFAULT '[]'::jsonb,
    participants jsonb DEFAULT '[]'::jsonb,
    meeting_notes text DEFAULT ''::text,
    member_notes jsonb DEFAULT '{}'::jsonb NOT NULL
);


--
-- Name: site_settings; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.site_settings (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    club_name text DEFAULT 'Next Gen'::text,
    club_subtitle text DEFAULT 'Venture Club'::text,
    cohort_name text DEFAULT 'Cohort 1'::text,
    primary_color text DEFAULT '#1B4D5C'::text,
    accent_color text DEFAULT '#C9A227'::text,
    logo_url text DEFAULT '/av-logo.png'::text,
    created_at timestamp with time zone DEFAULT now(),
    logo_background_color text DEFAULT '#1B4D5C'::text,
    cohort_number text,
    email_test_mode boolean DEFAULT true
);


--
-- Data for Name: admin_sessions; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.admin_sessions (id, device_id, is_active, created_at) FROM stdin;
89078595-0eea-4bf2-9f46-55b4e6d2470a	device_e31nf18y4_1783450624207	t	2026-07-14 14:57:41.730155+00
\.


--
-- Data for Name: admin_settings; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.admin_settings (id, admin_password) FROM stdin;
\.


--
-- Data for Name: announcements; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.announcements (id, title, content, author, is_pinned, created_at, author_id) FROM stdin;
\.


--
-- Data for Name: av_team; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.av_team (id, full_name, email, title, company, club_role, bio, emoji, fun_fact, linkedin_url, phone, location, timezone, is_active, is_visible_to_members, created_at, photo_url) FROM stdin;
c97da4ea-a3ea-46a7-981b-7d783aa03112	Yev Gelfand	yev@av.vc	Partner	Alumni Ventures	Club President		initials					America/New_York	t	t	2026-07-07 19:13:04.769144+00	
021f3191-a370-46fd-9d04-8ef076bcec31	Cate Woolsey	cate.woolsey@av.vc	AI Associate	Alumni Ventures	Club Operations	I recently graduated from Middlebury College, where I majored in Computer Science and minored in the History of Art and Architecture. My interests lie at the intersection of art, technology, and growth—exploring how creativity and innovation can drive meaningful experiences. With a background in both technical problem-solving and artistic analysis, I am passionate about designing and building solutions that blend functionality with aesthetics.	👤	\N	\N	\N	\N	America/New_York	t	f	2026-07-07 18:41:04.424908+00	\N
b9e40d0e-6d77-48be-bc9e-2e6c543eeec6	Brandon Osian	brandon.osian@av.vc	Venture Associate	Alumni Ventures	Membership Manager		initials					America/New_York	t	t	2026-07-07 19:13:31.549507+00	
2363b2fe-75fc-4b6d-b462-7ed589b1cbdb	Emily Hamilton	emily@av.vc	Community Manager	Alumni Ventures	Membership Manager		initials					America/New_York	t	f	2026-07-07 19:12:42.652833+00	profile-photos/linkedin_c0504ce6-9832-4f9b-a8f6-0438c58b1a12_1784042296940.jpg
d70a4304-723a-4f5c-89f9-ed6b16fb5a4f	Eoin Forker	eoin@av.vc	AI Associate	Alumni Ventures	Contributor		initials					America/New_York	t	f	2026-07-14 14:57:58.873896+00	profile-photos/linkedin_737e8459-6592-4f74-8846-e917b3720a7e_1784041632799.jpg
\.


--
-- Data for Name: content; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.content (id, title, description, type, category, url, duration, thumbnail_url, author, file_name, featured, sort_order, created_at) FROM stdin;
07465af9-a616-452e-a356-d1a505a6403f	AV 100	This curated selection of 100 ventures from AV’s portfolio of over 1,600+ current and historical investments represents the names our 10 venture teams are most excited to spotlight. These companies were selected for their variety, innovative impact, performance, and upside potential.	pdf	\N	https://wpiaagersjhhosozclla.supabase.co/storage/v1/object/public/content-files/content/1776971253283_fclbzy0pl.pdf		\N	Alumni Ventures	AV100_2026 (1).pdf	f	2	2026-04-23 19:08:40.476828+00
a49163f0-255b-4ef2-9687-9237fc935217	The Role of Venture Capital in a Modern Portfolio	Venture capital has evolved from a niche asset class into an important part of sophisticated portfolios. This lesson provides an overview of venture capital — how it works, key pros, cons, and considerations, and why it might belong in an investor’s portfolio.	link	\N	https://video.av.vc/academy/watch/YuQhXFktq53RqP1sPiqJyA	5 min	\N	Alumni Ventures		f	0	2026-04-23 19:10:00.438718+00
d4d3c03d-247c-4644-8d79-10fb6089733a	What is Venture Capital?	What exactly is venture capital—and why does it matter? In this quick video, we explain the vital role VC plays in fueling innovation. Venture capital provides early-stage funding to bold, high-ambition startups that aim to change the world. Learn how this unique part of the economy helps visionary entrepreneurs turn big ideas into reality.	link	\N	https://video.av.vc/avx/watch/t5rdhYynW5piowUXU9yJn9	33 sec	\N	Alumni Ventures		f	1	2026-04-23 19:15:03.84649+00
\.


--
-- Data for Name: deal_interests; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.deal_interests (id, member_id, deal_id, interest_type, investment_amount, reason, status, email_sent, email_sent_at, email_error, created_at, updated_at, archived) FROM stdin;
\.


--
-- Data for Name: deals; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.deals (id, company_name, headline, sector, stage, description, raise_amount, valuation, lead_investor, av_allocation, minimum_check, status, voting_deadline, deal_deadline, memo_url, deck_url, portal_url, highlights, risks, created_at, company_logo, company_url, additional_media, source_deal_id, closes_at, interest_active, archived_at) FROM stdin;
\.


--
-- Data for Name: intro_requests; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.intro_requests (id, from_member_id, to_member_id, reason, note, proposed_format, suggested_format, status, email_shared, email_shared_at, created_at, responded_at) FROM stdin;
\.


--
-- Data for Name: member_blocks; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.member_blocks (id, blocker_id, blocked_id, created_at) FROM stdin;
\.


--
-- Data for Name: member_reports; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.member_reports (id, reporter_id, reported_id, reason, note, status, admin_notes, reviewed_by, reviewed_at, created_at) FROM stdin;
\.


--
-- Data for Name: member_sessions; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.member_sessions (id, member_id, device_id, is_active, created_at) FROM stdin;
025fa9bc-3417-44ca-9dc6-f624f22ae010	c0504ce6-9832-4f9b-a8f6-0438c58b1a12	device_9gghqkrcd_1784040508143	t	2026-07-14 14:49:12.800943+00
e2931e43-e14d-48e6-8bf5-8ebd1e33e554	737e8459-6592-4f74-8846-e917b3720a7e	device_l1i7cj6kw_1784027564566	t	2026-07-14 15:02:40.901656+00
86add8bd-82ef-445b-a700-d08ff01fdc7d	c0504ce6-9832-4f9b-a8f6-0438c58b1a12	device_io6uvdbnv_1783452886135	t	2026-07-14 15:18:01.166113+00
\.


--
-- Data for Name: members; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.members (id, full_name, email, must_change_password, emoji, headline, photo_url, phone, location, timezone, linkedin_url, whatsapp, calendly_url, preferred_contact, member_role, member_company, sector_interests, stage_interest, geography_preference, deal_role_preference, theme_tags, personal_statement, why_joined, hoping_to_get, vc_experience_level, learning_goals, fun_fact, outside_interests, languages, open_to_chats, chat_format, best_times, email_visible, whatsapp_visible, calendly_visible, onboarding_complete, code_of_conduct_accepted, is_manager, admin_accreditation_status, admin_check_size_band, admin_past_av_investments, admin_investment_count, admin_compliance_flags, admin_restricted_notes, admin_agreement_signed, admin_internal_owner, admin_internal_notes, admin_last_contact_date, created_at, migration_status, auth_user_id, linkedin_connected, linkedin_sub, linkedin_photo_url, linkedin_name, linkedin_connected_at, deals_disclosure_accepted_at) FROM stdin;
e751f306-a5a7-4b53-94db-be522be80733	Yev Gelfand	yev@av.vc	t	initials	Club President		\N		America/New_York		\N	\N	email	Club President	\N	[]	[]	[]	[]	[]	\N	\N	[]	new	[]	\N	[]	[]	f	\N	[]	f	f	f	f	f	t	\N	\N	f	0	[]	\N	f	\N	\N	\N	2026-07-07 19:13:59.082577+00	pending	2b015ba9-55b1-46ec-9673-ddcfcba0d941	f	\N	\N	\N	\N	\N
9b9e4906-7aa8-45f4-bebf-cf0abbf8eb43	Brandon Osian	brandon.osian@av.vc	t	initials	Membership Manager		\N		America/New_York		\N	\N	email	Membership Manager	\N	[]	[]	[]	[]	[]	\N	\N	[]	new	[]	\N	[]	[]	f	\N	[]	f	f	f	f	f	t	\N	\N	f	0	[]	\N	f	\N	\N	\N	2026-07-07 19:14:11.857062+00	pending	70617fd6-39b8-466f-b22e-bc3334217679	f	\N	\N	\N	\N	\N
57de2705-93fc-48f5-a992-b4cbf1efda26	Cate Woolsey	cate.woolsey@av.vc	f	👤	\N	\N	\N	\N	America/New_York	\N	\N	\N	email	\N	\N	[]	[]	[]	[]	[]	\N	\N	[]	new	[]	\N	[]	[]	t	\N	[]	f	f	f	t	t	t	\N	\N	f	0	[]	\N	f	\N	\N	\N	2026-07-07 18:40:37.76563+00	pending	1fdcaa9f-c68d-4396-97c4-5f776070af08	f	\N	\N	\N	\N	2026-07-13 17:12:53.816+00
c0504ce6-9832-4f9b-a8f6-0438c58b1a12	Emily Hamilton	emily@av.vc	f	initials	Membership Manager	profile-photos/linkedin_c0504ce6-9832-4f9b-a8f6-0438c58b1a12_1784042296940.jpg	\N		America/New_York		\N	\N	email	Membership Manager	\N	[]	[]	[]	[]	[]	\N	\N	[]	new	[]	\N	[]	[]	f	\N	[]	f	f	f	f	f	t	\N	\N	f	0	[]	\N	f	\N	\N	\N	2026-07-07 19:13:43.372817+00	pending	1dff0783-9306-4806-8189-7e9aed07000d	t	mZ3_VhYLjO	profile-photos/linkedin_c0504ce6-9832-4f9b-a8f6-0438c58b1a12_1784042296940.jpg	Emily Hamilton	2026-07-14 15:18:17.7+00	\N
737e8459-6592-4f74-8846-e917b3720a7e	Eoin Forker	eoin@av.vc	f	initials	Contributor	profile-photos/linkedin_737e8459-6592-4f74-8846-e917b3720a7e_1784041632799.jpg	\N		America/New_York		\N	\N	email	Contributor	\N	[]	[]	[]	[]	[]	\N	\N	[]	new	[]	\N	[]	[]	f	\N	[]	f	f	f	f	f	t	\N	\N	f	0	[]	\N	f	\N	\N	\N	2026-07-14 14:58:30.290673+00	pending	e7e45b7b-93ef-48a4-a4a7-e27753b30940	t	J5Emq4WZ-w	profile-photos/linkedin_737e8459-6592-4f74-8846-e917b3720a7e_1784041632799.jpg	Eoin Forker	2026-07-14 15:07:13.379+00	2026-07-14 15:37:18.859+00
\.


--
-- Data for Name: messages; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.messages (id, thread_id, from_member_id, to_member_id, intro_request_id, content, read, read_at, created_at) FROM stdin;
\.


--
-- Data for Name: password_reset_codes; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.password_reset_codes (id, email, code_hash, expires_at, used_at, attempts, created_at) FROM stdin;
\.


--
-- Data for Name: portfolio_investments; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.portfolio_investments (id, member_id, news, investment_date, dd_report_url, amount_invested, cost_basis, current_value, exit_status, created_at, deal_id) FROM stdin;
\.


--
-- Data for Name: session_rsvps; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.session_rsvps (id, session_id, member_id, attending, created_at) FROM stdin;
\.


--
-- Data for Name: sessions; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.sessions (id, title, description, type, date, "time", timezone, duration, host_name, host_title, host_linkedin, zoom_link, recording_url, deal_id, created_at, google_calendar_link, attendees, participants, meeting_notes, member_notes) FROM stdin;
\.


--
-- Data for Name: site_settings; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.site_settings (id, club_name, club_subtitle, cohort_name, primary_color, accent_color, logo_url, created_at, logo_background_color, cohort_number, email_test_mode) FROM stdin;
5a3aa484-d70e-4143-b320-d3ed516b3a41	Israel Tech	Venture Club	Cohort 2	#1c5e9c	#324558	/av-white-logo.png	2026-02-04 19:07:50.093105+00	#324558		t
\.


--
-- Name: admin_sessions admin_sessions_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.admin_sessions
    ADD CONSTRAINT admin_sessions_pkey PRIMARY KEY (id);


--
-- Name: admin_settings admin_settings_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.admin_settings
    ADD CONSTRAINT admin_settings_pkey PRIMARY KEY (id);


--
-- Name: announcements announcements_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.announcements
    ADD CONSTRAINT announcements_pkey PRIMARY KEY (id);


--
-- Name: av_team av_team_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.av_team
    ADD CONSTRAINT av_team_pkey PRIMARY KEY (id);


--
-- Name: content content_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.content
    ADD CONSTRAINT content_pkey PRIMARY KEY (id);


--
-- Name: deal_interests deal_interests_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.deal_interests
    ADD CONSTRAINT deal_interests_pkey PRIMARY KEY (id);


--
-- Name: deals deals_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.deals
    ADD CONSTRAINT deals_pkey PRIMARY KEY (id);


--
-- Name: intro_requests intro_requests_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.intro_requests
    ADD CONSTRAINT intro_requests_pkey PRIMARY KEY (id);


--
-- Name: member_blocks member_blocks_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.member_blocks
    ADD CONSTRAINT member_blocks_pkey PRIMARY KEY (id);


--
-- Name: member_reports member_reports_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.member_reports
    ADD CONSTRAINT member_reports_pkey PRIMARY KEY (id);


--
-- Name: member_sessions member_sessions_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.member_sessions
    ADD CONSTRAINT member_sessions_pkey PRIMARY KEY (id);


--
-- Name: members members_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.members
    ADD CONSTRAINT members_pkey PRIMARY KEY (id);


--
-- Name: messages messages_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.messages
    ADD CONSTRAINT messages_pkey PRIMARY KEY (id);


--
-- Name: password_reset_codes password_reset_codes_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.password_reset_codes
    ADD CONSTRAINT password_reset_codes_pkey PRIMARY KEY (id);


--
-- Name: portfolio_investments portfolio_investments_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.portfolio_investments
    ADD CONSTRAINT portfolio_investments_pkey PRIMARY KEY (id);


--
-- Name: session_rsvps session_rsvps_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.session_rsvps
    ADD CONSTRAINT session_rsvps_pkey PRIMARY KEY (id);


--
-- Name: sessions sessions_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.sessions
    ADD CONSTRAINT sessions_pkey PRIMARY KEY (id);


--
-- Name: site_settings site_settings_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.site_settings
    ADD CONSTRAINT site_settings_pkey PRIMARY KEY (id);


--
-- Name: admin_sessions_device_id_key; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX admin_sessions_device_id_key ON public.admin_sessions USING btree (device_id);


--
-- Name: av_team_email_key; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX av_team_email_key ON public.av_team USING btree (email);


--
-- Name: deal_interests_archived_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX deal_interests_archived_idx ON public.deal_interests USING btree (archived);


--
-- Name: deal_interests_unique_member_deal; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX deal_interests_unique_member_deal ON public.deal_interests USING btree (member_id, deal_id);


--
-- Name: idx_admin_sessions_device; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_admin_sessions_device ON public.admin_sessions USING btree (device_id);


--
-- Name: idx_av_team_email; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_av_team_email ON public.av_team USING btree (email);


--
-- Name: idx_av_team_visible; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_av_team_visible ON public.av_team USING btree (is_visible_to_members) WHERE (is_visible_to_members = true);


--
-- Name: idx_deal_interests_deal_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_deal_interests_deal_id ON public.deal_interests USING btree (deal_id);


--
-- Name: idx_deal_interests_member_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_deal_interests_member_id ON public.deal_interests USING btree (member_id);


--
-- Name: idx_deal_interests_status; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_deal_interests_status ON public.deal_interests USING btree (status);


--
-- Name: idx_deals_source_deal_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_deals_source_deal_id ON public.deals USING btree (source_deal_id);


--
-- Name: idx_deals_status; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_deals_status ON public.deals USING btree (status);


--
-- Name: idx_intro_requests_members; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_intro_requests_members ON public.intro_requests USING btree (from_member_id, to_member_id);


--
-- Name: idx_member_sessions_device; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_member_sessions_device ON public.member_sessions USING btree (device_id);


--
-- Name: idx_members_auth_user_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_members_auth_user_id ON public.members USING btree (auth_user_id);


--
-- Name: idx_members_email; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_members_email ON public.members USING btree (email);


--
-- Name: idx_messages_members; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_messages_members ON public.messages USING btree (from_member_id, to_member_id);


--
-- Name: idx_portfolio_member; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_portfolio_member ON public.portfolio_investments USING btree (member_id);


--
-- Name: idx_pwr_email_active; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_pwr_email_active ON public.password_reset_codes USING btree (email, expires_at DESC) WHERE (used_at IS NULL);


--
-- Name: idx_sessions_date; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_sessions_date ON public.sessions USING btree (date);


--
-- Name: members_email_key; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX members_email_key ON public.members USING btree (email);


--
-- Name: announcements announcements_author_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.announcements
    ADD CONSTRAINT announcements_author_id_fkey FOREIGN KEY (author_id) REFERENCES public.members(id);


--
-- Name: deal_interests deal_interests_deal_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.deal_interests
    ADD CONSTRAINT deal_interests_deal_id_fkey FOREIGN KEY (deal_id) REFERENCES public.deals(id) ON DELETE CASCADE;


--
-- Name: deal_interests deal_interests_member_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.deal_interests
    ADD CONSTRAINT deal_interests_member_id_fkey FOREIGN KEY (member_id) REFERENCES public.members(id) ON DELETE CASCADE;


--
-- Name: intro_requests intro_requests_from_member_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.intro_requests
    ADD CONSTRAINT intro_requests_from_member_id_fkey FOREIGN KEY (from_member_id) REFERENCES public.members(id) ON DELETE CASCADE;


--
-- Name: intro_requests intro_requests_to_member_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.intro_requests
    ADD CONSTRAINT intro_requests_to_member_id_fkey FOREIGN KEY (to_member_id) REFERENCES public.members(id) ON DELETE CASCADE;


--
-- Name: member_blocks member_blocks_blocked_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.member_blocks
    ADD CONSTRAINT member_blocks_blocked_id_fkey FOREIGN KEY (blocked_id) REFERENCES public.members(id) ON DELETE CASCADE;


--
-- Name: member_blocks member_blocks_blocker_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.member_blocks
    ADD CONSTRAINT member_blocks_blocker_id_fkey FOREIGN KEY (blocker_id) REFERENCES public.members(id) ON DELETE CASCADE;


--
-- Name: member_reports member_reports_reported_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.member_reports
    ADD CONSTRAINT member_reports_reported_id_fkey FOREIGN KEY (reported_id) REFERENCES public.members(id) ON DELETE CASCADE;


--
-- Name: member_reports member_reports_reporter_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.member_reports
    ADD CONSTRAINT member_reports_reporter_id_fkey FOREIGN KEY (reporter_id) REFERENCES public.members(id) ON DELETE CASCADE;


--
-- Name: member_sessions member_sessions_member_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.member_sessions
    ADD CONSTRAINT member_sessions_member_id_fkey FOREIGN KEY (member_id) REFERENCES public.members(id) ON DELETE CASCADE;


--
-- Name: messages messages_from_member_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.messages
    ADD CONSTRAINT messages_from_member_id_fkey FOREIGN KEY (from_member_id) REFERENCES public.members(id) ON DELETE CASCADE;


--
-- Name: messages messages_intro_request_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.messages
    ADD CONSTRAINT messages_intro_request_id_fkey FOREIGN KEY (intro_request_id) REFERENCES public.intro_requests(id);


--
-- Name: messages messages_to_member_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.messages
    ADD CONSTRAINT messages_to_member_id_fkey FOREIGN KEY (to_member_id) REFERENCES public.members(id) ON DELETE CASCADE;


--
-- Name: portfolio_investments portfolio_investments_deal_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.portfolio_investments
    ADD CONSTRAINT portfolio_investments_deal_id_fkey FOREIGN KEY (deal_id) REFERENCES public.deals(id) ON DELETE CASCADE;


--
-- Name: portfolio_investments portfolio_investments_member_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.portfolio_investments
    ADD CONSTRAINT portfolio_investments_member_id_fkey FOREIGN KEY (member_id) REFERENCES public.members(id) ON DELETE CASCADE;


--
-- Name: session_rsvps session_rsvps_member_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.session_rsvps
    ADD CONSTRAINT session_rsvps_member_id_fkey FOREIGN KEY (member_id) REFERENCES public.members(id) ON DELETE CASCADE;


--
-- Name: session_rsvps session_rsvps_session_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.session_rsvps
    ADD CONSTRAINT session_rsvps_session_id_fkey FOREIGN KEY (session_id) REFERENCES public.sessions(id) ON DELETE CASCADE;


--
-- Name: av_team AV team readable by all; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "AV team readable by all" ON public.av_team FOR SELECT USING (true);


--
-- Name: av_team AV team writable by service role; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "AV team writable by service role" ON public.av_team USING (true);


--
-- Name: admin_sessions Admin sessions readable by all; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "Admin sessions readable by all" ON public.admin_sessions FOR SELECT USING (true);


--
-- Name: admin_sessions Admin sessions writable by service role; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "Admin sessions writable by service role" ON public.admin_sessions USING (true);


--
-- Name: deal_interests Admins can delete deal interests; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "Admins can delete deal interests" ON public.deal_interests FOR DELETE TO authenticated USING ((EXISTS ( SELECT 1
   FROM public.members
  WHERE ((members.auth_user_id = auth.uid()) AND (members.is_manager = true)))));


--
-- Name: announcements Allow all; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "Allow all" ON public.announcements USING (true);


--
-- Name: av_team Allow all; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "Allow all" ON public.av_team USING (true);


--
-- Name: content Allow all; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "Allow all" ON public.content USING (true);


--
-- Name: deals Allow all; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "Allow all" ON public.deals USING (true);


--
-- Name: intro_requests Allow all; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "Allow all" ON public.intro_requests USING (true);


--
-- Name: member_blocks Allow all; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "Allow all" ON public.member_blocks USING (true);


--
-- Name: member_reports Allow all; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "Allow all" ON public.member_reports USING (true);


--
-- Name: members Allow all; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "Allow all" ON public.members USING (true);


--
-- Name: messages Allow all; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "Allow all" ON public.messages USING (true);


--
-- Name: portfolio_investments Allow all; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "Allow all" ON public.portfolio_investments USING (true);


--
-- Name: session_rsvps Allow all; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "Allow all" ON public.session_rsvps USING (true);


--
-- Name: sessions Allow all; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "Allow all" ON public.sessions USING (true);


--
-- Name: site_settings Allow all; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "Allow all" ON public.site_settings USING (true);


--
-- Name: announcements Allow all operations; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "Allow all operations" ON public.announcements USING (true) WITH CHECK (true);


--
-- Name: av_team Allow all operations; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "Allow all operations" ON public.av_team USING (true) WITH CHECK (true);


--
-- Name: content Allow all operations; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "Allow all operations" ON public.content USING (true) WITH CHECK (true);


--
-- Name: deals Allow all operations; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "Allow all operations" ON public.deals USING (true) WITH CHECK (true);


--
-- Name: intro_requests Allow all operations; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "Allow all operations" ON public.intro_requests USING (true) WITH CHECK (true);


--
-- Name: member_blocks Allow all operations; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "Allow all operations" ON public.member_blocks USING (true) WITH CHECK (true);


--
-- Name: member_reports Allow all operations; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "Allow all operations" ON public.member_reports USING (true) WITH CHECK (true);


--
-- Name: members Allow all operations; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "Allow all operations" ON public.members USING (true) WITH CHECK (true);


--
-- Name: messages Allow all operations; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "Allow all operations" ON public.messages USING (true) WITH CHECK (true);


--
-- Name: portfolio_investments Allow all operations; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "Allow all operations" ON public.portfolio_investments USING (true) WITH CHECK (true);


--
-- Name: session_rsvps Allow all operations; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "Allow all operations" ON public.session_rsvps USING (true) WITH CHECK (true);


--
-- Name: sessions Allow all operations; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "Allow all operations" ON public.sessions USING (true) WITH CHECK (true);


--
-- Name: site_settings Allow all operations; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "Allow all operations" ON public.site_settings USING (true) WITH CHECK (true);


--
-- Name: announcements Announcements readable by all; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "Announcements readable by all" ON public.announcements FOR SELECT USING (true);


--
-- Name: announcements Announcements writable by service role; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "Announcements writable by service role" ON public.announcements USING (true);


--
-- Name: announcements Authenticated users can view announcements; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "Authenticated users can view announcements" ON public.announcements FOR SELECT TO authenticated USING (true);


--
-- Name: content Authenticated users can view content; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "Authenticated users can view content" ON public.content FOR SELECT TO authenticated USING (true);


--
-- Name: deals Authenticated users can view deals; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "Authenticated users can view deals" ON public.deals FOR SELECT TO authenticated USING (true);


--
-- Name: sessions Authenticated users can view sessions; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "Authenticated users can view sessions" ON public.sessions FOR SELECT TO authenticated USING (true);


--
-- Name: content Content readable by all; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "Content readable by all" ON public.content FOR SELECT USING (true);


--
-- Name: content Content writable by service role; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "Content writable by service role" ON public.content USING (true);


--
-- Name: deals Deals readable by all; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "Deals readable by all" ON public.deals FOR SELECT USING (true);


--
-- Name: deals Deals writable by service role; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "Deals writable by service role" ON public.deals USING (true);


--
-- Name: members Enable delete for service role; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "Enable delete for service role" ON public.members FOR DELETE TO service_role USING (true);


--
-- Name: members Enable insert for service role; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "Enable insert for service role" ON public.members FOR INSERT TO service_role WITH CHECK (true);


--
-- Name: members Enable read access for authenticated users; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "Enable read access for authenticated users" ON public.members FOR SELECT TO authenticated USING (true);


--
-- Name: members Enable update for own profile; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "Enable update for own profile" ON public.members FOR UPDATE TO authenticated USING ((auth.uid() = auth_user_id)) WITH CHECK ((auth.uid() = auth_user_id));


--
-- Name: members Enable update for service role; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "Enable update for service role" ON public.members FOR UPDATE TO service_role USING (true) WITH CHECK (true);


--
-- Name: intro_requests Intro requests readable by all; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "Intro requests readable by all" ON public.intro_requests FOR SELECT USING (true);


--
-- Name: intro_requests Intro requests writable by service role; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "Intro requests writable by service role" ON public.intro_requests USING (true);


--
-- Name: member_blocks Member blocks readable by all; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "Member blocks readable by all" ON public.member_blocks FOR SELECT USING (true);


--
-- Name: member_blocks Member blocks writable by service role; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "Member blocks writable by service role" ON public.member_blocks USING (true);


--
-- Name: member_reports Member reports readable by all; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "Member reports readable by all" ON public.member_reports FOR SELECT USING (true);


--
-- Name: member_reports Member reports writable by service role; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "Member reports writable by service role" ON public.member_reports USING (true);


--
-- Name: member_sessions Member sessions readable by all; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "Member sessions readable by all" ON public.member_sessions FOR SELECT USING (true);


--
-- Name: member_sessions Member sessions writable by service role; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "Member sessions writable by service role" ON public.member_sessions USING (true);


--
-- Name: deal_interests Members can insert their own interests; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "Members can insert their own interests" ON public.deal_interests FOR INSERT WITH CHECK (true);


--
-- Name: deal_interests Members can update their own interests; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "Members can update their own interests" ON public.deal_interests FOR UPDATE USING (true);


--
-- Name: deal_interests Members can view their own interests; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "Members can view their own interests" ON public.deal_interests FOR SELECT USING (true);


--
-- Name: members Members readable by all; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "Members readable by all" ON public.members FOR SELECT USING (true);


--
-- Name: members Members writable by service role; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "Members writable by service role" ON public.members USING (true);


--
-- Name: messages Messages readable by all; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "Messages readable by all" ON public.messages FOR SELECT USING (true);


--
-- Name: messages Messages writable by service role; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "Messages writable by service role" ON public.messages USING (true);


--
-- Name: portfolio_investments Portfolio investments readable by all; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "Portfolio investments readable by all" ON public.portfolio_investments FOR SELECT USING (true);


--
-- Name: portfolio_investments Portfolio investments writable by service role; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "Portfolio investments writable by service role" ON public.portfolio_investments USING (true);


--
-- Name: announcements Public read; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "Public read" ON public.announcements FOR SELECT USING (true);


--
-- Name: av_team Public read; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "Public read" ON public.av_team FOR SELECT USING (true);


--
-- Name: content Public read; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "Public read" ON public.content FOR SELECT USING (true);


--
-- Name: deals Public read; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "Public read" ON public.deals FOR SELECT USING (true);


--
-- Name: intro_requests Public read; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "Public read" ON public.intro_requests FOR SELECT USING (true);


--
-- Name: member_blocks Public read; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "Public read" ON public.member_blocks FOR SELECT USING (true);


--
-- Name: member_reports Public read; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "Public read" ON public.member_reports FOR SELECT USING (true);


--
-- Name: members Public read; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "Public read" ON public.members FOR SELECT USING (true);


--
-- Name: messages Public read; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "Public read" ON public.messages FOR SELECT USING (true);


--
-- Name: portfolio_investments Public read; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "Public read" ON public.portfolio_investments FOR SELECT USING (true);


--
-- Name: session_rsvps Public read; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "Public read" ON public.session_rsvps FOR SELECT USING (true);


--
-- Name: sessions Public read; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "Public read" ON public.sessions FOR SELECT USING (true);


--
-- Name: site_settings Public read; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "Public read" ON public.site_settings FOR SELECT USING (true);


--
-- Name: admin_sessions Service only; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "Service only" ON public.admin_sessions USING (true);


--
-- Name: member_sessions Service only; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "Service only" ON public.member_sessions USING (true);


--
-- Name: members Service role has full access; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "Service role has full access" ON public.members TO service_role USING (true) WITH CHECK (true);


--
-- Name: session_rsvps Service role has full access to RSVPs; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "Service role has full access to RSVPs" ON public.session_rsvps TO service_role USING (true) WITH CHECK (true);


--
-- Name: deal_interests Service role has full access to deal interests; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "Service role has full access to deal interests" ON public.deal_interests TO service_role USING (true) WITH CHECK (true);


--
-- Name: announcements Service write; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "Service write" ON public.announcements USING (true);


--
-- Name: av_team Service write; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "Service write" ON public.av_team USING (true);


--
-- Name: content Service write; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "Service write" ON public.content USING (true);


--
-- Name: deals Service write; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "Service write" ON public.deals USING (true);


--
-- Name: intro_requests Service write; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "Service write" ON public.intro_requests USING (true);


--
-- Name: member_blocks Service write; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "Service write" ON public.member_blocks USING (true);


--
-- Name: member_reports Service write; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "Service write" ON public.member_reports USING (true);


--
-- Name: members Service write; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "Service write" ON public.members USING (true);


--
-- Name: messages Service write; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "Service write" ON public.messages USING (true);


--
-- Name: portfolio_investments Service write; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "Service write" ON public.portfolio_investments USING (true);


--
-- Name: session_rsvps Service write; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "Service write" ON public.session_rsvps USING (true);


--
-- Name: sessions Service write; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "Service write" ON public.sessions USING (true);


--
-- Name: site_settings Service write; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "Service write" ON public.site_settings USING (true);


--
-- Name: session_rsvps Session RSVPs readable by all; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "Session RSVPs readable by all" ON public.session_rsvps FOR SELECT USING (true);


--
-- Name: session_rsvps Session RSVPs writable by service role; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "Session RSVPs writable by service role" ON public.session_rsvps USING (true);


--
-- Name: sessions Sessions readable by all; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "Sessions readable by all" ON public.sessions FOR SELECT USING (true);


--
-- Name: sessions Sessions writable by service role; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "Sessions writable by service role" ON public.sessions USING (true);


--
-- Name: site_settings Site settings readable by all; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "Site settings readable by all" ON public.site_settings FOR SELECT USING (true);


--
-- Name: site_settings Site settings writable by service role; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "Site settings writable by service role" ON public.site_settings USING (true);


--
-- Name: session_rsvps Users can manage own RSVPs; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "Users can manage own RSVPs" ON public.session_rsvps TO authenticated USING ((member_id IN ( SELECT members.id
   FROM public.members
  WHERE (members.auth_user_id = auth.uid())))) WITH CHECK ((member_id IN ( SELECT members.id
   FROM public.members
  WHERE (members.auth_user_id = auth.uid()))));


--
-- Name: deal_interests Users can manage own deal interests; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "Users can manage own deal interests" ON public.deal_interests FOR INSERT TO authenticated WITH CHECK ((member_id IN ( SELECT members.id
   FROM public.members
  WHERE (members.auth_user_id = auth.uid()))));


--
-- Name: members Users can update own member data; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "Users can update own member data" ON public.members FOR UPDATE TO authenticated USING ((auth_user_id = auth.uid())) WITH CHECK ((auth_user_id = auth.uid()));


--
-- Name: session_rsvps Users can view own RSVPs; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "Users can view own RSVPs" ON public.session_rsvps FOR SELECT TO authenticated USING ((member_id IN ( SELECT members.id
   FROM public.members
  WHERE (members.auth_user_id = auth.uid()))));


--
-- Name: deal_interests Users can view own deal interests; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "Users can view own deal interests" ON public.deal_interests FOR SELECT TO authenticated USING ((member_id IN ( SELECT members.id
   FROM public.members
  WHERE (members.auth_user_id = auth.uid()))));


--
-- Name: members Users can view own member data; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "Users can view own member data" ON public.members FOR SELECT TO authenticated USING ((auth_user_id = auth.uid()));


--
-- Name: admin_sessions; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.admin_sessions ENABLE ROW LEVEL SECURITY;

--
-- Name: admin_settings; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.admin_settings ENABLE ROW LEVEL SECURITY;

--
-- Name: announcements; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.announcements ENABLE ROW LEVEL SECURITY;

--
-- Name: av_team; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.av_team ENABLE ROW LEVEL SECURITY;

--
-- Name: content; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.content ENABLE ROW LEVEL SECURITY;

--
-- Name: deal_interests; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.deal_interests ENABLE ROW LEVEL SECURITY;

--
-- Name: deals; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.deals ENABLE ROW LEVEL SECURITY;

--
-- Name: intro_requests; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.intro_requests ENABLE ROW LEVEL SECURITY;

--
-- Name: member_blocks; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.member_blocks ENABLE ROW LEVEL SECURITY;

--
-- Name: member_reports; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.member_reports ENABLE ROW LEVEL SECURITY;

--
-- Name: member_sessions; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.member_sessions ENABLE ROW LEVEL SECURITY;

--
-- Name: members; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.members ENABLE ROW LEVEL SECURITY;

--
-- Name: messages; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.messages ENABLE ROW LEVEL SECURITY;

--
-- Name: password_reset_codes; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.password_reset_codes ENABLE ROW LEVEL SECURITY;

--
-- Name: portfolio_investments; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.portfolio_investments ENABLE ROW LEVEL SECURITY;

--
-- Name: session_rsvps; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.session_rsvps ENABLE ROW LEVEL SECURITY;

--
-- Name: sessions; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.sessions ENABLE ROW LEVEL SECURITY;

--
-- Name: site_settings; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.site_settings ENABLE ROW LEVEL SECURITY;

--
-- PostgreSQL database dump complete
--

\unrestrict AtWhmXM6h5ef571Yq8nfRRTc0FnRHSPYrAfBby5Us9um3J6Uw3cfk4UWkLprjbm

