## Context

The app is a multi-tenant ATS (Applicant Tracking System) built with Phoenix LiveView. It already has:
- A per-tenant public career page (`/:tenant_slug/careers`) with job listing, detail, and application form
- Jobs with `status` (open/closed) but no per-job visibility control
- No search functionality on public pages
- No global board across tenants
- Internal job management at `/app/jobs`

The public pages use a root scope (no auth) and resolve tenants from the URL slug. Authenticated pages use a `:require_auth` plug pipeline.

## Goals / Non-Goals

**Goals:**
- Per-job visibility control (`visible` boolean) separate from status
- Global job board at `/careers` showing jobs from all tenants
- Simple text search on public boards (title + description)
- Enhanced job detail with company branding (logo, name, description)
- "Position not found" page for closed jobs
- Copy-public-link button on internal job detail page
- Visibility toggle on internal job listing

**Non-Goals:**
- Advanced search filters (location, salary range, etc.) — future enhancement
- Job alerts or notifications
- Application tracking from the public side
- Multi-language support for public boards (inherits current locale system)

## Decisions

### 1. `visible` field on Job schema

**Decision**: Add a `visible` boolean field (default: `true`) to the `jobs` table via migration.

**Rationale**: Existing jobs should be visible by default. The `visible` flag controls listing visibility; the direct link always works for open jobs regardless of `visible`.

**Alternatives considered**:
- Separate `career_page` flag: Too coarse — controls entire page, not individual jobs
- Using `status` for visibility: Conflates "is the position open" with "should it appear publicly"

### 2. Search implementation

**Decision**: Simple `ILIKE` query on `title` and `description` fields using Ecto. No full-text search engine.

**Rationale**: The dataset is small (jobs per tenant or across tenants). PostgreSQL `ILIKE` is sufficient and avoids new dependencies. For a global board, we query across all tenants.

**Alternatives considered**:
- PostgreSQL full-text search (`tsvector`): Overkill for this scale
- External search service (Meilisearch, Elasticsearch): Too heavy for current needs

### 3. Global board architecture

**Decision**: New route `/careers` → `CareersLive.GlobalIndex` that queries all visible open jobs across tenants, with tenant info preloaded.

**Rationale**: Keeps the per-tenant and global boards as separate LiveViews with different data sources. The global board joins jobs with tenant data for company info display.

**Alternatives considered**:
- Single LiveView with conditional data loading: More complex, harder to maintain
- API-based approach: Unnecessary for server-rendered LiveView

### 4. "Not found" for closed jobs

**Decision**: In `CareersLive.Show`, if the job is closed, render a "Position not found" message instead of the job detail.

**Rationale**: Simple and clean. No redirect needed — the page loads but shows the not-found state. This avoids leaking information about closed positions.

### 5. Copy link implementation

**Decision**: Use a JavaScript hook with `navigator.clipboard.writeText()` triggered by a LiveView event. The URL is constructed from the tenant slug and job ID.

**Rationale**: Native clipboard API is widely supported. The hook pattern is idiomatic in LiveView.

### 6. Search UX

**Decision**: Search input on the public board pages. On submit (or debounce), filter the job list via a LiveView event that queries the database.

**Rationale**: Keeps it simple — no client-side filtering, always server-side. Works with pagination if added later.

## Risks / Trade-offs

- **[Risk] Global board performance with many tenants**: Mitigated by limiting to visible + open jobs and using efficient queries. Can add pagination later.
- **[Risk] Search relevance with ILIKE**: Simple substring match may not be ideal. Acceptable for v1; can upgrade to full-text search later.
- **[Trade-off] No client-side search**: Every keystroke (or submit) hits the server. Acceptable for the expected load.
- **[Risk] Closed jobs accessible via direct link**: We show "not found" but the URL still works. This is intentional — avoids broken links in shared URLs.
