## Context

`Treby.Calendar.Google` makes direct HTTP calls to Google's OAuth token and Calendar API endpoints using the top-level `Req` API (`Req.post/2`, `Req.new/1`). Two tests in `test/treby/calendar_test.exs` currently depend on `GOOGLE_CLIENT_ID` / `GOOGLE_CLIENT_SECRET` being **absent**: they assert a `RuntimeError` that is raised by `fetch_config!/1` only when the config value is `nil`. When the env vars are present (local dev machine), the code instead performs a real network call to `oauth2.googleapis.com/token`, so no exception is raised and `assert_raise` fails. On CI (no env vars) the opposite happens, so the tests only pass there.

All `Req` usage in the app is Google-related: `Treby.Calendar.Google` and `TrebyWeb.GoogleAuthController`. No other code performs HTTP requests via Req. `test/support` is compiled in test env (`elixirc_paths`), so test helpers are available.

## Goals / Non-Goals

**Goals:**
- Make the two failing tests deterministic and environment-independent.
- Guarantee no `Req` request hits the real network during tests.
- Assert the real, intended behavior of `get_valid_token/1` (lazy token refresh) against a mocked token endpoint.
- Fail loudly if an unstubbed `Req` request is attempted in test.

**Non-Goals:**
- No changes to production code under `lib/`.
- No change to the `google-calendar-integration` requirements/behavior.
- No new runtime or test dependencies (`Req.Test` ships with `:req`).

## Decisions

### 1. Named `Req.Test` stub with global default options
`Req.default_options/0` reads `Application.get_env(:req, :default_options, [])`, which is merged into every `Req.new/1`. In `config/test.exs` set:

```elixir
config :req,
  default_options: [plug: {Req.Test, Treby.GoogleApiMock}]
```

This routes every Req request in test through the `Req.Test` plug named `Treby.GoogleApiMock`. Tests register stubs via `Req.Test.stub(Treby.GoogleApiMock, plug)`. Because the ownership model of `Req.Test` is per-process (nimble_ownership), this works in `async: true` tests as long as the stubbed call happens in the test process — which is the case for direct calls to `Calendar.Google.get_valid_token/1`.

**Alternative considered:** attaching `plug: {Req.Test, name}` per-request in the `Google` module (e.g. via a configurable Req base). Rejected: it would require `lib/` changes, and the global default is strictly safer (any unstubbed request raises "no mock or stub" instead of hitting the network).

**Alternative considered:** `Req.Test.stub(Req, fun)` (legacy adapter-on-struct API). Rejected: it only stubs requests made through the returned request struct; the `Google` module builds its own `Req.new/1`, so it would not be intercepted.

### 2. Deterministic dummy credentials in `config/test.exs`
`fetch_config!/1` raises when `google_client_id`/`google_client_secret` are `nil`. Set dummy values in test config so token refresh proceeds to the mocked endpoint:

```elixir
config :treby,
  google_client_id: "test-client-id",
  google_client_secret: "test-client-secret"
```

`config/test.exs` is imported after `config.exs`, so it overrides the env-var-based values.

### 3. `test/support/google_api_mock.ex` helper module
A small helper exposing intent-revealing stubs:

- `stub_token_refresh(access_token, expires_in \\ 3600)` — stubs the token endpoint (`POST /token`) to return `200` with a JSON body containing `access_token` and `expires_in`.
- `stub_token_error(status, body)` — stubs the token endpoint to return an error status/body (used for the refresh-failure scenario).

Each stub asserts `conn.request_path == "/token"` so a wrong endpoint fails fast. `Req.Test.json/2` honors `conn.status` (via `Plug.Conn.put_status/2`), so error responses are straightforward.

### 4. Rewrite the two environment-dependent tests
The tests "returns error when token_expires_at is nil" and "returns error when access_token is nil" were asserting the missing-config guard. Replace them with tests that assert the actual spec behavior (lazy token refresh):

- A connection with a refresh token and `token_expires_at: nil` → stub token refresh → assert `{:ok, "refreshed-token"}` and that the persisted `access_token`/`token_expires_at` were updated.
- A connection with `access_token: nil` (refresh token present) → stub token refresh → assert `{:ok, "refreshed-token"}`.
- A connection whose refresh fails (stubbed `400` response) → assert `{:error, {:refresh_failed, _}}`.
- Keep the existing valid-token and `:no_refresh_token` tests unchanged (no HTTP involved).

## Risks / Trade-offs

- **Global `:req` default options** → Affects every Req request in test, including `GoogleAuthController`. Mitigation: all Req usage is Google-related and no other test exercises it; an unstubbed request raises "no mock or stub", which surfaces a clear error rather than a network call. If a future non-Google Req call is added, its tests must stub it too.
- **Stub ownership and async tests** → If a stub is needed from a different process than the test (e.g. Oban inline jobs), `Req.Test.allow/3` would be required. Mitigation: the changed tests call `get_valid_token/1` directly from the test process; note this limitation in the helper moduledoc.
- **Stub must be registered per test** → Tests that exercise HTTP paths must call the helper. Mitigation: stubs are cheap and idiomatic; the rewrite includes all currently-HTTP-exercising tests.