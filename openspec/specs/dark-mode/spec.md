# Dark Mode

## Purpose

Allow users to switch the app theme between system (OS preference), light, and dark, persist their explicit choice in the browser, and ensure all app pages render correctly in dark mode.

## Requirements

### Requirement: Theme toggle in navigation
The app SHALL provide a theme toggle control in the main navigation, positioned adjacent to the locale switcher, on both desktop and in the mobile drawer.

#### Scenario: Desktop shows theme toggle
- **WHEN** a logged-in user views the desktop navigation bar
- **THEN** a theme toggle control is visible next to the locale switcher
- **AND** the toggle offers system, light, and dark options

#### Scenario: Mobile drawer shows theme toggle
- **WHEN** a user opens the mobile navigation drawer
- **THEN** a theme toggle control is visible next to the locale switcher

### Requirement: Theme toggle on unauthenticated pages
Unauthenticated pages (homepage, login, register, forgot password) SHALL also provide the theme toggle and locale switcher so users can choose their theme before signing in.

#### Scenario: Homepage shows toggles
- **WHEN** a user views the homepage
- **THEN** a theme toggle control and locale switcher are visible in the header

#### Scenario: Login page shows toggles
- **WHEN** a user views the login page
- **THEN** a theme toggle control and locale switcher are visible

#### Scenario: Register page shows toggles
- **WHEN** a user views the register page
- **THEN** a theme toggle control and locale switcher are visible

#### Scenario: Forgot password page shows toggles
- **WHEN** a user views the forgot password page
- **THEN** a theme toggle control and locale switcher are visible

#### Scenario: Toggle works without LiveView
- **WHEN** a user clicks a theme option on an unauthenticated page
- **THEN** the theme changes immediately and is persisted in `localStorage`

### Requirement: System theme is default
When the user has not made an explicit choice, the app SHALL follow the operating system's color scheme preference (`prefers-color-scheme`).

#### Scenario: No stored preference follows OS
- **WHEN** the user has not chosen a theme and their OS reports dark mode
- **THEN** the app displays in dark mode

#### Scenario: OS preference changes while in system mode
- **WHEN** the user is in system mode and the OS color scheme changes
- **THEN** the app updates the active theme to match without a page reload

### Requirement: Explicit theme choice is persisted
When the user selects light or dark, the app SHALL store that preference in the browser's `localStorage` and use it on subsequent visits.

#### Scenario: Choosing dark persists
- **WHEN** the user selects dark
- **THEN** the app applies dark mode immediately
- **AND** dark mode remains active after a full page reload

#### Scenario: Choosing light persists
- **WHEN** the user selects light
- **THEN** the app applies light mode immediately
- **AND** light mode remains active after a full page reload

#### Scenario: Returning to system clears stored choice
- **WHEN** the user selects system after having selected light or dark
- **THEN** the app follows the OS preference again
- **AND** the previously stored light/dark preference is removed

### Requirement: No flash of incorrect theme
The active theme SHALL be applied before the page first paints so users do not briefly see the wrong theme on load.

#### Scenario: Theme applied before paint
- **WHEN** a user loads a page with a stored dark preference
- **THEN** the page first renders in dark mode with no visible flash of light mode

### Requirement: Theme toggle is accessible
The theme toggle control SHALL be operable by keyboard and have descriptive accessible labels for each option.

#### Scenario: Toggle labelled and keyboard-operable
- **WHEN** a keyboard-only user tabs to the theme toggle
- **THEN** each option (system, light, dark) can be activated via keyboard
- **AND** the buttons have accessible names describing their function

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
