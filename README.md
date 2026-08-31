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
- S3-compatible storage — RustFS for development (via `docker-compose.yml`)
- Node.js 18+ (assets + docs site)

### Setup

```bash
mix setup
mix phx.server
```

Visit [`http://localhost:4000`](http://localhost:4000).

With Docker for Postgres + RustFS (S3):

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
sensible dev defaults (including the local RustFS credentials).

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
| File Storage | S3-compatible (RustFS) via ExAWS + Req |
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

## Design System & Storybook

All UI uses `TrebyWeb.DesignSystem.*` (`Button`, `Badge`, `Card`, `Modal`, `Dropdown`, `Tabs`, `Avatar`, `Feedback`/`Spinner`/`Skeleton`/`Toast`, `Pattern`/`ConfirmDialog`/`PageHeader`/`EmptyState`/`FilterBar`/`FormSection`/`LoadingOverlay`) with tokens in `assets/css/app.css` (`--ds-*`, light/dark via `data-theme`). No screen should define ad-hoc `bg-blue-600`/`bg-gray-500` button styles outside `lib/treby_web/components/design_system/*` — CI fails via `mix treby.check_design_system` (wired into `mix precommit`).

Isolated preview (dev only, not in `prod`/`test`):

```bash
mix phx.server
# http://localhost:4000/dev/storybook  (requires MIX_ENV=dev, mount via dev_routes)
```

Stories live in `storybook/` (`button`/`badge`/`card`/`modal`/`dropdown`/`tabs`/`avatar`/`spinner`/`skeleton`/`toast` + `patterns/*`), powered by [`phoenix_storybook ~> 0.9`](https://github.com/phenixdigital/phoenix_storybook) (`only: :dev`).

## Quality Checks

```bash
mix precommit   # format --check-formatted, credo, treby.check_translations, treby.check_design_system, sobelow, compile --warnings-as-errors, test
```

## License

[MIT](LICENSE)
