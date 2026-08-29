# Google Calendar Test Mocking

## Purpose

Provide deterministic, network-free testing of the Google Calendar API client by routing all Req requests through a `Req.Test` stub in the test environment.

## Requirements

### Requirement: Tests never hit the real network
The system SHALL ensure that all `Req` requests made during tests are routed through a `Req.Test` stub, so no test performs a real HTTP call to Google.

#### Scenario: Req request without a registered stub
- **WHEN** any test makes a `Req` request and no stub is registered for `Treby.GoogleApiMock`
- **THEN** the request raises an error indicating no mock or stub is registered

#### Scenario: Req request with a registered stub
- **WHEN** any test makes a `Req` request and a stub is registered for `Treby.GoogleApiMock`
- **THEN** the request is handled by the registered stub without any network access

### Requirement: Google token refresh is testable deterministically
The system SHALL allow tests to stub the Google OAuth token endpoint so token refresh behavior can be asserted without environment variables or real credentials.

#### Scenario: Stub a successful token refresh
- **WHEN** a test registers a `stub_token_refresh` stub on `Treby.GoogleApiMock`
- **THEN** a call to `Calendar.Google.get_valid_token/1` that requires a refresh returns the stubbed access token
- **AND** the persisted `access_token` and `token_expires_at` are updated

#### Scenario: Stub a failed token refresh
- **WHEN** a test registers a `stub_token_error` stub on `Treby.GoogleApiMock` with a non-200 status
- **THEN** a call to `Calendar.Google.get_valid_token/1` that requires a refresh returns `{:error, {:refresh_failed, _}}`

### Requirement: Google client tests are environment-independent
The system SHALL configure dummy Google credentials in the test environment so `fetch_config!/1` in `Treby.Calendar.Google` never raises `RuntimeError` due to missing configuration.

#### Scenario: Test env has no GOOGLE_CLIENT_ID / GOOGLE_CLIENT_SECRET env vars
- **WHEN** tests run with `GOOGLE_CLIENT_ID` and `GOOGLE_CLIENT_SECRET` unset (as on CI)
- **THEN** `config/test.exs` still provides non-nil `google_client_id` and `google_client_secret` values

#### Scenario: Test env has GOOGLE_CLIENT_ID / GOOGLE_CLIENT_SECRET env vars set
- **WHEN** tests run with `GOOGLE_CLIENT_ID` and `GOOGLE_CLIENT_SECRET` set (as on a developer machine)
- **THEN** the same tests pass, because `config/test.exs` overrides the env-var-derived values with deterministic test values