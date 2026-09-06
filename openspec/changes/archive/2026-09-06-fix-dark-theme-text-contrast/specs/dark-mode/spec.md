## MODIFIED Requirements

### Requirement: App pages render in both themes
All app pages SHALL use theme-aware colors so text, backgrounds, borders, and surfaces remain legible in both light and dark mode with WCAG AA contrast (4.5:1 normal text, 3:1 large text) on their actual dark surfaces (`zinc-800` card, `zinc-900` page, `zinc-700` borders). All design-system tokens and components SHALL define explicit light and dark values; no screen SHALL use hardcoded `gray-50`/`gray-900` or other non-token surfaces that break in dark mode. Muted copy SHALL use the canonical mapping `text-zinc-500 dark:text-zinc-400` (or `text-zinc-600 dark:text-zinc-400` for stronger contrast) and SHALL NOT use the inverted `text-zinc-400 dark:text-zinc-500`. Public careers pages (`/careers`, `/:tenant_slug/careers`, `/:tenant_slug/careers/:job_id`) are explicitly included, with their search input/placeholder and "Back to all positions" link verified for dark contrast.

#### Scenario: Dark mode legibility
- **WHEN** the user enables dark mode and visits any app page
- **THEN** page backgrounds, cards, tables, forms, and text use dark-appropriate colors
- **AND** all text is readable against its background with at least 4.5:1 (normal) / 3:1 (large) contrast

#### Scenario: Light mode unchanged
- **WHEN** the user enables light mode
- **THEN** all app pages display with their existing light appearance

#### Scenario: Design-system tokens cover both themes
- **WHEN** the theme switches between light and dark
- **THEN** every `--ds-*` token and every DS component (Button, Badge, Card, Modal, PageHeader, EmptyState, FilterBar, FormSection, LoadingOverlay, Spinner, Skeleton) renders with theme-specific values derived from `data-theme` / `prefers-color-scheme`

#### Scenario: No hardcoded gray surfaces outside tokens
- **WHEN** CI scans `lib/treby_web` for `bg-gray-50` / `bg-gray-900` / `dark:bg-gray-800` outside `assets/css/app.css` and `lib/treby_web/components/design_system/*`
- **THEN** no matches are found

#### Scenario: Storybook shows both themes per component
- **WHEN** a developer opens any component story in storybook
- **THEN** a theme control (or `data-theme` toggle) shows the component in both light and dark variants

#### Scenario: Dark contrast is enforced by axe
- **WHEN** `node scripts/screenshots.mjs --axe` runs capturing both themes
- **THEN** zero serious/critical `color-contrast` violations are reported, including on `/careers` and `/:tenant_slug/careers/:job_id`

#### Scenario: No inverted muted mapping
- **WHEN** CI greps `lib/treby_web` for `text-zinc-400 dark:text-zinc-500`
- **THEN** no matches are found

#### Scenario: Careers pages are contrast-compliant
- **WHEN** a visitor opens `/careers` (search input) or `/:tenant_slug/careers/:job_id` ("← Back to all positions" link and description) in dark mode
- **THEN** search text/placeholder, back link/ghost button, and tenant description all meet the 4.5:1 / 3:1 thresholds and are visibly legible

