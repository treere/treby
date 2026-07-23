## Context

Treby is a multi-tenant ATS built with Phoenix LiveView. Phase 1 added a dashboard, candidate search/editing, review state, and activity logging. The app now has:

- Roles (`admin`/`member`) stored on users but not enforced — any user can do anything
- Free-text notes with star ratings as the only evaluation mechanism
- Swoosh email for interview notifications only
- Analytics locked to the default pipeline
- Activity log (from Phase 1) tracking stage changes, notes, interviews, and candidate edits

The target audience is small businesses and startups (5-50 people, 1-3 hiring managers). The goal is to make Treby a collaborative team tool without adding enterprise complexity.

## Goals / Non-Goals

**Goals:**
- Enforce admin vs member permissions consistently across all LiveViews
- Provide structured interview evaluation (scorecards) alongside existing notes
- Automate candidate communication when pipeline stages change
- Make analytics work across multiple pipelines
- Surface where candidates get stuck (time-in-stage)

**Non-Goals:**
- Granular permission system (viewer, interviewer, coordinator, etc.) — 2 roles is enough
- Approval workflows for offers — too enterprise
- SMS notifications — email is sufficient
- AI-generated feedback or scoring
- Integration with external job boards (LinkedIn, Indeed)

## Decisions

### 1. RBAC enforcement via LiveView `on_mount` hook

**Decision**: Create a single `on_mount` hook (`:require_role`) that checks `current_user.role` against a required role. Apply it per-route in the router or per-LiveView. Context functions also check role for defense-in-depth.

**Rationale**: LiveView hooks are the idiomatic Phoenix way to guard routes. Checking at both router and context level prevents bypassing via direct function calls.

**Alternatives considered**:
- Plug-based middleware: Works for controllers but not LiveViews
- Context-only checks: No UI feedback — user fills out a form only to get denied
- Single global hook with per-page config: More complex than needed

### 2. Role permission matrix

**Decision**: Two roles with these permissions:

| Action | Admin | Member |
|---|---|---|
| View candidates, jobs, pipeline | ✅ | ✅ |
| Add/edit notes | ✅ | ✅ |
| Move candidates between stages | ✅ | ✅ |
| Schedule interviews | ✅ | ✅ |
| Create/edit jobs | ✅ | ✅ |
| Create candidates | ✅ | ✅ |
| Edit candidate info | ✅ | ✅ |
| Toggle review state | ✅ | ✅ |
| Manage pipeline stages | ✅ | ❌ |
| Manage custom fields | ✅ | ❌ |
| Manage team (invite/remove) | ✅ | ❌ |
| Manage branding | ✅ | ❌ |
| Manage email templates | ✅ | ❌ |
| Manage scorecard templates | ✅ | ❌ |
| Delete candidates | ✅ | ❌ |
| View analytics | ✅ | ✅ |

**Rationale**: Simple split — admins configure the system, members use it. No granularity needed for small teams.

### 3. Scorecard schema design

**Decision**: Two tables:
- `scorecard_templates`: Admin-defined criteria per tenant (name, criteria as JSON array, position)
- `scorecards`: Filled-out evaluations linked to an interview_event + interviewer (scores as JSON map, recommendation, notes)

Each criteria in the template has: `name` (string), `type` (one of `number_1_5`, `yes_no_maybe`, `text`), `position` (integer).

**Rationale**: JSON for criteria/scores keeps the schema simple. The criteria are small, bounded structures — no need for relational normalization. A single template applies to all interviews in a tenant (not per-pipeline) because small teams don't need that granularity.

**Alternatives considered**:
- Separate tables per criteria type: Over-normalized for this scale
- Per-pipeline templates: Too complex — a startup has one interview process
- Embed templates on interview_event: Can't update templates retroactively

### 4. Scorecard: one per interviewer per interview

**Decision**: Each interviewer fills out exactly one scorecard per interview. If they try to submit again, it updates the existing scorecard (upsert by `interview_event_id + interviewer_id`).

**Rationale**: Prevents duplicate evaluations. Interviewers can revise before the decision meeting.

### 5. Email template schema

**Decision**: `email_templates` table with: `name`, `stage_type` (which stage type triggers it), `subject` (with variable interpolation), `body` (HTML with variable interpolation), `tenant_id`. One template per stage type per tenant (upsert on `stage_type + tenant_id`).

**Variables**: `{candidate_name}`, `{job_title}`, `{company_name}`, `{stage_name}`, `{recruiter_name}`.

**Rationale**: Stage-type trigger (not per-stage) because rejection is rejection regardless of which specific stage. One template per type keeps it simple — no "which template do I use?" confusion.

**Alternatives considered**:
- Per-stage trigger: Too granular — "Rejected from Phone Screen" vs "Rejected from Interview" is the same email
- Template variables via EEx: Security risk (user-controlled code execution). Use simple string replacement instead
- Separate "from" address config: Out of scope — use tenant default

### 6. Triggering stage-based emails

**Decision**: When a user moves a candidate to a stage, if an email template exists for that stage type, show a confirmation dialog with a preview of the email. User can send or skip.

**Rationale**: Auto-sending without confirmation is dangerous (accidental moves). Always letting the user choose respects their workflow. The confirmation dialog is the natural place.

**Alternatives considered**:
- Auto-send always: Risky — accidental moves trigger emails
- Never auto-send, separate "Send email" button: Extra step, defeats the purpose
- Toggle per-stage "auto-send": Configurable but complex — v1 uses confirmation dialog

### 7. Time-in-stage tracking

**Decision**: Compute time-in-stage from the Phase 1 `activity_log` table. Query `application_stage_changed` events, compute duration between consecutive stage entries. No new table needed.

**Rationale**: The activity_log already records stage changes with timestamps. Adding a separate tracking table would be redundant. The computation is O(n) per application where n is the number of stage changes — fast enough for startup scale.

**Alternatives considered**:
- Separate `application_stage_history` table: Redundant with activity_log
- Database triggers: Over-engineered, hard to maintain
- Real-time tracking with GenServer: Massive overkill

### 8. Analytics pipeline selector

**Decision**: Add a pipeline dropdown to `AnalyticsLive.Index`. Pass `pipeline_id` to all analytics queries. Include "All pipelines" option that aggregates across all pipelines.

**Rationale**: The existing analytics page already queries the default pipeline. Refactoring to accept a parameter is straightforward. "All pipelines" is useful for getting a company-wide view.

## Risks / Trade-offs

- **[Risk] RBAC bypass via direct context calls**: Mitigated by adding role checks in context functions, not just LiveViews. Defense in depth.
- **[Risk] Scorecard template changes after scorecards are filled**: Templates are versioned by reference (scorecard stores a snapshot of criteria at fill time). Retroactive template changes don't affect existing scorecards.
- **[Risk] Email template variables XSS**: Mitigated by using simple string replacement on escaped values, not EEx. Candidate names are escaped by Phoenix.HTML.
- **[Risk] Time-in-stage computation with many stage changes**: Acceptable for startup scale. Can add materialized view later if needed.
- **[Trade-off] Single template per stage type**: Can't have different rejection emails for different roles. Acceptable for v1 — small teams send one rejection message.
- **[Trade-off] No email open tracking**: Can't tell if candidates read the email. Out of scope — would require tracking pixels and email service webhooks.
