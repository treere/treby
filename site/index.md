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

- **Isolated per company** — each company sees only its own data
- **Customizable pipelines** — multiple pipelines per company, drag & drop board, configurable stages and colors
- **Real-time collaboration** — moves update instantly for the whole team
- **Public career pages** — publish branded career pages
- **Candidate portal** — email code access, self-scheduling, conversations, and notification preferences
- **Interviews without email ping-pong** — weekly internal availability + optional Google Calendar, automatic Jitsi/Google Meet links
- **Teamwork** — per-stage roles (examiner/reviewer/advancer), gated scorecards, bulk operations, and CSV import
- **Open source** — MIT license, self-hosted, full control

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

Treby is a modern web application: it runs in the browser, stores data in a database, and integrates with file storage and email. To learn how it works under the hood, see [How Treby Works →](/architecture).

---

Ready to get started? [Set up Treby locally →](/getting-started)
