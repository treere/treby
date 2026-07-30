## Why

Treby is a mature open-source ATS, but it has no dedicated showcase or documentation site. The README is overloaded with 22 inline screenshots, making it slow to load and hard to navigate. Potential users and contributors have no polished entry point to understand what Treby does, see its features, or evaluate whether it fits their needs. A dedicated GitHub Pages site solves this: fast, searchable, professional, and always up to date.

## What Changes

- **Create a Vitepress documentation site** in `site/` with a professional landing page, feature documentation, and getting-started guide
- **Add a Playwright screenshot generation script** (`scripts/screenshots.mjs`) to automate image capture from the running Phoenix app
- **Add a GitHub Actions workflow** (`.github/workflows/deploy-pages.yml`) to build and deploy the site to GitHub Pages on push to `main`
- **Strip inline screenshots from README.md** and replace them with a link to the site
- **Update AGENTS.md** with a reminder to update the site when adding new features
- **Remove old screenshots from `docs/screenshots/`** (they move to `site/public/screenshots/`)

## Capabilities

### New Capabilities
- `docs-site`: Vitepress-based documentation and showcase site with landing page, feature pages, getting-started guide, search, and professional styling
- `screenshot-generation`: Playwright script that starts the Phoenix server, logs in, navigates key pages, and captures screenshots for the site
- `ci-deployment`: GitHub Actions workflow that builds the Vitepress site and deploys to GitHub Pages

### Modified Capabilities
<!-- No existing specs change behavior — this is net-new infrastructure. -->

## Impact

- **New directory**: `site/` with Vitepress config, content, and `package.json`
- **New file**: `scripts/screenshots.mjs` — Playwright-based screenshot capture
- **New file**: `.github/workflows/deploy-pages.yml` — CI/CD pipeline
- **Modified**: `README.md` — screenshots removed, link to GitHub Pages added
- **Modified**: `AGENTS.md` — reminder to keep the site in sync with new features
- **Removed**: `docs/screenshots/` — screenshots live in `site/public/screenshots/` now
- **Removed**: `docs/ROADMAP.md` — content relocated to a page on the site
- **Dependencies**: `vitepress` + `@playwright/test` (dev only, in `site/package.json`)
