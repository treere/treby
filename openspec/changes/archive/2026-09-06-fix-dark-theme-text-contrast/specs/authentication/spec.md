## MODIFIED Requirements

### Requirement: User login
The system SHALL allow users to log in with email and password. The system SHALL authenticate against the globally unique identity and then resolve the user's memberships. The login page at `/login` (and sibling unauthenticated pages `/reset-password`, `/register`, invite) SHALL render all `text-primary` links such as "Forgot your password?", "create a new account", and "Back to sign in" with explicit `dark:` overrides so they remain ≥4.5:1 in dark mode on `bg-zinc-50 dark:bg-zinc-800`, and the pages SHALL include a homepage brand link (Treby → `/`) alongside the existing `Layouts.auth_toolbar` theme+language controls.

#### Scenario: Successful login with single membership
- **WHEN** a user submits a valid email and password and the user has exactly one membership
- **THEN** a session is created with `user_id` only
- **AND** the user is redirected to `/:tenant_slug/app` for that membership

#### Scenario: Successful login with multiple memberships
- **WHEN** a user submits a valid email and password and the user has two or more memberships
- **THEN** a session is created with `user_id`
- **AND** the user is redirected to `/choose-tenant`
- **AND** after choosing a workspace the user is redirected to `/:tenant_slug/app` for the chosen membership

#### Scenario: Choosing a workspace after login
- **WHEN** a user on `/choose-tenant` selects a workspace they belong to
- **THEN** the system verifies the membership and redirects to `/:tenant_slug/app` for that tenant

#### Scenario: Invalid credentials
- **WHEN** a user submits an invalid email or password
- **THEN** the system returns an error: "Invalid email or password"

#### Scenario: Forgot password link
- **WHEN** a user views the login page
- **THEN** a "Forgot your password?" link is displayed below the password field
- **AND** the link navigates to `/reset-password`
- **AND** the link uses `text-primary dark:text-orange-300` (or `dark:text-zinc-300`) so it is ≥4.5:1 in dark mode

#### Scenario: Password pages show homepage + theme + language
- **WHEN** a visitor opens `http://localhost:4000/reset-password` (or `/reset-password/edit?token=...`, `/login`, `/register`) in dark mode
- **THEN** a header with Treby brand → `/` (top-left) and theme+language controls (top-right, via `auth_toolbar`) is visible and contrast-compliant, with no axe `color-contrast` violation

