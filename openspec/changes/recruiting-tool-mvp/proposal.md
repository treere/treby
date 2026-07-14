## Why

Startups need a recruiting tool that's simple, open-source, and customizable. Existing solutions like Ashby are closed-source, complex, and expensive. There's a gap for a lightweight ATS that startups can self-host or use as a hosted service, with the flexibility to adapt to their unique hiring workflows.

## What Changes

Build the core MVP of Treby — a multi-tenant recruiting tool with:

- **Multi-tenant architecture** — Tenant isolation via tenant_id on all tables, supporting both hosted (multi-tenant) and self-hosted (single-tenant) deployments
- **Authentication** — Email + password login, session management, tenant-scoped access
- **Job management** — Create/edit job postings with title, description, salary range, and status
- **Candidate management** — Track candidates with contact info, resume, and custom fields
- **Pipeline (Kanban)** — Visual drag-and-drop board for moving candidates through customizable stages
- **Applications** — Link candidates to jobs with stage tracking and resume storage
- **Notes** — Interview feedback and comments, visible to all team members
- **Career page** — Public job listings with customizable branding (logo, colors)
- **Application form** — Public form that auto-creates candidates and adds them to pipeline
- **File upload** — S3/MinIO storage for resumes and logos
- **Custom fields** — JSONB-based flexible fields on candidates, jobs, and applications
- **Team management** — Admin invites members via email, role-based access (admin, member)
- **Analytics** — Pipeline counts, time-to-hire, stage conversion metrics
- **Branding** — Customizable career page with logo, colors, and text

## Capabilities

### New Capabilities
- `multi-tenancy`: Tenant data model, scoping, slug-based routing for career pages
- `authentication`: Email + password auth, sessions, login/register flows
- `job-management`: CRUD for job postings with title, description, salary range, status
- `candidate-management`: CRUD for candidates with contact info and profile data
- `pipeline`: Kanban board with drag-and-drop stage transitions via SortableJS
- `applications`: Links candidates to jobs, tracks pipeline stage, stores resume URL
- `notes`: Comments and interview feedback on applications, visible to all team members
- `career-page`: Public job listings with tenant branding, application submission flow
- `file-upload`: S3/MinIO integration for resume and logo storage
- `custom-fields`: Configurable fields on candidates, jobs, and applications via JSONB
- `team-management`: User invites via email, role-based access control (admin, member)
- `analytics`: Pipeline metrics, time-to-hire, stage conversion rates
- `branding`: Customizable career page appearance (logo, primary color, text)

### Modified Capabilities
None — this is a new feature set.

## Impact

### New Dependencies
- `bcrypt_elixir` ~> 3.0 — Password hashing
- `ex_aws` ~> 2.5, `ex_aws_s3` ~> 2.5, `nimble_aws` ~> 1.0, `hackney` ~> 1.20 — S3 file storage
- SortableJS — Vendor'd to `assets/vendor/` for drag-and-drop

### Infrastructure
- MinIO added to `docker-compose.yml` for S3-compatible object storage
- PostgreSQL database schema: ~10 new tables (tenants, users, jobs, candidates, applications, notes, pipeline_stages, custom_fields, invites, career_pages)

### Code Structure
New context modules under `lib/treby/`:
- `accounts/` — Tenants, users, auth, invites
- `jobs/` — Job CRUD
- `candidates/` — Candidate CRUD
- `pipeline/` — Pipeline stages, applications
- `notes/` — Notes and feedback
- `careers/` — Public career pages, application submission
- `customization/` — Custom fields, branding settings
- `uploads/` — S3 file upload handling

New LiveViews under `lib/treby_web/live/`:
- Auth: `LoginLive`, `RegisterLive`, `InviteLive`
- App: `DashboardLive`, `JobsLive`, `CandidatesLive`, `PipelineLive`, `AnalyticsLive`, `SettingsLive`
- Public: `CareersLive`

### Affected Files
- `mix.exs` — New dependencies
- `docker-compose.yml` — MinIO service
- `lib/treby_web/router.ex` — New routes (public + authenticated)
- `config/config.exs` — S3/MinIO configuration
- `config/runtime.exs` — Production S3 config
