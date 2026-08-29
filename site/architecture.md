
# Architecture

## Overview

Treby is a standard Phoenix LiveView application with a multi-tenant PostgreSQL database. Each company (tenant) gets isolated data scoped by a `tenant_id` column on all relevant tables.

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
│  (pages) │   (webhooks, API)         │  (real-time)    │
│          │                           │                 │
├──────────┴───────────────────────────┴─────────────────┤
│                  Business Contexts                      │
│  Accounts │ Hiring │ Pipeline │ Analytics │ Interviews  │
├────────────────────────────────────────────────────────┤
│                    Ecto / PostgreSQL                    │
│              (multi-tenant, scoped queries)             │
├────────────────────────────────────────────────────────┤
│             External Services                           │
│  S3 (resumes) │ Calendar/Meeting providers │ SMTP (OTP + pings) │
└────────────────────────────────────────────────────────┘
```

## Key Design Decisions

### Multi-tenancy via scope, not separate databases

Each table has a `tenant_id` foreign key. Queries are scoped via `where(tenant_id: ^current_tenant.id)` in the context layer. This keeps deployment simple (single database) while providing data isolation.

### LiveView for interactivity

The entire UI is driven by Phoenix LiveView. There are no REST endpoints for page rendering. LiveView handles:
- Page navigation (push_patch / push_navigate)
- Form validation and submission
- Real-time pipeline updates (drag-and-drop via Sortable.js hook + PubSub)
- Search and filtering

### Session-based auth

Authentication uses Phoenix sessions with BCrypt passwords. No JWT, no OAuth (for now). Sessions are scoped to tenants.

### Candidate portal auth (OTP)

Candidates never create passwords. They request a login code by email (6-digit OTP, hashed at rest, 10-minute validity, single-use, rate-limited) and verify it to open a portal session with a limited lifetime (a few hours) and explicit logout.

### S3 for file storage

Resumes and brand logos are stored in S3-compatible storage (MinIO in dev, any S3 provider in production). Uploads go through ExAWS with pre-signed URLs.

## Tech Stack

| Layer | Technology |
|---|---|
| Framework | [Phoenix 1.8](https://www.phoenixframework.org/) with LiveView |
| Language | [Elixir](https://elixir-lang.org/) |
| Database | PostgreSQL (via Ecto) |
| Authentication | Session-based with BCrypt |
| File Storage | S3-compatible via ExAWS |
| Styling | [Tailwind CSS](https://tailwindcss.com/) |
| Drag & Drop | [Sortable.js](https://sortablejs.github.io/Sortable/) via LiveView hook |
| Email | [Swoosh](https://hexdocs.pm/swoosh) |
| Real-time | Phoenix PubSub |
| HTTP Client | [Req](https://hexdocs.pm/req) |
| Encryption | Cloak (Google token encryption) |
| Background Jobs | Oban (scheduled portal messages) |

## Data Model (Simplified)

```
Tenants
  ├── Users (admin / member)
  ├── Jobs
  │   ├── Applications
  │   │   ├── Notes (with star ratings)
  │   │   └── Interview Events
  │   └── Pipeline Stages (configurable order & color)
  ├── Candidates (shared across jobs)
  ├── Custom Fields (per entity type)
  └── Message Templates (per stage)
```
