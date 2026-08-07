# App Navigation

## Delta

### ADDED Requirements

### Requirement: Mobile drawer includes theme toggle
The mobile navigation drawer SHALL include a theme toggle alongside the locale switcher.

#### Scenario: Mobile drawer has theme toggle
- **WHEN** a user opens the mobile navigation drawer
- **THEN** a theme toggle control is visible next to the locale switcher

### Requirement: Unauthenticated pages include theme and locale toggles
The homepage, login, register, and forgot password pages SHALL include the theme toggle and locale switcher.

#### Scenario: Homepage has toggles
- **WHEN** a user views the homepage
- **THEN** a theme toggle control and locale switcher are visible in the header

#### Scenario: Login page has toggles
- **WHEN** a user views the login page
- **THEN** a theme toggle control and locale switcher are visible
- **AND** both controls function without requiring a signed-in session
