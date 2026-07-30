
# Getting Started

## Prerequisites

- **Elixir** 1.14+
- **PostgreSQL** 14+
- **S3-compatible storage** (MinIO for development)
- **Node.js** 18+ (for asset build)

## Setup

```bash
# Clone the repository
git clone git@github.com:treere/treby.git
cd treby

# Install dependencies and set up the database
mix setup

# Start the Phoenix server
mix phx.server
```

Visit [`http://localhost:4000`](http://localhost:4000) in your browser.

## Seed Data

Running `mix setup` seeds the database with demo data for **Acme Corp** (`acme`):

| Email | Password | Role |
|---|---|---|
| `admin@acme.com` | `password123` | Admin |
| `member@acme.com` | `password123` | Member |

Pre-loaded content:
- 3 job postings (Senior Elixir Developer, Product Designer, DevOps Engineer)
- 10 candidates with applications across pipeline stages
- 6 pipeline stages (New → Screen → Phone Screen → Interview → Offer → Hired)
- Published career page at `http://localhost:4000/acme/careers`

## Docker Development

A `docker-compose.yml` is included for PostgreSQL and MinIO:

```bash
docker compose up -d
mix setup
mix phx.server
```

## Project Structure

```
treby/
├── lib/
│   ├── treby/          # Core business logic contexts
│   │   ├── accounts/   # Users, teams, authentication
│   │   ├── hiring/     # Jobs, candidates, applications
│   │   ├── pipeline/   # Pipeline stages and moves
│   │   └── ...
│   └── treby_web/      # Web layer (LiveViews, controllers)
├── priv/
│   └── gettext/        # Translations (EN, IT)
├── test/               # Tests
├── assets/             # JS, CSS (Tailwind + esbuild)
└── site/               # Documentation site (Vitepress)
```
