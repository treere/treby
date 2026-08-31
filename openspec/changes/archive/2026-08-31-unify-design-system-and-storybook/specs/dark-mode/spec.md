## MODIFIED Requirements

### Requirement: App pages render in both themes
All app pages SHALL use theme-aware colors so text, backgrounds, borders, and surfaces remain legible in both light and dark mode. All design-system tokens and components SHALL define explicit light and dark values; no screen SHALL use hardcoded `gray-50`/`gray-900` or other non-token surfaces that break in dark mode.

#### Scenario: Dark mode legibility
- **WHEN** the user enables dark mode and visits any app page
- **THEN** page backgrounds, cards, tables, forms, and text use dark-appropriate colors
- **AND** all text is readable against its background with sufficient contrast

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
