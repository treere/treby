# Roadmap

> **North star**: Notion-level simplicity, purpose-built for hiring.
> For small businesses and startups (5–50 people, hiring 1–10 roles at a time).

## Current State — November 2025

Treby is **feature-complete for a single tenant ATS replacement**. The roadmap below reflects what shipped since the initial skeleton; current gaps are polish, not core capability.

| Feature | Status | Location |
|---|---|---|
| Multi-tenant architecture | ✅ Complete | `lib/treby/tenants/`, `lib/treby_web/plugs/tenant.ex` |
| Multi-pipeline per tenant + templates | ✅ Complete | `lib/treby/pipeline/` |
| Kanban pipeline (drag-and-drop, real-time) | ✅ Complete | `lib/treby_web/live/pipeline_live/`, `lib/treby_web/live/jobs_live/show.ex` |
| Public career page (branded, per tenant) | ✅ Complete | `lib/treby_web/live/careers_live/` |
| Candidate self-scheduling (in-portal) + meeting links (Google Meet / Jitsi) | ✅ Complete | `lib/treby/calendar/`, `lib/treby_web/live/candidate_portal_live/schedule.ex` |
| Google Calendar integration (optional; internal calendar always active) | ✅ Complete | `lib/treby/calendar/google.ex`, `lib/treby/calendar/providers/` |
| Availability rules + overlapping multi-examiner | ✅ Complete | `lib/treby/availability/` |
| Custom fields (dynamic, per-entity) | ✅ Complete | `lib/treby/customization/` |
| Notes with star ratings | ✅ Complete | `lib/treby/notes/` |
| Resume uploads (S3) + logos | ✅ Complete | `lib/treby/uploads.ex` |
| Email (Swoosh, OTP + pings only) | ✅ Complete | `lib/treby/notifications/`, Swoosh |
| Team invites + role gates | ✅ Complete | `lib/treby/invites/`, `lib/treby_web/hooks/require_role.ex` |
| i18n (English/Italian) | ✅ Complete | `priv/gettext/`, `lib/treby_web/plugs/set_locale.ex` |
| Landing page | ✅ Complete | `lib/treby_web/live/home_live.ex` |
| **Dashboard** (My Actions, stale, upcoming, activity) | ✅ Complete | `lib/treby/dashboard.ex`, `lib/treby_web/live/dashboard_live.ex` |
| **Candidate search & filtering** | ✅ Complete | `lib/treby/candidates/candidates.ex:12` (`ilike`) |
| **Candidate editing** | ✅ Complete | `lib/treby_web/live/candidates_live/show.ex` |
| **Application review state** (NEW badge, toggle) | ✅ Complete | `lib/treby/pipeline/pipeline.ex:904` |
| **Activity timeline** | ✅ Complete | `lib/treby/activities/` |
| **RBAC** (admin vs member + examiner/reviewer/advancer) | ✅ Complete | `lib/treby/pipeline/` role assignments |
| **Interview scorecards + gating** | ✅ Complete | `lib/treby/scorecards/`, `lib/treby/pipeline/pipeline.ex:435` |
| **Stage-based message templates** | ✅ Complete | `lib/treby/email_templates/` |
| **Pipeline selector on Analytics** | ✅ Complete | `lib/treby_web/live/analytics_live/index.ex` |
| **Time-in-stage metrics** | ✅ Complete | `lib/treby/pipeline/pipeline.ex:1091` |
| **Source tracking** | ✅ Complete | `lib/treby/sources/`, Analytics source breakdown |
| **CSV Import** | ✅ Complete | `lib/treby/csv_import/`, `/app/import` |
| **Bulk operations** | ✅ Complete | `lib/treby/bulk_operations/`, candidates list & job page |
| **Candidate comparison** (2–3 side-by-side) | ✅ Complete | `lib/treby/comparison/`, `/app/candidates/compare` |
| **Portal-first comms** (OTP, conversations, pings) | ✅ Complete | `lib/treby/candidate_portal/`, `lib/treby_web/router.ex:95` |
| **Message scheduler** (jitter, retries, queue) | ✅ Complete | `lib/treby/scheduled_messages/`, `lib/treby/workers/`, `/app/messages-queue` |
| **Duplicate detection & merge** | ✅ Complete | `lib/treby/candidates/duplicates.ex`, `/app/candidates/merge` |
| **Dark mode** (light/dark/system) | ✅ Complete | `assets/js/` + Tailwind, `site/features/dark-mode.md` |

## What remains (polish, not core)

- Screenshot regeneration for new pages (`node scripts/screenshots.mjs` — see [Getting Started](/getting-started))
- Optional: pipeline analytics export, more granular notifications, saved filters, offer-letter workflows

These are intentionally deferred — see "What NOT to Build" below.

## Original Phased Plan (for context — now mostly shipped)

### Phase 1: "I Can Actually Use This Daily" — ✅ shipped

- **1.1 Actionable Dashboard** — My Actions (scorecards to fill, waiting on others), upcoming interviews, stale candidates, weekly stats
- **1.2 Candidate Search & Filtering** — `ilike` on name/email + job/stage filters
- **1.3 Candidate Editing** — inline edit on candidate detail
- **1.4 Application Review State** — `reviewed` flag, NEW badge, toggle from card
- **1.5 Activity Timeline** — `ActivityLog` chronology

### Phase 2: "My Team Wants to Use This Too" — ✅ shipped

- **2.1 Role-Based Access Control** — admin/member + per-stage examiner/reviewer/advancer gates
- **2.2 Interview Scorecards** — templates, per-examiner submission, gating
- **2.3 Stage-Based Message Templates** — portal templates with `{candidate_name}` etc.
- **2.4 Pipeline Selector on Analytics** — per-pipeline scoping
- **2.5 Time-in-Stage Metrics** — avg days per stage from activity events

### Phase 3: "We're Replacing Our Old ATS" — ✅ shipped

- **3.1 CSV Import** — NimbleCSV, auto-mapping, `ImportLog`
- **3.2 Bulk Operations** — move/mark/delete/message across many applications
- **3.3 Candidate Comparison** — side-by-side for 2–3 candidates
- **3.4 Source Tracking** — per-source breakdown in Analytics
- **3.5 Portal-First Communications** — email is notification-only; content in portal conversations

## Priority Matrix (historical)

```
  IMPACT
  HIGH  │  CSV Import     Scorecards
        │  Bulk Ops       Message Templates
        │  Dashboard*      Search*
        │  Edit*           Review State*
        │  Activity Log*
        │
  LOW   │  Comparison     Time-in-Stage
        │  Source Track    Pipeline Analytics
        │  RBAC
        │
        └────────────────────────────────
           LOW EFFORT          HIGH EFFORT
```

*Phase 1 priorities — all shipped.*

## What NOT to Build

- AI-powered candidate scoring
- Video interviews (automatic meeting links — Google Meet or Jitsi)
- Offer letter management
- Onboarding workflows
- Complex approval chains
- SSO/SAML
- Mobile app (the web app is responsive)
- Job board integrations (expensive, low ROI early)

## Tech Stack Considerations

| Need | Tool | Notes |
|---|---|---|
| Real-time updates | Phoenix PubSub | Already used for pipeline |
| Email | Swoosh | OTP + pings only |
| File storage | S3/ExAWS + Finch | Resumes + logos |
| Search | Ecto + PostgreSQL `ilike` | Fine for <1k candidates |
| Background jobs | Oban | Scheduled portal messages (`SendScheduledMessage` worker) |
| Encryption | Cloak/Ecto (`Treby.Vault`) | Google tokens |
| CSV | NimbleCSV | Import pipeline |

No new dependencies needed for the shipped phases.
