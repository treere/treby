
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

- **Multi-tenant** — each company gets isolated data
- **Customizable pipeline** — drag-and-drop Kanban board with configurable stages
- **Real-time collaboration** — pipeline moves update instantly via Phoenix PubSub
- **Public career pages** — publish branded career pages for external applicants
- **Self-scheduling** — candidates book interviews with internal + optional Google calendar sync
- **Open source** — MIT license, self-hosted, full control

Treby is designed for small businesses and startups (5–50 people, hiring 1–10 roles at a time).

---

## Key Capabilities

### Kanban Pipeline
Drag-and-drop candidates through pipeline stages with real-time updates. Configure stages, colors, and order to match your hiring process.

[Dive into the Pipeline →](/features/pipeline)

### Public Career Pages
Publish branded career pages for each tenant. Customize colors, logo, and description. Candidates apply directly through a polished form with resume upload.

[Learn about Career Pages →](/features/career-pages)

### Candidate Management
Central candidate database with application history, notes, interview feedback, star ratings, and custom fields.

[Explore Candidate Management →](/features/candidate-management)

### Interview Scheduling
Let candidates self-schedule interviews with an always-active internal calendar and optional Google Calendar sync. Automatic timezone handling, availability rules, and automatic meeting links (Google Meet or Jitsi).

[See Interview Scheduling →](/features/interview-scheduling)

### Analytics Dashboard
Pipeline overview, conversion rates, and hiring metrics. Track time-to-hire and candidate distribution across stages.

[View Analytics →](/features/analytics)

### Email Notifications
Automated email notifications for pipeline events. Stage-based templates, interview confirmations, and team invitations via Swoosh.

[See Email Notifications →](/features/email-notifications)

---

## Tech Stack

| Layer | Technology |
|---|---|
| Framework | [Phoenix 1.8](https://www.phoenixframework.org/) with LiveView |
| Language | [Elixir](https://elixir-lang.org/) |
| Database | PostgreSQL (via Ecto) |
| Authentication | Session-based with BCrypt |
| File Storage | S3-compatible (MinIO) via ExAWS |
| Styling | [Tailwind CSS](https://tailwindcss.com/) |
| Drag & Drop | [Sortable.js](https://sortablejs.github.io/Sortable/) via LiveView hook |
| Email | [Swoosh](https://hexdocs.pm/swoosh) |
| Real-time | Phoenix PubSub |
| HTTP Client | [Req](https://hexdocs.pm/req) |

---

Ready to get started? [Set up Treby locally →](/getting-started)
