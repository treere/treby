## 1. Test configuration

- [x] 1.1 Add dummy Google credentials and the global `Req.Test` stub routing to `config/test.exs` (`config :req, default_options: [plug: {Req.Test, Treby.GoogleApiMock}]` and `config :treby, google_client_id: "test-client-id", google_client_secret: "test-client-secret"`)

## 2. Test helper

- [x] 2.1 Create `test/support/google_api_mock.ex` with `Treby.GoogleApiMock` exposing `stub_token_refresh/2` and `stub_token_error/2`, both asserting `conn.request_path == "/token"`

## 3. Rewrite environment-dependent tests

- [x] 3.1 Replace the `"returns error when token_expires_at is nil"` test with a test asserting a successful token refresh (`{:ok, "refreshed-token"}`) and persisted `access_token` / `token_expires_at` update
- [x] 3.2 Replace the `"returns error when access_token is nil"` test with a test asserting a successful token refresh when `access_token` is `nil`
- [x] 3.3 Add a test asserting `{:error, {:refresh_failed, _}}` when the stubbed token endpoint returns a non-200 status

## 4. Verification

- [x] 4.1 Run `mix test` locally (env vars set) and confirm the 356-test suite passes with no failures
- [x] 4.2 Confirm `mix test` also passes with `GOOGLE_CLIENT_ID` / `GOOGLE_CLIENT_SECRET` unset (simulating CI), e.g. `env -u GOOGLE_CLIENT_ID -u GOOGLE_CLIENT_SECRET mix test test/treby/calendar_test.exs`