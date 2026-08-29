# Getting Started

## Prerequisites

- **Elixir** 1.19+ / **Erlang** 28+ (see `.tool-versions` for the pinned versions)
- **PostgreSQL** 14+
- **S3-compatible storage** — MinIO in development (provided by `docker-compose.yml`)
- **Node.js** 18+ (for `assets` via esbuild + Tailwind, and for the VitePress site in `site/`)

## Setup

```bash
# Clone the repository
git clone git@github.com:treere/treby.git
cd treby

# Install Elixir deps + create/migrate/seed DB + install & build assets
mix setup

# Start the Phoenix server (Bandit)
mix phx.server
```

Visit [`http://localhost:4000`](http://localhost:4000) in your browser.

Useful aliases defined in `mix.exs:89`:

| Command | What it does |
|---|---|
| `mix setup` | `deps.get`, `ecto.setup`, `assets.setup`, `assets.build` |
| `mix ecto.setup` | create + migrate + `priv/repo/seeds.exs` |
| `mix ecto.reset` | drop + setup |
| `mix assets.build` | `tailwind treby` + `esbuild treby` |
| `mix assets.deploy` | minified assets + `phx.digest` (production) |
| `mix precommit` | format check, Credo, Sobelow, compile warnings-as-errors, tests |

## Seed Data

`mix setup` / `mix ecto.setup` seeds demo data for **Acme Corp** (`acme`):

| Email | Password | Role |
|---|---|---|
| `admin@acme.com` | `password123` | Admin |
| `member@acme.com` | `password123` | Member |

Pre-loaded content:

- 3 job postings — Senior Elixir Developer, Product Designer, DevOps Engineer
- 10 candidates with applications distributed across pipeline stages
- 6 extra duplicate-profile candidates (same person with slightly different email/phone/name) to exercise the **Merge Duplicates** center
- 7 pipeline stages — New → Screen → Phone Screen → Interview → Offer → Hired → Rejected (see `lib/treby/pipeline/pipeline.ex:670`)
- Published career page at `http://localhost:4000/acme/careers`
- A few scheduled email-queue entries for the queue demo

## Docker Development

`docker-compose.yml` provides PostgreSQL + MinIO:

```bash
docker compose up -d
mix setup
mix phx.server
```

MinIO console: `http://localhost:9001` (credentials from `.env.example` — `treby` / `treby_password`).

## Environment Variables

Configuration is read from env vars (see `config/runtime.exs` and `config/config.exs`). `.env.example` lists every variable with dev defaults; `.env` is git-ignored:

```bash
cp .env.example .env   # then fill in values
```

Key variables:

| Variable | Required in prod | Description |
|---|---|---|
| `SECRET_KEY_BASE` | yes | `mix phx.gen.secret` |
| `DATABASE_URL` | yes | e.g. `ecto://USER:PASS@HOST/DATABASE` |
| `PHX_HOST` | yes (prod) | public host, e.g. `treby.example.com` |
| `CLOAK_KEY` | recommended | 32-byte base64 key for `Treby.Vault` (Google token encryption); has dev default |
| `S3_*` | — | `S3_SCHEME`, `S3_HOST`, `S3_PORT`, `S3_ACCESS_KEY_ID`, `S3_SECRET_ACCESS_KEY` |
| `GOOGLE_CLIENT_ID` / `GOOGLE_CLIENT_SECRET` | if using Google Calendar | OAuth at https://console.cloud.google.com — callback `http(s)://HOST/auth/google/callback` |
| `MAILGUN_API_KEY` / `MAILGUN_DOMAIN` | if using Swoosh in prod | SMTP provider |

## Project Structure

```
treby/
├── lib/
│   ├── treby/                      # Business contexts
│   │   ├── accounts/               # Users, auth, invites, password reset, registration OTP
│   │   ├── tenants/                # Multi-tenancy
│   │   ├── jobs/                   # Job postings
│   │   ├── candidates/             # Candidates, duplicates/merge, dismissed groups
│   │   ├── pipeline/               # Pipelines, stages, applications, roles (examiner/reviewer/advancer)
│   │   ├── interviews/             # Interview events + examiners
│   │   ├── scorecards/             # Scorecard templates & filled scorecards
│   │   ├── availability/           # Weekly availability rules
│   │   ├── calendar/               # Calendar connections, Google/Jitsi providers
│   │   ├── candidate_portal/       # OTP, conversations, messages, notification prefs
│   │   ├── scheduled_messages/     # Oban-backed scheduled portal messages
│   │   ├── email_templates/        # Per-stage message templates
│   │   ├── customization/          # Custom fields
│   │   ├── sources/                # Candidate sources
│   │   ├── csv_import/             # CSV parsing & import logs
│   │   ├── bulk_operations/        # Bulk move/review/delete
│   │   ├── comparison/             # Side-by-side candidate comparison
│   │   ├── activities/             # Activity timeline
│   │   └── dashboard.ex            # Dashboard aggregations
│   └── treby_web/                  # Web layer
│       ├── live/                   # LiveViews (dashboard, jobs, pipeline, candidates, analytics, etc.)
│       ├── controllers/            # Session, registration, invites, resume, candidate OTP, etc.
│       ├── components/             # Core + design system
│       ├── plugs/ + hooks/         # Auth, tenant, candidate auth, locale, role
│       └── router.ex               # All routes (see Architecture)
├── priv/
│   ├── repo/migrations/            # ~30 migrations
│   ├── repo/seeds.exs              # Demo data
│   └── gettext/                    # Translations (EN, IT) + errors
├── assets/                         # app.js / app.css (Tailwind v4 + esbuild, Sortable.js hook)
├── test/                           # ExUnit + Phoenix.LiveViewTest
├── site/                           # VitePress docs (this site) + screenshots
├── scripts/screenshots.mjs         # Playwright screenshot generator
├── docker-compose.yml              # Postgres + MinIO for dev
└── config/                         # config.exs / dev.exs / runtime.exs ...
```

## Docs Site

```bash
cd site && npm install && npm run dev   # http://localhost:5173/treby/
cd site && npm run build                # output in site/.vitepress/dist/

# Regenerate all screenshots (requires running app + seeded DB)
node scripts/screenshots.mjs            # output in site/public/screenshots/
```

The site auto-deploys to GitHub Pages on push to `main` via `.github/workflows/deploy-pages.yml`.

## Quality Checks

Before opening a PR, run:

```bash
mix precommit   # format --check-formatted, credo --strict, sobelow, compile --warnings-as-errors, test
```
