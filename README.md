# Treby

A multi-tenant **Applicant Tracking System (ATS)** built with [Phoenix LiveView](https://www.phoenixframework.org/). Treby helps companies manage job postings, track candidates through customizable hiring pipelines, review applications with notes and ratings, and publish public career pages.

![Dashboard](docs/screenshots/04-dashboard.png)

## Table of Contents

- [Features](#features)
- [Getting Started](#getting-start)
- [Authentication](#authentication)
- [Public Career Pages](#public-career-pages)
- [Job Management](#job-management)
- [Candidate Management](#candidate-management)
- [Pipeline Board](#pipeline-board)
- [Analytics](#analytics)
- [Settings](#settings)
- [Tech Stack](#tech-stack)

## Features

- **Multi-tenant architecture** — each company gets isolated data
- **Customizable hiring pipeline** — drag-and-drop Kanban board with configurable stages
- **Job postings** — create, manage, and close/open positions
- **Candidate tracking** — central candidate database with application history
- **Notes & feedback** — add notes, interview feedback, and ratings (1-5 stars) per application
- **Public career pages** — publish branded career pages for external applicants
- **Resume uploads** — candidates can upload resumes (PDF/DOC/DOCX) via the public application form
- **Custom fields** — define custom metadata for candidates, jobs, and applications
- **Team management** — invite team members, assign roles (admin/member)
- **Analytics dashboard** — pipeline overview, conversion rates, and hiring metrics
- **Real-time pipeline** — candidates can be moved between stages with live updates via PubSub

## Getting Started

### Prerequisites

- Elixir 1.14+
- PostgreSQL
- S3-compatible storage (MinIO for development)

### Setup

```bash
# Install dependencies and set up the database
mix setup

# Start the Phoenix server
mix phx.server
```

Visit [`http://localhost:4000`](http://localhost:4000) in your browser.

### Seed Data

Running `mix setup` seeds the database with demo data for **Acme Corp** (`acme`):

| Email | Password | Role |
|-------|----------|------|
| `admin@acme.com` | `password123` | Admin |
| `member@acme.com` | `password123` | Member |

Pre-loaded content:
- 3 job postings (Senior Elixir Developer, Product Designer, DevOps Engineer)
- 10 candidates with applications across pipeline stages
- 6 pipeline stages (New → Screen → Phone Screen → Interview → Offer → Hired)
- Published career page at `/acme/careers`

---

## Authentication

### Login

![Login Page](docs/screenshots/03-login-page.png)

Users sign in with their email and password. The session is managed server-side via Phoenix sessions.

### Registration

![Registration Page](docs/screenshots/19-register-page.png)

New companies can register by providing:
- **Company Name** — display name for the organization
- **Company Slug** — URL-safe identifier used in public career page URLs (e.g., `acme`)
- **Your Name** — the admin user's full name
- **Email** — login credential (unique per tenant)
- **Password** — account password

Registration creates both a new tenant and an admin user in a single transaction.

### Team Invitations

Admins can invite team members from **Settings → Team**. Invitations are sent via email and include a unique token link. Invited users set their name and password through the invite link.

![Team Settings](docs/screenshots/13-settings-team.png)

---

## Public Career Pages

Each tenant can publish a branded career page accessible at `/:tenant_slug/careers`.

### Careers Listing

![Public Careers Page](docs/screenshots/16-public-careers.png)

The careers page displays:
- Company title and description (customizable in Settings → Branding)
- All open job postings with salary ranges
- Styled with the tenant's primary brand color

### Job Detail

![Public Job Detail](docs/screenshots/17-public-job-detail.png)

Each job listing shows the full description, salary range, and an **Apply Now** button.

### Application Form

![Application Form](docs/screenshots/18-apply-form.png)

External candidates can apply directly through the public form:
- Full name, email, phone number
- Resume upload (PDF, DOC, DOCX — max 10MB)
- Custom application fields (if configured)

Applications are automatically placed in the first pipeline stage. Duplicate candidates are deduplicated by email address.

---

## Job Management

### Jobs Listing

![Jobs List](docs/screenshots/05-jobs-list.png)

The Jobs page displays all postings in a table with:
- **Title** — links to the pipeline view
- **Salary** — salary range string
- **Status** — `open` or `closed`
- **Actions** — Pipeline link, Close/Reopen toggle

Filter by **All**, **Open**, or **Closed** jobs using the toggle buttons.

### Creating a Job

![New Job Form](docs/screenshots/06-new-job-form.png)

Click **+ New Job** to expand the inline creation form:
- Title
- Description
- Salary Range (e.g., `$100k-$150k`)

### Job Detail

![Job Detail](docs/screenshots/22-job-detail.png)

The job detail page shows the full description, salary, status, creation date, and any custom fields. An inline edit form allows updating all fields. Custom fields defined in Settings → Fields appear automatically.

---

## Candidate Management

### Candidates Listing

![Candidates List](docs/screenshots/08-candidates-list.png)

The Candidates page shows all candidates with:
- Name (links to detail page)
- Email
- Phone
- Number of applications
- Delete action

### Adding a Candidate

![Add Candidate Form](docs/screenshots/21-add-candidate-form.png)

Click **+ Add Candidate** to open the creation form with fields for name, email, phone, LinkedIn URL, and any custom candidate fields.

### Candidate Detail

![Candidate Detail](docs/screenshots/09-candidate-detail.png)

The candidate detail page shows:
- Contact information (name, email, phone, LinkedIn)
- All applications with job title and current pipeline stage
- Notes and feedback per application with star ratings
- Custom fields

### Adding Notes

![Add Note Form](docs/screenshots/20-add-note-form.png)

Click **Add Note** on any application to leave feedback:
- **Type** — Note or Interview Feedback
- **Rating** — optional 1-5 star rating
- **Content** — free-text note

Authors can delete their own notes.

---

## Pipeline Board

![Pipeline Kanban Board](docs/screenshots/07-pipeline-kanban.png)

The pipeline view is a **Kanban-style board** for each job posting:

- **Columns** represent pipeline stages (New, Screen, Phone Screen, Interview, Offer, Hired)
- **Cards** show candidate name and email
- **Drag-and-drop** moves candidates between stages (uses Sortable.js via a Phoenix LiveView hook)
- **Real-time updates** — all connected users see moves instantly via Phoenix PubSub
- **Counts** displayed per stage header

---

## Analytics

![Analytics Dashboard](docs/screenshots/10-analytics.png)

The Analytics page provides hiring metrics:

- **Total Candidates** — count of all candidates in the tenant
- **Avg. Time to Hire** — average days from application to hired (based on `updated_at - inserted_at` for hired applications)
- **Active Jobs** — count of open job postings
- **Pipeline Overview** — horizontal bar chart showing candidate counts per stage across all jobs
- **Stage Conversion Rates** — percentage of candidates progressing from one stage to the next

---

## Settings

![Settings Hub](docs/screenshots/11-settings.png)

The Settings page provides navigation to four configuration areas:

### Pipeline Stages

![Pipeline Settings](docs/screenshots/12-settings-pipeline.png)

Manage the stages of your hiring pipeline:
- View all stages with color, name, and position
- Create new stages with a custom color and position number
- Edit existing stages
- Cannot delete stages that have active applications

### Custom Fields

![Custom Fields Settings](docs/screenshots/14-settings-fields.png)

Define additional metadata fields that appear on candidate, job, or application forms:

| Field Type | Description |
|-----------|-------------|
| `text` | Free-text input |
| `number` | Numeric input |
| `date` | Date picker |
| `select` | Dropdown with configurable options |
| `url` | URL input |

Each field can be marked as **required** and assigned a display **position** for ordering.

### Team Management

![Team Settings](docs/screenshots/13-settings-team.png)

- View all team members with name, email, and role
- Remove team members (cannot remove yourself)
- Send invitations with a chosen role (admin or member)
- View pending invitations with expiration dates and revoke option

### Branding

![Branding Settings](docs/screenshots/15-settings-branding.png)

Customize the public career page appearance:
- **Page Title** — heading displayed on the careers page
- **Description** — company description shown below the title
- **Primary Color** — accent color for the career page (color picker)
- **Logo** — upload a logo (PNG/JPG/SVG, max 5MB)
- **Published** — toggle visibility of the public career page

A live preview panel shows how the career page header will look with your current settings.

---

## Tech Stack

| Layer | Technology |
|-------|-----------|
| Framework | [Phoenix 1.8](https://www.phoenixframework.org/) with LiveView |
| Language | [Elixir](https://elixir-lang.org/) |
| Database | PostgreSQL (via Ecto) |
| Authentication | Session-based with BCrypt |
| File Storage | S3-compatible (MinIO in dev) via ExAWS |
| Styling | [Tailwind CSS](https://tailwindcss.com/) |
| Drag & Drop | [Sortable.js](https://sortablejs.github.io/Sortable/) via LiveView hook |
| Email | [Swoosh](https://hexdocs.pm/swoosh) |
| HTTP Client | [Req](https://hexdocs.pm/req) |

---

## Learn More

- Official website: https://www.phoenixframework.org/
- Guides: https://hexdocs.pm/phoenix/overview.html
- Docs: https://hexdocs.pm/phoenix
- Forum: https://elixirforum.com/c/phoenix-forum
- Source: https://github.com/phoenixframework/phoenix
