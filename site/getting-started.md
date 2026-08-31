# Getting Started

## Requirements

- **Elixir 1.19+ / Erlang 28+** (versions pinned in `.tool-versions`)
- **PostgreSQL 14+**
- **S3-compatible storage** — provided locally by `docker-compose.yml` (RustFS) in development; any S3 provider works in production
- **Node.js 18+** (only if you want to build assets or the documentation site)

## Quick Install

```bash
# Clone the repository
git clone git@github.com:treere/treby.git
cd treby

# Install dependencies, create the database and load sample data
mix setup

# Start the server
mix phx.server
```

Open [`http://localhost:4000`](http://localhost:4000) in your browser.

## Sample Data

The setup command loads demo data for the **Acme Corp** company (`acme`):

| Email | Password | Role |
|---|---|---|
| `admin@acme.com` | `password123` | Admin |
| `member@acme.com` | `password123` | Member |

Preloaded content:

- 3 positions — Senior Elixir Developer, Product Designer, DevOps Engineer
- 10 candidates with applications spread across pipeline stages
- 6 additional duplicate profiles (same person with slightly different email/phone) to try the merge feature
- 7 pipeline stages — New → Screening → Phone Screen → Interview → Offer → Hired → Rejected
- Published career page at `http://localhost:4000/acme/careers`
- A few scheduled message examples for the queue

## Development with Docker

The `docker-compose.yml` file starts PostgreSQL and local S3 storage:

```bash
docker compose up -d
mix setup
mix phx.server
```

The storage console is at `http://localhost:9001` (credentials in `.env.example` — `treby` / `treby_password`).

## Environment Variables

Treby reads configuration from environment variables. The `.env.example` file lists all variables with development-friendly defaults; `.env` (ignored by git) holds your real values:

```bash
cp .env.example .env   # then edit the values
```

Main variables:

| Variable | Required in production | Description |
|---|---|---|
| `SECRET_KEY_BASE` | yes | Secret key — generate with `mix phx.gen.secret` |
| `DATABASE_URL` | yes | Database URL, e.g. `ecto://USER:PASS@HOST/DATABASE` |
| `PHX_HOST` | yes | Public host, e.g. `treby.example.com` |
| `CLOAK_KEY` | recommended | Key for Google token encryption; has a default value for development |
| `S3_*` | — | `S3_SCHEME`, `S3_HOST`, `S3_PORT`, `S3_ACCESS_KEY_ID`, `S3_SECRET_ACCESS_KEY` |
| `GOOGLE_CLIENT_ID` / `GOOGLE_CLIENT_SECRET` | if you use Google Calendar | OAuth credentials from https://console.cloud.google.com — callback `http(s)://HOST/auth/google/callback` |
| `MAILGUN_API_KEY` / `MAILGUN_DOMAIN` | if you use email in production | SMTP provider |

How you inject the variables (shell export, process manager, etc.) depends on your environment.

## Useful Commands

| Command | What it does |
|---|---|
| `mix setup` | Installs dependencies, creates/migrates the database, loads sample data, and builds assets |
| `mix ecto.setup` | Creates and migrates the database + loads sample data |
| `mix ecto.reset` | Recreates the database from scratch |
| `mix phx.server` | Starts the application at http://localhost:4000 |
| `mix precommit` | Quality checks (formatting, static analysis, tests) |

## Documentation Site

This documentation is a VitePress site in `site/`:

```bash
cd site && npm install && npm run dev   # http://localhost:5173/treby/
cd site && npm run build                # build the static site
```

To regenerate the screenshots used on the feature pages (requires the app running with sample data):

```bash
node scripts/screenshots.mjs            # saves to site/public/screenshots/
```

The site is automatically published to GitHub Pages on every push to `main`.
