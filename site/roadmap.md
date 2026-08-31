# Roadmap

> **North Star**: Notion-like simplicity, built for hiring.
> For small companies and startups (5–50 people, 1–10 open roles at a time).

## Current Status

Treby is complete as a single-company ATS replacement. Core features are already available; what remains is polish, not core capability.

| Feature | Status |
|---|---|
| Multi-company architecture | ✅ Complete |
| Workspace switching with a single email (picker at login + header menu) | ✅ Complete |
| Multiple pipelines per company + templates | ✅ Complete |
| Kanban pipeline (drag & drop, real-time) | ✅ Complete |
| Public career page with branding | ✅ Complete |
| Self-scheduling in the portal + meeting links (Google Meet / Jitsi) | ✅ Complete |
| Google Calendar integration (optional; internal calendar always active) | ✅ Complete |
| Availability rules + multi-examiner overlap | ✅ Complete |
| Custom fields for candidate / position / application | ✅ Complete |
| Notes with star ratings | ✅ Complete |
| CV and logo upload to S3 | ✅ Complete |
| Email (OTP codes and short pings only) | ✅ Complete |
| Team invitations and role-based permissions | ✅ Complete |
| Translations (English / Italian) | ✅ Complete |
| Landing page | ✅ Complete |
| Dashboard with "My Actions", stale applications, upcoming interviews, activity | ✅ Complete |
| Candidate search and filters | ✅ Complete |
| Candidate editing | ✅ Complete |
| Application read status (NEW badge) | ✅ Complete |
| Activity timeline | ✅ Complete |
| Role-based access control (admin/member + examiner/reviewer/advancer) | ✅ Complete |
| Scorecards + advancement gating | ✅ Complete |
| Per-stage message templates | ✅ Complete |
| Pipeline selector in Analytics | ✅ Complete |
| Time-in-stage metrics | ✅ Complete |
| Source tracking | ✅ Complete |
| CSV import | ✅ Complete |
| Bulk operations | ✅ Complete |
| Candidate comparison (2–3 side by side) | ✅ Complete |
| Portal-first communications (OTP, conversations, pings) | ✅ Complete |
| Message scheduling (jitter, retries, queue) | ✅ Complete |
| Duplicate detection and merging | ✅ Complete |
| Dark mode (light/dark/system) | ✅ Complete |

## What's Left (Polish)

- Screenshot regeneration for new pages
- Possible future improvements: analytics export, more granular notifications, saved filters, offer letter management

These are intentionally deferred — see "What We Won't Build" below.

## Original Phased Plan (Already Delivered)

### Phase 1: "I Can Use It Every Day" — ✅ Done

- Dashboard with action items, upcoming interviews, stale applications
- Search by name/email and filters by job/stage
- Direct candidate data editing
- Read/unread status with badge
- Activity history

### Phase 2: "My Team Wants to Use It Too" — ✅ Done

- Admin vs member permissions + per-stage roles (examiner/reviewer/advancer)
- Structured scorecards
- Per-stage message templates in the portal
- Pipeline selector in Analytics
- Average time-in-stage

### Phase 3: "It Replaces the Old ATS" — ✅ Done

- CSV import with column mapping
- Bulk operations on multiple applications
- Side-by-side candidate comparison
- Source tracking with breakdown in Analytics
- Portal-first communications (content in the portal, email only as notification)

## What We Won't Build

- AI candidate scoring
- Proprietary video interviews (we use automatic Google Meet or Jitsi links)
- Offer letter management
- Onboarding workflows
- Complex approval chains
- SSO/SAML
- Mobile app (the web app is already responsive)
- External job board integrations (expensive and low value early on)
