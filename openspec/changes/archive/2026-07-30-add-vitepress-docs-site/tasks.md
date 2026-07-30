## 1. Vitepress site scaffolding

- [x] 1.1 Create `site/` directory with `package.json` (vitepress dev dependency, Node 18+ engine pin)
- [x] 1.2 Create `site/.vitepress/config.ts` with base URL `/treby/`, title, description, theme config, search config, and nav/sidebar structure
- [x] 1.3 Create `site/.vitepress/theme/custom.css` with Treby brand colors, typography overrides, and component style tweaks
- [x] 1.4 Create `site/.vitepress/theme/index.ts` importing the custom CSS
- [x] 1.5 Create `site/public/screenshots/.gitkeep` (placeholder for screenshots)

## 2. Landing page and content

- [x] 2.1 Create `site/index.md` — landing page with hero section, feature cards (3-5 key features with links), CTA to getting-started
- [x] 2.2 Create `site/getting-started.md` — prerequisites, setup commands, seed data, demo credentials
- [x] 2.3 Create `site/architecture.md` — tech stack table, architecture notes, design decisions
- [x] 2.4 Create feature pages: `site/features/pipeline.md`, `site/features/career-pages.md`, `site/features/candidate-management.md`, `site/features/interview-scheduling.md`, `site/features/analytics.md`, `site/features/email-notifications.md`
- [x] 2.5 Create `site/features/index.md` — feature overview with grid of all features linking to individual pages

## 3. Screenshot generation script

- [x] 3.1 Create `scripts/screenshots.mjs` — Playwright script that starts Phoenix (`mix phx.server`), waits for ready, logs in as admin@acme.com, captures all screenshots at 1280x900 viewport, saves to `site/public/screenshots/`, and cleans up server
- [x] 3.2 Test the script end-to-end: run it, verify all 18 screenshots are generated correctly (manual — needs PostgreSQL + seed data)

## 4. CI/CD and deployment

- [x] 4.1 Create `.github/workflows/deploy-pages.yml` — workflow that builds Vitepress site on push to main and deploys to GitHub Pages via `actions/deploy-pages`
- [x] 4.2 Enable GitHub Pages in repo settings (Settings → Pages → Source: GitHub Actions) — one-time manual step
- [x] 4.3 Verify deployment: push to main, confirm site is live at `https://treere.github.io/treby/` — one-time manual verification

## 5. README and housekeeping

- [x] 5.1 Strip all inline screenshots from `README.md`, replace with a single introductory link to the site
- [x] 5.2 Strip the detailed feature documentation sections from `README.md` (keep only quickstart, tech stack, and link to site)
- [x] 5.3 Move ROADMAP content to a page on the site, then remove `docs/ROADMAP.md`
- [x] 5.4 Remove `docs/screenshots/` directory (screenshots now live in `site/public/screenshots/`)
- [x] 5.5 Add a section at the top of `AGENTS.md`: "After adding a new feature or changing an existing one, regenerate screenshots with `node scripts/screenshots.mjs` and update the feature page in `site/`"

