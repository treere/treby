# Treby Roadmap

> **North star**: Notion-level simplicity, purpose-built for hiring.
> For small businesses and startups (5-50 people, hiring 1-10 roles at a time).

---

## Current State

Treby already has a strong foundation:

| Feature | Status |
|---|---|
| Multi-tenant architecture | ✅ Complete |
| Kanban pipeline (drag-and-drop, real-time) | ✅ Complete |
| Public career page (branded, per tenant) | ✅ Complete |
| Candidate self-scheduling with Google Meet | ✅ Complete |
| Google Calendar integration | ✅ Complete |
| Custom fields (dynamic, per-entity) | ✅ Complete |
| Notes with star ratings | ✅ Complete |
| Resume uploads (S3) | ✅ Complete |
| Email notifications (Swoosh) | ✅ Complete |
| Team invites | ✅ Complete |
| i18n (English/Italian) | ✅ Complete |
| Landing page | ✅ Complete |

**The infrastructure is solid. The gaps are in the product layer.**

---

## Phase 1: "I Can Actually Use This Daily"

> Goal: Make Treby a daily driver for a hiring manager.
> Without this, the product feels like a prototype.

### 1.1 — Actionable Dashboard

The current dashboard shows only a welcome message. It needs to be a command center.

**What to show:**

```
┌─────────────────────────────────────────────────────────────┐
│  Good morning, Sarah                            🔔 3 items  │
├─────────────────────────────────────────────────────────────┤
│                                                             │
│  ⚡ Needs your attention                                    │
│  ┌───────────────────────────────────────────────────────┐  │
│  │ • Alex Chen — no action in 5 days (Senior Dev)       │  │
│  │ • 3 candidates stuck in "Screen" (Product Design)    │  │
│  │ • Interview with Jamie tomorrow — no feedback added  │  │
│  └───────────────────────────────────────────────────────┘  │
│                                                             │
│  📅 Upcoming                                                │
│  ┌───────────────────────────────────────────────────────┐  │
│  │ • Tomorrow 2pm — Technical interview w/ Alex Chen    │  │
│  │ • Thursday 10am — Culture fit w/ Sam Park            │  │
│  └───────────────────────────────────────────────────────┘  │
│                                                             │
│  📊 Pipeline at a glance                                    │
│  ┌───────────────────────────────────────────────────────┐  │
│  │ Senior Dev:     ████░░░░ 4 candidates (2 new today)  │  │
│  │ Product Design: ██░░░░░░ 2 candidates (stuck 14d)    │  │
│  │ DevOps:         █░░░░░░░ 1 candidate                  │  │
│  └───────────────────────────────────────────────────────┘  │
│                                                             │
│  📈 This week                                               │
│  • 12 applications received  • 3 interviews completed      │
│  • 0 offers sent            • 1 hire                       │
│                                                             │
└─────────────────────────────────────────────────────────────┘
```

**Data needed:**
- Upcoming interviews for the current user (from `interview_events`)
- Candidate staleness: applications where `updated_at` is older than N days and stage is not "hired" or "rejected"
- Pipeline snapshot: candidate count per stage per open job
- Weekly stats: applications received, interviews completed, offers, hires

**Implementation notes:**
- Add new functions in `Treby.Pipeline` and `Treby.Analytics` (or a new `Treby.Dashboard` context)
- The analytics page already computes some of these; reuse or refactor
- Staleness threshold should be configurable (default: 5 days)

---

### 1.2 — Candidate Search & Filtering

The candidates page is a flat list. With 30+ candidates across 3 roles, it's unusable.

**What to add:**

```
┌─────────────────────────────────────────────────────────────┐
│  Candidates                                    [+ Add]      │
├─────────────────────────────────────────────────────────────┤
│  🔍 Search by name, email...                               │
│                                                             │
│  Filter: [All Jobs ▾]  [All Stages ▾]  [New/Viewed/All ▾]  │
├─────────────────────────────────────────────────────────────┤
│  Name          Email              Job           Stage       │
│  ─────────────────────────────────────────────────────────  │
│  Alex Chen     alex@dev.com       Senior Dev    Interview   │
│  Sam Park      sam@design.co      Product Design Screen     │
│  Maria Garcia  maria@ops.io       DevOps        New         │
│  ...                                                        │
└─────────────────────────────────────────────────────────────┘
```

**Implementation notes:**
- Add search params to `CandidatesLive.Index` handle_event for "search" and "filter"
- `Candidates.list_candidates/2` needs to accept filter options (job_id, stage, search query)
- Use Ecto `ilike` for text search on name and email
- Join through applications to filter by job and stage
- Consider a lightweight full-text search on name+email for larger datasets

---

### 1.3 — Candidate Editing

You can create and delete candidates, but not edit. If someone typos their email, it's stuck forever.

**What to add:**
- Inline edit form on `CandidatesLive.Show` (similar to how `JobsLive.Show` does it)
- Editable fields: name, email, phone, linkedin_url, custom fields
- Validation: email uniqueness within tenant

**Implementation notes:**
- `Candidates.change_candidate/2` already exists but is only used for create
- Add `Candidates.update_candidate/2` (or rename `change_candidate` to support update)
- Add `handle_event("save_edit", ...)` to `CandidatesLive.Show`
- Follow the same inline edit pattern as `JobsLive.Show`

---

### 1.4 — Application Review State

The pipeline shows candidates but there's no "I've seen this" vs "new" indicator.

**What to add:**
- A `reviewed` boolean field on `applications`
- Visual indicator on pipeline cards: 🆕 badge for unreviewed
- One-click toggle: "Mark as reviewed" / "Mark as new"
- Filter option: "Show only unreviewed"

**Implementation notes:**
- New migration: `add :reviewed, :boolean, default: false` to `applications` table
- Add `mark_reviewed/1` and `mark_unreviewed/1` to `Treby.Pipeline`
- Update `PipelineLive.Index` card template to show badge
- Add event handler for review toggle
- When a candidate applies via the public form, `reviewed` defaults to `false`

---

### 1.5 — Activity Timeline

When did someone move Alex from Screen to Interview? Who added that note? When was the resume uploaded?

**What to add:**
- An `activity_log` table recording key events
- Display on candidate show page and optionally on the dashboard

**Events to track:**
- Application created (via public form or manually)
- Application moved between stages (with who moved it)
- Note added
- Interview scheduled
- Interview cancelled
- Candidate created / edited
- Resume uploaded

**Implementation notes:**
- New schema: `Treby.Activities.ActivityLog` with fields: `action`, `actor_id`, `entity_type`, `entity_id`, `metadata` (JSON map), `inserted_at`
- New context: `Treby.Activities` with `log_event/4` and `list_events_for_entity/2`
- Call `log_event` from the relevant context functions (pipeline move, note create, interview schedule, etc.)
- Display as a timeline on candidate show page, most recent first
- Keep it simple: no real-time updates needed, just a chronological feed

---

## Phase 2: "My Team Wants to Use This Too"

> Goal: Make it collaborative. Right now it's a single-player tool.
> A 3-person hiring team should be able to coordinate without leaving Treby.

### 2.1 — Role-Based Access Control

Roles exist (admin/member) but aren't enforced. Any member can invite, remove, or do anything.

**What to restrict:**
- Only admins can: invite/remove team members, manage pipeline stages, manage custom fields, manage branding, delete candidates
- Members can: view everything, add notes, move candidates, schedule interviews, create jobs

**Implementation notes:**
- Add a plug or LiveView helper that checks `current_user.role`
- Use `on_mount` hook in LiveViews that need admin-only access
- Show/hide UI elements based on role (don't just hide — also enforce server-side)
- Keep it simple: 2 roles (admin, member), no granular permissions

---

### 2.2 — Interview Scorecards

Free-text notes with star ratings aren't enough. A structured evaluation helps teams make consistent decisions.

**What to add:**

```
┌─────────────────────────────────────────────────────────────┐
│  Interview Scorecard — Alex Chen (Senior Dev)               │
│  Interviewer: Jamie Lee  │  Date: July 25, 2026            │
├─────────────────────────────────────────────────────────────┤
│                                                             │
│  Technical Skills          ⭐⭐⭐⭐☆  4/5                    │
│  Communication             ⭐⭐⭐☆☆  3/5                    │
│  Problem Solving           ⭐⭐⭐⭐⭐  5/5                    │
│  Culture Fit               ⭐⭐⭐⭐☆  4/5                    │
│                                                             │
│  Recommendation:  [ Strong Hire ▾ ]                         │
│                                                             │
│  Notes:                                                     │
│  ┌───────────────────────────────────────────────────────┐  │
│  │ Strong technical skills, great system design thinking │  │
│  │ ...                                                   │  │
│  └───────────────────────────────────────────────────────┘  │
│                                                             │
│              [ Save Scorecard ]                             │
└─────────────────────────────────────────────────────────────┘
```

**Implementation notes:**
- Admins define scorecard templates in Settings (criteria names, scale)
- Store template in `custom_fields` or a new `scorecard_templates` table
- Scorecard responses stored in a new `scorecards` table linked to interview_event + interviewer
- Extend `InterviewsLive.Index` to show scorecard status (completed/pending)
- Show aggregate scores on candidate show page

---

### 2.3 — Stage-Based Email Templates

When you move a candidate to "Rejected" or "Hired," there should be a way to send a templated email.

**What to add:**
- Email template editor in Settings (one template per stage type)
- Template variables: `{candidate_name}`, `{job_title}`, `{company_name}`
- Send email when moving candidate to a stage (optional, with confirmation dialog)
- Pre-built templates: "Application received," "Moving forward," "Not moving forward," "Offer"

**Implementation notes:**
- Add `email_template` field to `pipeline_stages` (or a separate `email_templates` table)
- When dragging a candidate to a stage, show a confirmation with option to send email
- Use existing Swoosh infrastructure
- Templates stored as HTML with mustache-style variables

---

### 2.4 — Pipeline Selector on Analytics

Analytics only shows the default pipeline. If you have separate pipelines, the data is meaningless.

**What to add:**
- Pipeline dropdown on the analytics page
- "All pipelines" aggregate view
- Per-pipeline conversion rates

**Implementation notes:**
- Add `handle_event("select_pipeline", ...)` to `AnalyticsLive.Index`
- Refactor analytics queries to accept a pipeline_id parameter
- Wire up the existing `stage_conversion_rates/1` function (currently dead code)

---

### 2.5 — Time-in-Stage Metrics

How long do candidates sit in each stage? Where's the bottleneck?

**What to add:**
- Track when applications move between stages (in `activity_log` from Phase 1.5)
- Calculate average time per stage
- Show on analytics page as a bar chart or table

**Implementation notes:**
- Query `activity_log` for "stage_changed" events
- Compute ` AVG(time_in_stage)` per stage per pipeline
- Display alongside existing pipeline overview on analytics page

---

## Phase 3: "We're Replacing Our Old ATS"

> Goal: Remove the last reasons to keep using spreadsheets or other tools.
> This is the "switch cost" phase — make Treby the single source of truth.

### 3.1 — CSV Import

When switching from spreadsheets, you need to bring your data.

**What to add:**
- CSV upload on candidates page
- Map columns to fields (name, email, phone, custom fields)
- Import into a specific job/pipeline stage
- Preview before import, show duplicates

**Implementation notes:**
- Use `Code.CSV` for parsing
- Add a LiveView step wizard: Upload → Map columns → Preview → Import
- Deduplicate by email (same as public application flow)
- Show import summary: X imported, Y duplicates skipped, Z errors

---

### 3.2 — Bulk Operations

When you have 50 candidates in "Screen," you need to act on many at once.

**What to add:**
- Checkbox selection on candidate list and pipeline
- Bulk actions: move to stage, mark as reviewed, delete, send email
- Select all / deselect all

**Implementation notes:**
- Add checkbox column to candidate table and pipeline cards
- Track selected IDs in socket assign
- Add bulk action dropdown toolbar
- Execute bulk operations in a single transaction

---

### 3.3 — Candidate Comparison

When deciding between 2-3 final candidates, you want them side-by-side.

**What to add:**
- "Compare" button on candidate cards (select 2-3)
- Side-by-side view: resume, notes, scores, custom fields, interview feedback

**Implementation notes:**
- New LiveView or a modal/panel on existing page
- Store selected candidates in socket assign
- Render comparison grid with candidate details

---

### 3.4 — Source Tracking

Where did candidates come from? LinkedIn? Referral? Job board?

**What to add:**
- `source` field on applications (or candidates)
- Preset sources: LinkedIn, Referral, Indeed, Company Website, Other
- Custom sources configurable in Settings
- Analytics breakdown by source

**Implementation notes:**
- Add `source` field to `applications` schema
- Show source dropdown on public application form (optional)
- Add source tracking to CSV import
- Add source chart to analytics page

---

### 3.5 — Bidirectional Email

Right now emails go out (interview notifications) but never come back. Real recruiting is a conversation.

**What to add:**
- Inbound email parsing (receive replies to interview notifications)
- Email thread view on candidate page
- Reply from within Treby

**Implementation notes:**
- This is the most complex feature. Consider using a service like Postmark or SendGrid inbound parse
- Store email threads in a new `email_threads` table
- Display thread on candidate show page
- "Reply" button that sends via Swoosh

---

## Feature Priority Matrix

```
  IMPACT
  HIGH  │  🟢 3.1 CSV Import     🟡 2.2 Scorecards
        │  🟢 3.2 Bulk Ops       🟡 2.3 Email Templates
        │  🔴 1.1 Dashboard       🔴 1.2 Search
        │  🔴 1.3 Edit            🔴 1.4 Review State
        │  🔴 1.5 Activity Log
        │
  LOW   │  🟢 3.3 Comparison     🟡 2.5 Time-in-Stage
        │  🟢 3.4 Source Track    🟡 2.4 Pipeline Analytics
        │  🟢 3.5 Bidirectional   🟡 2.1 RBAC
        │         Email
        └──────────────────────────────────────────
           LOW EFFORT                    HIGH EFFORT
```

**Legend:** 🔴 Phase 1 (Must have) · 🟡 Phase 2 (Should have) · 🟢 Phase 3 (Nice to have)

---

## What NOT to Build

These are tempting but would bloat the product and destroy the "Notion simplicity":

- **AI-powered candidate scoring** — gimmicky, erodes trust
- **Video interviews** — use Google Meet (already integrated)
- **Offer letter management** — use DocuSign or a doc template
- **Onboarding workflows** — that's a different product
- **Complex approval chains** — startups don't have these
- **SSO/SAML** — overkill for 5-50 person companies
- **Mobile app** — the web app is responsive, that's enough
- **Job board integrations** (Indeed, LinkedIn) — expensive API partnerships, low ROI early on

---

## Tech Stack Considerations

The existing stack is well-suited for all of this:

| Need | Existing Tool | Notes |
|---|---|---|
| Real-time updates | Phoenix PubSub | Already used for pipeline |
| Email | Swoosh | Already used for notifications |
| File storage | S3/ExAWS | Already used for resumes |
| Search | Ecto + PostgreSQL | `ilike` is fine for <1000 candidates |
| Background jobs | Not needed yet | Email is synchronous, fine for now |
| Encryption | Cloak/Ecto | Already used for Google tokens |

**No new dependencies needed for Phase 1 or 2.** Phase 3 might need a CSV parsing library (`nimble_csv`) and inbound email service.

---

## Measuring Success

After each phase, ask:

| Question | Phase 1 Target | Phase 2 Target | Phase 3 Target |
|---|---|---|---|
| Can a hiring manager use it daily? | Yes | Yes | Yes |
| Can a 3-person team coordinate? | No | Yes | Yes |
| Is it better than a spreadsheet? | For tracking, yes | For everything, yes | For everything, yes |
| Would you pay $30/mo for it? | Maybe | Yes | Definitely |
