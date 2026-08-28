
# Roadmap

> **North star**: Notion-level simplicity, purpose-built for hiring.
> For small businesses and startups (5-50 people, hiring 1-10 roles at a time).

## Current State

| Feature | Status |
|---|---|
| Multi-tenant architecture | ✅ Complete |
| Kanban pipeline (drag-and-drop, real-time) | ✅ Complete |
| Public career page (branded, per tenant) | ✅ Complete |
| Candidate self-scheduling (in-portal) with Google Meet | ✅ Complete |
| Google Calendar integration | ✅ Complete |
| Custom fields (dynamic, per-entity) | ✅ Complete |
| Notes with star ratings | ✅ Complete |
| Resume uploads (S3) | ✅ Complete |
| Email notifications (Swoosh, OTP + pings only) | ✅ Complete |
| Team invites | ✅ Complete |
| i18n (English/Italian) | ✅ Complete |
| Landing page | ✅ Complete |

**The infrastructure is solid. The gaps are in the product layer.**

## Phase 1: "I Can Actually Use This Daily"

Goal: Make Treby a daily driver for a hiring manager.

- **1.1 Actionable Dashboard** — command center with needs-attention, upcoming interviews, pipeline at a glance
- **1.2 Candidate Search & Filtering** — search by name/email, filter by job/stage
- **1.3 Candidate Editing** — inline edit for candidate fields
- **1.4 Application Review State** — reviewed/unreviewed badges on pipeline cards
- **1.5 Activity Timeline** — chronological log of all candidate events

## Phase 2: "My Team Wants to Use This Too"

Goal: Make it collaborative.

- **2.1 Role-Based Access Control** — enforce admin vs member permissions
- **2.2 Interview Scorecards** — structured evaluation with criteria
- **2.3 Stage-Based Message Templates** — templated portal messages per pipeline stage
- **2.4 Pipeline Selector on Analytics** — per-pipeline analytics views
- **2.5 Time-in-Stage Metrics** — where do candidates get stuck?

## Phase 3: "We're Replacing Our Old ATS"

Goal: Single source of truth.

- **3.1 CSV Import** — migrate from spreadsheets
- **3.2 Bulk Operations** — select and act on many candidates at once
- **3.3 Candidate Comparison** — side-by-side evaluation
- **3.4 Source Tracking** — where do candidates come from?
- **3.5 (replaced) Portal-First Communications** — email is notification-only; all content lives in the portal

## Priority Matrix

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

*Phase 1 priorities

## What NOT to Build

- AI-powered candidate scoring
- Video interviews (use Google Meet — already integrated)
- Offer letter management
- Onboarding workflows
- Complex approval chains
- SSO/SAML
- Mobile app (the web app is responsive)
- Job board integrations (expensive, low ROI early)

## Tech Stack Considerations

| Need | Existing Tool | Notes |
|---|---|---|
| Real-time updates | Phoenix PubSub | Already used for pipeline |
| Email | Swoosh | Already used for notifications |
| File storage | S3/ExAWS | Already used for resumes |
| Search | Ecto + PostgreSQL | ilike is fine for <1000 candidates |
| Background jobs | Oban | Scheduled portal messages |
| Encryption | Cloak/Ecto | Already used for Google tokens |

No new dependencies needed for Phase 1 or 2.
