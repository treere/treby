## MODIFIED Requirements

### Requirement: Navigation toggle below xl
The system SHALL display a hamburger menu button on screens below the `xl` breakpoint (1280px) that toggles a slide-out navigation drawer from the left edge.

#### Scenario: Hamburger button visible below xl
- **WHEN** the viewport width is below 1280px
- **THEN** a hamburger menu button is visible inside the navigation bar on the left side
- **AND** the inline nav links and right-side group are hidden

#### Scenario: Toggle drawer open
- **WHEN** a user taps the hamburger button
- **THEN** a slide-out navigation drawer opens from the left edge showing all nav links
- **AND** a backdrop overlay covers the main content

#### Scenario: Toggle drawer closed
- **WHEN** a user taps the close button or the backdrop overlay
- **THEN** the navigation drawer closes

#### Scenario: Navigate from drawer closes it
- **WHEN** a user taps a nav link inside the drawer
- **THEN** the user navigates to the selected page
- **AND** the drawer automatically closes

### Requirement: Inline nav only at xl and above
The system SHALL display inline nav links and the right-side group (notifications, theme, locale, user name, logout) only on screens at or above the `xl` breakpoint (1280px), with no hamburger button.

#### Scenario: Inline nav display at xl
- **WHEN** the viewport width is 1280px or above
- **THEN** nav links are displayed inline in the navigation bar
- **AND** the notification bell, theme toggle, locale switcher, user name, and logout are visible inline
- **AND** no hamburger button is visible

### Requirement: Mobile drawer includes theme and locale toggles
The mobile navigation drawer SHALL include a theme toggle control alongside the locale switcher so users can switch themes without leaving the drawer.

#### Scenario: Theme toggle in drawer
- **WHEN** a user opens the navigation drawer below the `xl` breakpoint
- **THEN** a theme toggle control is visible next to the locale switcher
- **AND** activating it changes the active theme immediately
