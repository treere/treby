# Candidate Portal

Candidates get a self-service portal under `/:tenant_slug/portal/*` — no password, just a 6-digit login code.

![Portal Login](/screenshots/26-portal-login.png)

## Auth — OTP only

- Candidate enters their email at `/portal/login` (`lib/treby_web/live/candidate_portal_live/request_link.ex` + `CandidateOtpController`)
- Receives a **6-digit OTP** by email — hashed at rest (`SHA256`), 10-minute validity, single-use, rate-limited (`lib/treby/candidate_portal/candidate_otp.ex`)
- Verifies at `/portal/verify`; on success a limited-lifetime portal session is opened (a few hours) with explicit logout (`lib/treby_web/controllers/candidate_portal_logout_controller.ex`, `lib/treby_web/plugs/candidate_auth.ex`)

No passwords are ever created for candidates; recruiter and candidate auth are fully separate (different plugs and sessions).

## What candidates can do

| Page | Route | Description |
|---|---|---|
| **Overview** | `/portal` | Application status, current stage, progress panel |
| **Messages** | `/portal/messages`, `/portal/messages/:id` | Threaded conversations per application (recruiter ↔ candidate) |
| **Schedule** | `/portal/schedule` | Self-scheduling picker — overlapping availability for multi-examiner stages (see [Interview Scheduling](/features/interview-scheduling)) |
| **Settings** | `/portal/settings` | Notification preferences — which pings generate an email, "important only" filter |

Every new application automatically gets a **welcome conversation** (`lib/treby/candidate_portal/conversation.ex`); stage moves, messages, interview updates and rejections post into that conversation and optionally trigger a short email ping that links back to `/portal`.

## Messaging inside the portal

- Conversations are per-application (`lib/treby/candidate_portal/message.ex`)
- Recruiters post via the pipeline card, candidate detail, or bulk/message-queue flows; candidates reply from `/portal/messages`
- Scheduled messages are delivered by Oban at `send_at` (see [Message Scheduler](/features/message-scheduler))
- Message templates support `{candidate_name}`, `{job_title}`, `{company_name}`, `{stage_name}`, `{recruiter_name}` (`lib/treby/email_templates/`)

## Notifications & privacy

- All real content lives in the portal — email carries only a short ping with a link to `/portal`
- Candidates control which events generate pings from **Portal → Settings**; pings are short and never contain message bodies
- Portal sessions are tenant-scoped (`tenant_slug` in the URL) and expire after a few hours

## Where it fits

- Public: `/:tenant_slug/portal/login` and `/portal/verify` (no auth)
- Authenticated: `/:tenant_slug/portal/*` through `:candidate_auth` pipeline (`lib/treby_web/router.ex:95`)
- Recruiter side: messages are composed from job/candidate views and delivered into the same conversation model
