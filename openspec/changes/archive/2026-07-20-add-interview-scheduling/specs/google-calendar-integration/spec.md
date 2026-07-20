## ADDED Requirements

### Requirement: Connect Google Calendar account
The system SHALL allow team members to connect their Google Calendar account via OAuth.

#### Scenario: Initiate Google Calendar connection
- **WHEN** a user clicks "Connect Google Calendar" in settings
- **THEN** the system redirects to Google OAuth consent screen requesting `calendar` scope

#### Scenario: Successful OAuth callback
- **WHEN** a user authorizes the Google OAuth application
- **THEN** the system stores the access token, refresh token, and token expiry encrypted in `calendar_connections`
- **AND** the system stores the user's Google email and primary calendar ID
- **AND** the settings page shows "Connected as user@gmail.com"

#### Scenario: OAuth denied
- **WHEN** a user denies the Google OAuth request
- **THEN** the system redirects back to settings with a message indicating the connection was not completed

### Requirement: Disconnect Google Calendar
The system SHALL allow users to disconnect their Google Calendar account.

#### Scenario: Disconnect calendar
- **WHEN** a user clicks "Disconnect" on the calendar settings page
- **THEN** the system deletes the `calendar_connection` record for that user
- **AND** the user can no longer use scheduling features until they reconnect

### Requirement: Lazy token refresh
The system SHALL refresh expired Google OAuth tokens transparently before API calls.

#### Scenario: Token is valid
- **WHEN** a Google Calendar API call is made and the access token has more than 5 minutes remaining
- **THEN** the system uses the existing access token

#### Scenario: Token is expired or expiring soon
- **WHEN** a Google Calendar API call is made and the access token has 5 minutes or less remaining
- **THEN** the system refreshes the token using the stored refresh token
- **AND** updates the `access_token` and `token_expires_at` in `calendar_connections`
- **AND** makes the API call with the new token

#### Scenario: Refresh token is invalid
- **WHEN** a token refresh fails because the refresh token is revoked
- **THEN** the system marks the connection as requiring re-authorization
- **AND** surfaces an error to the user indicating they need to reconnect

### Requirement: Query calendar free/busy
The system SHALL query Google Calendar free/busy data for connected users.

#### Scenario: Get busy periods for a date range
- **WHEN** the system requests free/busy data for a connected user over a date range
- **THEN** the system calls the Google Calendar FreeBusy API with the user's access token
- **AND** returns a list of busy time periods (start/end UTC pairs) for the user's primary calendar
