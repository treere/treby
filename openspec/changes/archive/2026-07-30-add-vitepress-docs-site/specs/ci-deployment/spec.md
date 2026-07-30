## ADDED Requirements

### Requirement: GitHub Actions workflow builds the site
The project SHALL have a GitHub Actions workflow that builds the Vitepress site on pushes to the main branch.

#### Scenario: Workflow triggers on push to main
- **WHEN** code is pushed to the `main` branch
- **THEN** the deploy workflow is triggered

#### Scenario: Vitepress build succeeds
- **WHEN** the workflow runs
- **THEN** it checks out the repo, installs Node.js 20, runs `npm ci` in `site/`, and runs `npm run build` which outputs to `site/.vitepress/dist/`

### Requirement: Workflow deploys to GitHub Pages
The workflow SHALL deploy the built site to GitHub Pages.

#### Scenario: Deployment succeeds
- **WHEN** the build step completes successfully
- **THEN** the contents of `site/.vitepress/dist/` are deployed to the `gh-pages` branch

### Requirement: Site is accessible at the correct URL
The deployed site SHALL be accessible at `https://treere.github.io/treby/`.

#### Scenario: Site loads at project pages URL
- **WHEN** a browser navigates to `https://treere.github.io/treby/`
- **THEN** the site loads with correct asset paths (CSS, JS, images)
