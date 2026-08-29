# Treby

**Open-source Applicant Tracking System** built with [Phoenix LiveView](https://www.phoenixframework.org/).

Manage job postings, track candidates through customizable hiring pipelines, review applications with notes and ratings, and publish public career pages — all in one place.

<div class="flex gap-4" style="margin: 2rem 0;">
  <a href="/getting-started" class="VPButton medium brand">Get Started</a>
  <a href="/features/" class="VPButton medium alt">Explore Features</a>
</div>

![Dashboard Screenshot](/screenshots/04-dashboard.png)

---

## Why Treby?

- **Multi-tenant** — each company gets isolated data (scoped `tenant_id`)
- **Customizable pipelines** — multiple pipelines per tenant, drag-and-drop Kanban, stage types & colors
- **Real-time collaboration** — pipeline moves broadcast via Phoenix PubSub
- **Public career pages** — publish branded career pages per tenant
- **Candidate portal** — OTP login, self-scheduling, threaded conversations, notification prefs
- **Self-scheduling** — internal weekly availability + optional Google Calendar sync, Jitsi/Google Meet links
- **Team workflows** — examiner/reviewer/advancer roles, scorecard gating, bulk ops, CSV import
- **Open source** — MIT, self-hosted, full control

Treby is designed for small businesses and startups (5–50 people, hiring 1–10 roles at a time).

---

## Key Capabilities

### Kanban Pipeline
Drag-and-drop candidates through pipeline stages with role-based access, scorecard gating, and rejection workflows.

[Dive into the Pipeline →](/features/pipeline)

### Public Career Pages
Publish branded career pages for each tenant. Customize colors, logo, and description. Candidates apply directly through a polished form with resume upload.

[Learn about Career Pages →](/features/career-pages)

### Candidate Management
Central candidate database with application history, notes, interview feedback, star ratings, custom fields, duplicate merging, and comparison.

[Explore Candidate Management →](/features/candidate-management)

### Candidate Portal
Self-service portal where candidates track status, book interviews, converse with recruiters, and manage notification preferences — OTP-secured.

[Explore the Portal →](/features/candidate-portal)

### Interview Scheduling
Let candidates self-schedule interviews with an always-active internal calendar and optional Google Calendar sync. Overlapping availability for multiple examiners, automatic timezone handling, and automatic meeting links (Google Meet or Jitsi).

[See Interview Scheduling →](/features/interview-scheduling)

### Scorecards
Structured evaluation per interview with configurable templates and criteria, completion gating for advancement.

[See Scorecards →](/features/scorecards)

### Analytics Dashboard
Pipeline overview, conversion rates, time-in-stage, and source breakdown — with per-pipeline selector.

[View Analytics →](/features/analytics)

### Email & Portal Messages
Email is OTP + notification pings only; all content lives in the portal with per-stage message templates and a scheduled queue.

[See Email →](/features/email-notifications) · [See Message Scheduler →](/features/message-scheduler)

### Import & Bulk Ops
CSV import with column mapping and source tagging, bulk move/review/delete, and side-by-side candidate comparison.

[CSV Import →](/features/csv-import) · [Bulk Ops →](/features/bulk-operations) · [Comparison →](/features/comparison)

---

## Tech Stack

| Layer | Technology |
|---|---|
| Framework | [Phoenix 1.8](https://www.phoenixframework.org/) with LiveView 1.1, Bandit |
| Language | [Elixir 1.19](https://elixir-lang.org/) / Erlang 28 |
| Database | PostgreSQL (via Ecto) — `binary_id` PKs |
| Authentication | Session + BCrypt (recruiters); OTP (candidates, registration); Cloak for Google tokens |
| File Storage | S3-compatible (RustFS) via ExAWS + Req |
| Styling | [Tailwind CSS 4](https://tailwindcss.com/) + esbuild |
| Drag & Drop | [Sortable.js](https://sortablejs.github.io/Sortable/) via LiveView hook |
| Email | [Swoosh](https://hexdocs.pm/swoosh) |
| Real-time | Phoenix PubSub |
| Background Jobs | [Oban](https://hexdocs.pm/oban) |
| HTTP Client | [Req](https://hexdocs.pm/req) |
| i18n | Gettext (EN, IT) |
| CSV | NimbleCSV |

See [Architecture →](/architecture) for the full diagram and data model.

---

Ready to get started? [Set up Treby locally →](/getting-started)
