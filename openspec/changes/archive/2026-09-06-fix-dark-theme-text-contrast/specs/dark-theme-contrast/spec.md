## ADDED Requirements

### Requirement: Dark theme text meets WCAG AA contrast
All text rendered on dark surfaces SHALL meet WCAG AA contrast: 4.5:1 for normal text (<18pt) and 3:1 for large text (≥18pt or 14pt bold) when `data-theme="dark"` or `prefers-color-scheme: dark` is active. This applies to body copy, muted/secondary copy, placeholders, links, badge text, and button labels on `zinc-800`/`zinc-900` surfaces.

#### Scenario: Muted copy on dark card meets contrast
- **WHEN** a user views any card (`bg-white dark:bg-zinc-800`) in dark mode
- **THEN** secondary/muted text uses at least `dark:text-zinc-400` (or lighter) and the computed contrast against `zinc-800` is ≥4.5:1 for normal text

#### Scenario: Automated axe check enforces contrast
- **WHEN** `node scripts/screenshots.mjs --axe` runs on a build that captures both light and dark theme
- **THEN** zero serious/critical `color-contrast` violations are reported

### Requirement: Public careers pages are readable in dark mode
The public careers surfaces — global board at `/careers` and tenant board/job detail at `/:tenant_slug/careers` and `/:tenant_slug/careers/:job_id` — SHALL be fully legible in dark mode, including search controls, job list metadata, and navigation links.

#### Scenario: Careers search input is legible in dark mode
- **WHEN** a visitor opens `http://localhost:4000/careers` in dark mode
- **THEN** the search input (`placeholder "Search across all companies..."`) has a dark-aware background (`dark:bg-zinc-800`), border (`dark:border-zinc-700`), text (`dark:text-zinc-100`), and placeholder (`dark:placeholder:text-zinc-400` or darker) with ≥4.5:1 text contrast and a visible placeholder with ≥3:1 on its background
- **AND** the adjacent Search button renders with its design-system variant and remains contrast-compliant

#### Scenario: Job list metadata is legible
- **WHEN** the same page lists jobs
- **THEN** tenant name, location, employment/workplace badges, and salary text are not using `text-zinc-400 dark:text-zinc-500` (inverted) but `text-zinc-500 dark:text-zinc-400` or lighter, so they are readable on both `zinc-50` and `zinc-800` cards

#### Scenario: Job detail back navigation is legible
- **WHEN** a visitor opens `http://localhost:4000/:tenant_slug/careers/:job_id` (e.g., `/acme/careers/8dec86b3-7584-47f0-b9f6-7af6625a55da`) in dark mode
- **THEN** the "← Back to all positions" link (and the ghost "View other positions" fallback button) uses a dark-aware color (`text-primary` with sufficient contrast or `dark:text-zinc-200`/`dark:text-orange-300` equivalent) and is visible against `bg-zinc-50 dark:bg-zinc-800` with ≥4.5:1 contrast
- **AND** the career-page description under the tenant name (`text-sm` line in the header) uses `text-zinc-500 dark:text-zinc-400` (not `text-zinc-400 dark:text-zinc-500`) so it is not washed out

### Requirement: Muted-text token mapping is consistent
The codebase SHALL use the canonical muted mapping: light `text-zinc-500`/`600` → dark `dark:text-zinc-400` (or `dark:text-zinc-300` for smaller/secondary text on `zinc-900`). The inverted pattern `text-zinc-400 dark:text-zinc-500` SHALL NOT appear in `lib/treby_web` or `assets/css`.

#### Scenario: No inverted muted pattern remains
- **WHEN** CI greps `lib/treby_web` for `text-zinc-400 dark:text-zinc-500`
- **THEN** no matches are found

#### Scenario: New code follows canonical mapping
- **WHEN** a developer adds secondary copy on a card or page surface
- **THEN** they use `text-zinc-500 dark:text-zinc-400` (or `text-zinc-600 dark:text-zinc-400`) for normal text, and the axe `color-contrast` check passes

### Requirement: Inputs and placeholders have dark contrast
All text inputs, textareas, selects, and search fields SHALL define explicit dark placeholder and text colors so typed text and placeholder are both legible on `dark:bg-zinc-800`.

#### Scenario: Placeholder is visible in dark mode
- **WHEN** an empty search or form input is rendered in dark mode
- **THEN** its placeholder is at least `dark:placeholder:text-zinc-400` (≥3:1 on `zinc-800`) and typed text is `dark:text-zinc-100`

#### Scenario: Input helper aligns with core_components
- **WHEN** an input is rendered via `<.input>` or raw `class="input"`
- **THEN** its Tailwind classes include `bg-white dark:bg-zinc-800 border-zinc-200 dark:border-zinc-700 text-zinc-900 dark:text-zinc-100 placeholder:text-zinc-400 dark:placeholder:text-zinc-400` (or equivalent token) and passes axe

### Requirement: Ghost and link affordances remain visible in dark mode
Ghost buttons and inline navigation links (e.g., "Back to all positions", "Forgot your password?") SHALL have dark overrides so they are not rendered as low-contrast dark-on-dark.

#### Scenario: Ghost button on dark page is visible
- **WHEN** a ghost button (e.g., "View other positions" on the closed/not-found state of `/:tenant_slug/careers/:job_id`) is shown in dark mode
- **THEN** it uses `dark:bg-zinc-800 dark:text-zinc-200 dark:border-zinc-600 dark:hover:bg-zinc-700` or the design-system ghost dark variant and meets ≥4.5:1 on `zinc-800`/`zinc-900`

#### Scenario: Text-primary link on dark background passes contrast
- **WHEN** a `text-primary` link is placed on `bg-zinc-800` or `bg-zinc-50 dark:bg-zinc-800` in dark mode
- **THEN** either the link color or its dark override provides ≥4.5:1 contrast (e.g., `dark:text-orange-300` for primary on dark, or switch to `text-zinc-200 dark:text-zinc-100` for navigational back links)

#### Scenario: Login forgot-password link is legible
- **WHEN** a visitor opens `http://localhost:4000/login` in dark mode
- **THEN** the "Forgot your password?" link (and sibling "create a new account" / "Back to sign in" auth links using `text-primary`) renders with a `dark:` override (e.g., `dark:text-orange-400` or `dark:text-zinc-300` with `dark:hover:text-zinc-100`) and is ≥4.5:1 on `bg-zinc-50 dark:bg-zinc-800`

### Requirement: Dashboard headings and stats are legible in dark mode
All dashboard headings and secondary copy at `/:tenant_slug/app` (tenant-scoped dashboard, e.g., `http://localhost:4000/acme/app`) SHALL be legible in dark mode: section titles such as "Le mie azioni" / "My Actions", "Upcoming Interviews (7 days)", "Stale Candidates (7+ days)", "Pipeline Overview", "Recent Activity", plus weekly-stats labels ("Applications This Week", etc.) and per-item metadata.

#### Scenario: Section headings have explicit dark color
- **WHEN** a user views `http://localhost:4000/acme/app` in dark mode with Italian or English locale
- **THEN** headings like "Le mie azioni" / "My Actions" and the other section `h2`s use `text-zinc-900 dark:text-zinc-100` (or at least `dark:text-zinc-100`) so they are ≥4.5:1 on `bg-white dark:bg-zinc-800` / `bg-zinc-50 dark:bg-zinc-900`

#### Scenario: Stats and action metadata use canonical muted mapping
- **WHEN** the same dashboard is viewed in dark mode
- **THEN** weekly-stats small labels, action `job_title` / interview dates, and stale/pipeline counts use `text-zinc-500 dark:text-zinc-400` (or `text-zinc-600 dark:text-zinc-400`) not the inverted `text-zinc-400 dark:text-zinc-500`, so all secondary copy remains ≥4.5:1 on its card

#### Scenario: No naked heading without dark override remains
- **WHEN** CI greps `lib/treby_web/live/dashboard_live.ex` for `text-lg font-semibold` without a following `dark:text-`
- **THEN** no matches are found

### Requirement: Public pages expose theme, language, and homepage navigation
Unauthenticated and tenant-public pages that are entry points SHALL expose a visible homepage link and the theme/language controls so users can navigate home and change preferences without being logged in. This covers `/reset-password` (password reset request/edit), `/careers` (global board), and `/:tenant_slug/careers`, `/:tenant_slug/careers/:job_id`, `/:tenant_slug/careers/:job_id/apply` (tenant career pages). Hosted pages that already use `Layouts.auth_toolbar` (login/register/invite resets) already satisfy theme+language but SHALL also include a homepage brand link; careers pages that currently have no header SHALL add a shared public header with homepage link + theme toggle + locale switcher that is itself contrast-compliant in dark mode.

#### Scenario: Careers pages show homepage + theme + language
- **WHEN** a visitor opens `http://localhost:4000/careers` or `http://localhost:4000/acme/careers` or `http://localhost:4000/acme/careers/8dec86b3-7584-47f0-b9f6-7af6625a55da` in dark mode (or any theme, any locale)
- **THEN** a header bar is visible containing a Treby (or tenant) brand link that navigates to `/` and, on the opposite side, the theme toggle (system/light/dark) and the language switcher (EN/IT), all rendered with `dark:` overrides so they are ≥4.5:1 on their `bg-white/80 dark:bg-zinc-900/80` header

#### Scenario: Password pages show homepage link alongside toolbar
- **WHEN** a visitor opens `http://localhost:4000/reset-password` (or `/reset-password/edit?token=...`) in dark mode
- **THEN** the page shows a Treby link to `/` (top-left) plus the existing `auth_toolbar` theme+language controls (top-right), forming the same public header pattern, and all remain legible in dark mode

#### Scenario: Header is consistent across public entry points
- **WHEN** a user navigates between `/login`, `/register`, `/reset-password`, `/careers`, and `/:tenant_slug/careers` in either light or dark mode
- **THEN** the same header pattern (homepage brand on the left, theme+language on the right) is present and does not introduce axe `color-contrast` violations

