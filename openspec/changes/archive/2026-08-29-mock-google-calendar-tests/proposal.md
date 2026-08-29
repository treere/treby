## Why

Two tests in `test/treby/calendar_test.exs` pass on CI but fail locally (and vice versa) because they depend on whether `GOOGLE_CLIENT_ID` / `GOOGLE_CLIENT_SECRET` environment variables are set. When the config is missing, `fetch_config!/1` raises a `RuntimeError` (making the `assert_raise` tests pass on CI); when it is present, the code performs a real HTTP call to Google's OAuth token endpoint, so no exception is raised and the tests fail. Tests must be deterministic regardless of the environment and must never perform real network calls.

## What Changes

- Add a test helper module that stubs the Google OAuth token endpoint (and the Calendar API endpoints) using `Req.Test`, so `Calendar.Google` tests never hit the real network.
- Set deterministic, dummy Google credentials in `config/test.exs` so `fetch_config!/1` never raises during tests.
- Rewrite the two environment-dependent tests (`token_expires_at is nil`, `access_token is nil`) to assert the real, intended behavior of `get_valid_token/1` against the mocked token endpoint instead of relying on missing config.
- Keep all existing behavior of the `Treby.Calendar.Google` module unchanged; this is a test-infrastructure-only change.

## Capabilities

### New Capabilities
- `google-calendar-test-mocking`: deterministic, network-free testing of the Google Calendar API client by stubbing the OAuth token and Calendar endpoints with `Req.Test`.

### Modified Capabilities
<!-- None: `google-calendar-integration` requirements are unchanged; this only affects test infrastructure. -->

## Impact

- `test/treby/calendar_test.exs` — rewrite of the `Google.get_valid_token/1` describe block.
- `config/test.exs` — add dummy Google credentials.
- `test/support/google_api_mock.ex` (new) — `Req.Test` helpers for the token and Calendar API endpoints.
- No changes to `lib/`, no new runtime dependencies (`Req.Test` ships with the already-present `:req` dependency).