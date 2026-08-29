# Treby

**Multi-tenant Applicant Tracking System (ATS)** built with [Phoenix LiveView](https://www.phoenixframework.org/).

Treby helps companies manage job postings, track candidates through customizable hiring pipelines, review applications with notes and ratings, and publish public career pages. Candidates use a self-service portal (OTP login) to track status, self-schedule interviews, and converse with recruiters.

> **Full documentation and feature showcase available at [treere.github.io/treby](https://treere.github.io/treby)**
> Includes screenshots, architecture overview, and step-by-step setup guide.

---

## Quick Start

### Prerequisites

- Elixir 1.19+ / Erlang 28+ (see `.tool-versions`)
- PostgreSQL 14+
- S3-compatible storage — MinIO for development (via `docker-compose.yml`)
- Node.js 18+ (assets + docs site)

### Setup

```bash
mix setup
mix phx.server
```

Visit [`http://localhost:4000`](http://localhost:4000).

With Docker for Postgres + MinIO:

```bash
docker compose up -d
mix setup
mix phx.server
```

### Seed Data

`mix setup` seeds demo data for **Acme Corp** (`acme`):

| Email | Password | Role |
|---|---|---|
| `admin@acme.com` | `password123` | Admin |
| `member@acme.com` | `password123` | Member |

Pre-loaded: 3 jobs, 10 candidates + 6 duplicate-profile fixtures for the merge center, 7 pipeline stages (New → … → Rejected), published career page at `/acme/careers`.

### Environment variables & secrets

Treby reads its configuration from environment variables (see `config/runtime.exs`
and `config/config.exs`). A `.env.example` file lists every available variable with
sensible dev defaults (including the local MinIO credentials).

```bash
cp .env.example .env   # then fill in your values
```

How you inject the variables into the environment (shell exports, a process
manager, etc.) is up to you.

> `.env` is git-ignored; `.env.example` is committed so the setup is reproducible.
> The most important variables are `SECRET_KEY_BASE` and `DATABASE_URL`
> (both required in production) and `GOOGLE_CLIENT_ID` / `GOOGLE_CLIENT_SECRET` for
> [Google Calendar integration](https://console.cloud.google.com/).

---

## Tech Stack

| Layer | Technology |
|---|---|
| Framework | [Phoenix 1.8](https://www.phoenixframework.org/) with LiveView 1.1, Bandit |
| Language | [Elixir 1.19](https://elixir-lang.org/) |
| Database | PostgreSQL (via Ecto) |
| Authentication | Session + BCrypt (team), OTP (candidate portal + registration) |
| File Storage | S3-compatible (MinIO) via ExAWS + Finch |
| Styling | [Tailwind CSS 4](https://tailwindcss.com/) + esbuild |
| Drag & Drop | [Sortable.js](https://sortablejs.github.io/Sortable/) via LiveView hook |
| Email | [Swoosh](https://hexdocs.pm/swoosh) |
| Real-time | Phoenix PubSub |
| Background Jobs | [Oban](https://hexdocs.pm/oban) (scheduled portal messages) |
| HTTP Client | [Req](https://hexdocs.pm/req) |
| Encryption | Cloak (Google token encryption) |
| i18n | Gettext (EN, IT) |

See `site/architecture.md` and `mix.exs:41` for the full list.

---

## Preview the Docs Site

```bash
cd site && npm install && npm run dev
```

Opens at `http://localhost:5173/treby/`. Build with `cd site && npm run build`. Screenshots: `node scripts/screenshots.mjs` (requires running app + seeded DB).

## Quality Checks

```bash
mix precommit   # format --check-formatted, credo, sobelow, compile --warnings-as-errors, test
```

## License

[MIT](LICENSE)
