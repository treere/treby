# Architecture

## Overview

Treby is a standard Phoenix LiveView application with a multi-tenant PostgreSQL database. Each company (tenant) gets isolated data scoped by a `tenant_id` column on all relevant tables. See `lib/treby_web/router.ex:1` for the full route map and `lib/treby/` for contexts.

```
┌───────────────────────────────────────────────────────┐
│                     Browser                            │
│                     ↑ WebSocket                        │
├───────────────────────────────────────────────────────┤
│                   Phoenix Endpoint                     │
│              (Bandit HTTP server)                      │
├──────────┬───────────────────────────┬─────────────────┤
│          │                           │                 │
│  LiveView│   REST Controllers        │  PubSub         │
│  (pages) │   (session, OTP, resume,  │  (real-time     │
│          │    invite, google auth)   │   pipeline)     │
│          │                           │                 │
├──────────┴───────────────────────────┴─────────────────┤
│                  Business Contexts                      │
│  Accounts │ Pipeline │ Interviews │ Scorecards │ Avail. │
│  Tenants  │  Jobs    │  Candidates│ Calendar   │ Portal │
│  Sources  │  CsvImport│ BulkOps  │ Comparison │ Activities│
│  EmailTemplates │ ScheduledMessages │ Customization │ Dashboard │
├────────────────────────────────────────────────────────┤
│                    Ecto / PostgreSQL                    │
│              (multi-tenant, scoped queries)             │
│              binary_id PKs, uc_timestamps              │
├────────────────────────────────────────────────────────┤
│             External Services                           │
│  S3 (resumes/logos) │ Calendar/Meeting providers │ SMTP │
│  Req (HTTP)         │  Oban (jobs) │ Cloak (encryption)│
└────────────────────────────────────────────────────────┘
```

## Key Design Decisions

### Multi-tenancy via scope, not separate databases

Each table has a `tenant_id` foreign key. Queries are scoped via `where(tenant_id: ^current_tenant.id)` in the context layer (e.g. `lib/treby/candidates/candidates.ex:12`, `lib/treby/jobs/jobs.ex`). This keeps deployment simple (single database) while providing data isolation. Tenant resolution happens in `lib/treby_web/plugs/tenant.ex` and the authenticated `live_session` in `lib/treby_web/router.ex:22`.

Multiple **pipelines** per tenant are supported — each `Job` can point at a `pipeline_id` or fall back to the tenant's default pipeline (`lib/treby/pipeline/pipeline.ex:205`). Stages belong to a pipeline, not directly to a tenant.

### LiveView for interactivity

The entire app UI is driven by Phoenix LiveView. There are no REST endpoints for page rendering (controllers exist only for auth/session/OTP/resume/invite/Google). LiveView handles:
- Page navigation (`push_patch` / `push_navigate`)
- Form validation and submission (`to_form/2` + `<.input>` from `core_components.ex`)
- Real-time pipeline updates (drag-and-drop via Sortable.js hook + `Phoenix.PubSub` on `pipeline:#{job_id}` — `lib/treby/pipeline/pipeline.ex:861`)
- Search and filtering (e.g. candidate search via `ilike` in `lib/treby/candidates/candidates.ex:22`)
- Streams for collections (`stream/3` where applicable)

### Session-based auth

Authentication uses Phoenix sessions with BCrypt passwords (`lib/treby/accounts/user.ex`, `lib/treby_web/plugs/auth.ex`). No JWT. Roles are `admin` vs `member`; pipeline-stage role gates (examiner/reviewer/advancer) are enforced in `lib/treby/pipeline/pipeline.ex:342` and `lib/treby_web/hooks/require_role.ex`. Registration uses email OTP verification (`lib/treby/registration_verification/`), password reset via tokens.

### Candidate portal auth (OTP)

Candidates never create passwords. They request a login code by email (6-digit OTP, hashed at rest, 10-minute validity, single-use, rate-limited — `lib/treby/candidate_portal/candidate_otp.ex`) and verify it to open a portal session with a limited lifetime (a few hours) and explicit logout (`lib/treby_web/plugs/candidate_auth.ex`, `lib/treby_web/controllers/candidate_otp_controller.ex`). The portal lives under `/:tenant_slug/portal/*` (`lib/treby_web/router.ex:95`).

### S3 for file storage

Resumes and brand logos are stored in S3-compatible storage (RustFS in dev, any S3 provider in production). Uploads go through `ExAWS` + `Req` with pre-signed URLs (`lib/treby/uploads.ex`). Limits: resume 10 MB (PDF/DOC/DOCX), logo 5 MB (PNG/JPG/SVG) — enforced via `allow_upload` in the respective LiveViews.

### Background jobs

Scheduled portal messages are delivered via **Oban** (`lib/treby/workers/send_scheduled_message.ex`, `lib/treby/scheduled_messages/`). Each scheduled message gets its own Oban job at `send_at` (post-jitter). Retries use exponential backoff; after 5 failures the row is marked `failed`.

## Tech Stack

| Layer | Technology | Notes |
|---|---|---|
| Framework | [Phoenix 1.8](https://www.phoenixframework.org/) with LiveView 1.1 | `mix.exs:43` |
| Language | [Elixir 1.19](https://elixir-lang.org/) / Erlang 28 | `.tool-versions` |
| Database | PostgreSQL (via Ecto 3.13) | `binary_id` PKs, `utc_datetime` |
| HTTP Server | [Bandit 1.5](https://hexdocs.pm/bandit) | `mix.exs:68` |
| Authentication | Session + BCrypt | `bcrypt_elixir`, `lib/treby_web/plugs/auth.ex` |
| File Storage | S3-compatible via ExAWS + Req | `ex_aws_s3`, RustFS in dev |
| Styling | [Tailwind CSS 4](https://tailwindcss.com/) | `@import "tailwindcss" source(none)` in `app.css` |
| Drag & Drop | [Sortable.js](https://sortablejs.github.io/Sortable/) via LiveView hook | `assets/js/` |
| Email | [Swoosh 1.16](https://hexdocs.pm/swoosh) | Mailbox preview at `/dev/mailbox` |
| Real-time | Phoenix PubSub | `pipeline:#{job_id}` topic |
| HTTP Client | [Req 0.5](https://hexdocs.pm/req) | preferred over Tesla/HTTPoison |
| Encryption | Cloak Ecto 1.3 (`Treby.Vault`) | Google tokens, `CLOAK_KEY` env |
| Background Jobs | [Oban 2.19](https://hexdocs.pm/oban) | `scheduled_messages` |
| CSV | [NimbleCSV 1.2](https://hexdocs.pm/nimble_csv) | import pipeline |
| i18n | Gettext (EN, IT) | `priv/gettext`, `SetLocale` plug/hook |
| Search | Ecto + PostgreSQL `ilike` | sufficient for <1k candidates per tenant |

## Data Model (Simplified)

```
Tenants
  ├── Users (admin / member, locale)
  │   ├── CalendarConnections (encrypted Google tokens via Cloak)
  │   └── AvailabilityRules (weekly windows)
  ├── Pipelines (is_default, is_template, stages)
  │   └── PipelineStages (position, color, stage_type, min_examiners, scorecard_template_id)
  │       ├── StageExaminers / StageReviewers / StageAdvancers (role gates)
  │       └── Applications (job_id, candidate_id, stage_id, reviewed, is_duplicate, source, anagrafica)
  │           ├── Notes (type, rating 1-5, author)
  │           └── InterviewEvents (start_at_utc, status, meeting_url, provider)
  │               ├── EventExaminers (join)
  │               └── Scorecards (per examiner, via ScorecardTemplate)
  ├── Jobs (pipeline_id, status, custom_fields)
  ├── Candidates (name, email, phone, linkedin_url, merged_into_id)
  │   ├── MergeLogs / DismissedMergeGroups (duplicate handling)
  │   └── Conversations / Messages (portal threads per application)
  │       └── ScheduledMessages (Oban, jitter, retries, send_at)
  ├── Sources (candidate sources, position)
  ├── CustomFields (per entity type, configurable)
  ├── CareerPages (title, description, primary_color, logo, published)
  ├── EmailTemplates (per stage, variables: {candidate_name} etc.)
  ├── ScorecardTemplates (position, criteria)
  ├── Activities / ActivityLogs (timeline)
  ├── CandidateOtps / RegistrationOtps / PasswordResetTokens (hashed, expiring)
  └── ImportLogs (CSV imports)
```

Primary keys are `binary_id` throughout; see `priv/repo/migrations/` (~30 migrations) and `lib/treby/*/`.

## Request Flow

1. `TrebyWeb.Endpoint` (Bandit) → `TrebyWeb.Router` pipelines (`:browser`, `:require_auth`, `:candidate_auth`)
2. Public routes (`/`, `/:tenant_slug/careers*`) need no auth; `/app/*` requires `TrebyWeb.Plugs.Auth` + `live_session :default`; `/app/settings/*` additionally requires `RequireRole admin`
3. Candidate portal auth is separate: `/:tenant_slug/portal/login|verify` are public OTP endpoints, `/:tenant_slug/portal/*` requires `CandidateAuth`
4. LiveViews mount with `SetLocale` hook for i18n; forms use `to_form/2` + `<.input>`
5. Pipeline moves broadcast via PubSub and log to `Activities`; interview scheduling intersects internal availability with connected provider free/busy
