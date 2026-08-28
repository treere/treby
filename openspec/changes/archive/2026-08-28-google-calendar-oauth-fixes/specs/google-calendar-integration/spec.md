## MODIFIED Requirements

### Requirement: Connect Google Calendar account
The system SHALL allow team members to connect their Google Calendar account via OAuth.

#### Scenario: Initiate Google Calendar connection
- **WHEN** a user clicks "Connect Google Calendar" in settings
- **THEN** the system redirects to Google OAuth consent screen requesting `openid`, `email`, `profile`, and `calendar` scopes

#### Scenario: Successful OAuth callback
- **WHEN** a user authorizes the Google OAuth application
- **THEN** the system resolves the user's email from Google's userinfo endpoint
- **AND** the system stores the access token, refresh token, and token expiry encrypted in `calendar_connections`
- **AND** the system stores the user's Google email and primary calendar ID
- **AND** the settings page shows "Connected as user@gmail.com"

#### Scenario: OAuth denied
- **WHEN** a user denies the Google OAuth request
- **THEN** the system redirects back to settings with a message indicating the connection was not completed