## Context

Treby is a new open-source recruiting tool for startups. The project currently has a basic Phoenix LiveView setup with PostgreSQL, Tidewave, and Docker Compose. No business logic exists yet — this is a greenfield implementation of the core product.

The goal is to build a multi-tenant ATS that's simpler and more customizable than Ashby, with support for both hosted (SaaS) and self-hosted deployments.

## Goals / Non-Goals

**Goals:**
- Multi-tenant data isolation with tenant_id on all tables
- Self-hosted and hosted modes from a single codebase
- Real-time Kanban board with drag-and-drop
- Public career page with customizable branding
- File storage for resumes and logos via S3/MinIO
- Team invites via email
- Basic analytics without complex infrastructure

**Non-Goals:**
- Email/calendar integrations (Gmail, Outlook, Google Calendar)
- Slack notifications
- Sourcing or email sequences
- HRIS integrations
- Mobile apps
- Advanced analytics (BI dashboards, data warehouse)
- Multi-language support (i18n)

## Decisions

### 1. Multi-tenancy: Shared schema with tenant_id

**Decision:** Every table gets a `tenant_id` column. All queries filter by tenant_id.

**Rationale:**
- Simplest to implement and understand
- Works for both hosted (many tenants, one DB) and self-hosted (one tenant, one DB)
- No schema prefix complexity or dynamic repo management
- Standard pattern used by most SaaS applications

**Alternatives considered:**
- PostgreSQL schemas per tenant: Rejected — migration complexity, harder to query across tenants for analytics
- Separate databases per tenant: Rejected — maximum complexity, overkill for startups

**Implementation:**
```elixir
# Every context function takes tenant as first argument
def list_jobs(%Tenant{} = tenant) do
  Repo.all(from j in Job, where: j.tenant_id == ^tenant.id)
end
```

### 2. Tenant routing: Path-based for career pages

**Decision:** Career pages use `/:tenant_slug/careers` URL pattern. Authenticated routes use session-based tenant identification.

**Rationale:**
- Career pages are public — need tenant identification in URL
- Authenticated users already have tenant in session — no URL prefix needed
- Simpler than subdomain routing (no DNS configuration required)
- Self-hosted users just use their company slug

**Implementation:**
```elixir
# Public career pages
scope "/:tenant_slug" do
  live "/careers", CareersLive.Index
end

# Authenticated routes (tenant from session)
scope "/app" do
  live "/jobs", JobsLive.Index
end
```

### 3. Auth: Email + password with bcrypt

**Decision:** Email + password authentication using bcrypt_elixir for hashing.

**Rationale:**
- Simplest auth flow for startups
- No OAuth dependency (Google, GitHub)
- bcrypt is well-tested and secure
- Session-based auth via Phoenix built-in session plug

**Implementation:**
- Password hashed with bcrypt on registration
- Session stored in signed cookie
- Auth plug checks session for user_id and tenant_id
- All LiveViews mount with tenant from session

### 4. File storage: S3/MinIO with server-side upload

**Decision:** Files uploaded server-side to S3/MinIO. No presigned URLs for MVP.

**Rationale:**
- Simpler implementation (LiveView handles upload, server stores to S3)
- Resumes are typically < 10MB — server-side is fine
- MinIO provides S3-compatible storage for self-hosted
- No need for client-side upload complexity

**Implementation:**
```elixir
# LiveView handles upload
def handle_event("save", %{"job" => job_params}, socket) do
  {:ok, filename} = Uploads.store(socket.assigns.current_user, :resume, file)
  # ... create application with resume_url = filename
end
```

### 5. Drag-and-drop: SortableJS with simplified position tracking

**Decision:** SortableJS for drag-and-drop. MVP tracks stage changes only, not position within stages.

**Rationale:**
- SortableJS is battle-tested, 10KB, works with LiveView hooks
- Position tracking adds significant complexity (reordering adjacent cards)
- Stage changes are the core value — position is cosmetic
- Can add position tracking in a future iteration

**Implementation:**
```javascript
// LiveView hook
export default {
  mounted() {
    this.el.querySelectorAll('.stage-column').forEach(column => {
      new Sortable(column, {
        group: 'pipeline',
        animation: 150,
        onEnd: (evt) => {
          this.pushEvent('move_candidate', {
            application_id: evt.item.dataset.applicationId,
            new_stage_id: evt.to.dataset.stageId
          })
        }
      })
    })
  }
}
```

### 6. Custom fields: JSONB columns with database-defined schema

**Decision:** Custom fields defined in a `custom_fields` table, values stored in JSONB columns on target tables.

**Rationale:**
- JSONB is flexible and queryable in PostgreSQL
- Custom field definitions in DB — no code changes to add fields
- Application form dynamically renders custom fields based on definitions
- Validation happens at application level, not DB level

**Implementation:**
```elixir
# Custom field definition
%CustomField{
  name: "GitHub URL",
  field_type: "url",
  applies_to: "candidate",
  required: false
}

# Stored in candidate.custom_fields
%{github_url: "https://github.com/johndoe"}
```

### 7. Team invites: Token-based with email via Swoosh

**Decision:** Admin creates invite, system sends email with token link, invitee registers via link.

**Rationale:**
- Swoosh already included — no new dependencies
- Token-based invites are simple and secure
- Invitee creates account with pre-filled email and role
- Invites expire after 7 days

**Implementation:**
```elixir
# Invite flow
1. Admin enters email + role
2. System creates Invite record with token
3. System sends email with /invites/:token link
4. Invitee clicks link, sees registration form
5. Invitee enters name + password
6. Account created, linked to tenant
```

### 8. Analytics: Simple SQL queries, no data warehouse

**Decision:** Analytics computed via SQL queries on existing tables. No separate analytics infrastructure.

**Rationale:**
- MVP doesn't need real-time analytics
- SQL queries on indexed tables are fast enough for startup scale
- No additional infrastructure (Kafka, ClickHouse, etc.)
- Can add dedicated analytics later if needed

**Implementation:**
- Pipeline counts: GROUP BY stage per job
- Time-to-hire: AVG difference between applied_at and hired_at
- Stage conversion: Count candidates who moved from stage A to B

### 9. Career page: Dedicated career_pages table

**Decision:** Career page settings stored in a dedicated `career_pages` table with structured fields.

**Rationale:**
- Normalized schema with proper types and constraints (better than JSONB for this use case)
- Dedicated fields: `title`, `description`, `logo_url`, `primary_color`, `published`
- Type-safe queries and validations
- Cleaner API than drilling into JSONB

**Implementation:**
```elixir
# CareerPage schema
%CareerPage{
  title: "Join our team",
  description: "Help us build the future...",
  logo_url: "/uploads/logos/acme.png",
  primary_color: "#3b82f6",
  published: true
}
```

## Risks / Trade-offs

**[Risk] JSONB querying complexity** → Mitigation: Use PostgreSQL GIN indexes on JSONB columns. Keep custom field access patterns simple (equality checks, not complex joins).

**[Risk] SortableJS + LiveView sync issues** → Mitigation: Use optimistic UI updates. Server confirms stage change, client re-renders if needed.

**[Risk] File upload size limits** → Mitigation: Validate file size in LiveView before upload. Set max size to 10MB for resumes, 5MB for logos.

**[Risk] Multi-tenant data leakage** → Mitigation: Every context function takes tenant as first argument. Enforce at query level, not just controller level. Add integration tests for tenant isolation.

**[Career page SEO]** → Career pages are public but not SEO-optimized. Can add meta tags later if needed.

**[Email delivery]** → Swoosh local adapter in dev, needs SMTP provider in production. Document recommended providers (Mailgun, Postmark, Resend).

## Migration Plan

1. **Database migrations** — Create all tables in order: tenants → users → pipeline_stages → jobs → candidates → applications → notes → custom_fields → invites → career_pages
2. **Docker Compose** — Add MinIO service alongside PostgreSQL
3. **Dependencies** — Add bcrypt_elixir, ex_aws, ex_aws_s3, nimble_aws, hackney to mix.exs
4. **Seed data** — Default tenant with pipeline stages on first run
5. **Assets** — Download SortableJS to assets/vendor/, import in app.js

## Open Questions

- **Resume download**: Should candidates/ recruiters download resumes from S3, or just view? (MVP: view only via presigned URL)
- **Application status email**: Should we send confirmation email when candidate applies? (Not in scope — no notifications)
- **Job closing**: Should closing a job hide it from career page? (Yes — status = closed means hidden)
