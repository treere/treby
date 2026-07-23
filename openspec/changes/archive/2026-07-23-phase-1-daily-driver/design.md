## Context

The app is a multi-tenant ATS built with Phoenix LiveView. It already has:
- Dashboard at `/app` showing only a welcome message
- Candidates list at `/app/candidates` with no search or filtering
- Candidate profile at `/app/candidates/:id` with notes, interviews, applications but no edit capability
- Pipeline Kanban at `/app/pipeline/:job_id` with drag-and-drop but no review state
- Analytics at `/app/analytics` with basic metrics
- All context modules: `Candidates`, `Pipeline`, `Interviews`, `Notes`

Multi-tenancy is enforced at query level (all queries filter by `tenant_id`). Real-time updates use Phoenix PubSub. All entities use UUIDs.

## Goals / Non-Goals

**Goals:**
- Hiring manager opens the app and immediately sees what needs attention
- Can search and filter candidates across jobs and stages
- Can fix typos and update candidate info without deleting/recreating
- Can tell at a glance which candidates have been reviewed
- Can see a chronological history of actions on any candidate

**Non-Goals:**
- Notification system (push notifications, email digests) — Phase 2
- Structured scorecards — Phase 2
- Bulk operations — Phase 3
- CSV import — Phase 3
- Real-time dashboard updates via PubSub — the dashboard loads on page visit, refresh is sufficient

## Decisions

### 1. Dashboard data strategy

**Decision**: Compute dashboard data on page load using direct queries. No caching, no background jobs.

**Rationale**: The dataset is small (a startup hiring 1-10 roles at a time, maybe 50-200 candidates). PostgreSQL can answer all dashboard queries in <50ms. Caching adds complexity without benefit at this scale.

**Alternatives considered**:
- ETS caching: Premature optimization for this scale
- PubSub real-time updates: Overkill — hiring managers refresh the page, they don't stare at it
- Background aggregation: No benefit without millions of rows

### 2. Staleness threshold

**Decision**: Candidates are "stale" if no activity (stage change, note, interview) for more than 5 days. Configurable per tenant via `settings` map.

**Rationale**: 5 business days is a reasonable default for startup hiring velocity. Configurable because different roles have different urgency.

**Alternatives considered**:
- Fixed threshold: Too rigid
- Per-stage thresholds: Over-engineered for v1
- No staleness tracking: Defeats the purpose

### 3. Search implementation

**Decision**: `ILIKE` on `candidates.name` and `candidates.email` with a single search input. Server-side filtering via LiveView event.

**Rationale**: Same approach as the job search on public boards. The candidate dataset is small enough that `ILIKE` is fast. No need for full-text search.

**Alternatives considered**:
- PostgreSQL full-text search: Overkill for <1000 candidates
- Client-side filtering: Doesn't scale, breaks with pagination

### 4. Review state

**Decision**: Add a `reviewed` boolean field (default: `false`) to `applications`. Show a visual badge on pipeline cards. Toggle via a single click event.

**Rationale**: Simple, binary state. "I've looked at this" vs "I haven't." No need for granular review states (skipped, bookmarked, etc.) in v1.

**Alternatives considered**:
- Review status enum (new/viewed/skipped/bookmarked): Too complex for v1
- Separate "reviewed_at" timestamp: Boolean is simpler, timestamp can be added later
- Review per-pipeline-view: Wrong granularity — review is per-application, not per-pipeline

### 5. Activity log schema

**Decision**: Single `activity_log` table with `action` (string), `actor_id` (FK to user), `entity_type` (string), `entity_id` (UUID), `metadata` (JSON map), `inserted_at`. Polymorphic design.

**Rationale**: Simple, flexible. The metadata field holds entity-specific data (e.g., old/new stage for moves, note content for notes). No need for separate tables per entity type.

**Alternatives considered**:
- Separate tables per event type: Too many tables, hard to query chronologically
- Event sourcing: Overkill — this is an audit trail, not a state machine
- Embedded schema on each entity: Scatters data, hard to query across entities

### 6. Activity log trigger points

**Decision**: Log events from context functions, not from LiveViews. The context is the single source of truth.

**Rationale**: Ensures all code paths that modify data are logged, regardless of how they're triggered (LiveView, controller, test). Consistent with the existing architecture where context modules own business logic.

**Events to log:**
- `application_created` — when a candidate applies or is added manually
- `application_stage_changed` — when dragged on Kanban (includes old/new stage)
- `note_created` — when a note is added
- `interview_scheduled` — when an interview is booked
- `interview_cancelled` — when an interview is cancelled
- `candidate_created` — when a candidate is created
- `candidate_updated` — when a candidate is edited

### 7. Activity timeline display

**Decision**: Show the 20 most recent events on the candidate profile page. Simple chronological list with relative timestamps ("2 hours ago").

**Rationale**: The candidate profile is the natural place to see history. 20 events covers the typical lifecycle of a candidate. Can add "load more" later.

**Alternatives considered**:
- Separate activity page: Fragmented UX — the candidate profile is the context
- Infinite scroll: Premature optimization
- Real-time updates: Hiring managers don't watch the timeline live

## Risks / Trade-offs

- **[Risk] Dashboard queries get slow with many candidates**: Mitigated by filtering on `tenant_id` and using indexes. Can add caching later if needed.
- **[Risk] Activity log grows unbounded**: Acceptable for v1. Can add retention policies or archival later.
- **[Trade-off] No real-time dashboard**: The dashboard is computed on page load. If a user leaves it open, they won't see new data. Acceptable — hiring managers refresh pages.
- **[Trade-off] Boolean review state only**: No granularity (skipped, bookmarked). Acceptable for v1 — can extend to enum later.
- **[Risk] Search performance with ILIKE on large datasets**: Fine for <1000 candidates. Can add indexes or full-text search later.
