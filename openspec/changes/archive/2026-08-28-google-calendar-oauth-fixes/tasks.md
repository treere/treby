## 1. OAuth flow

- [x] 1.1 Add `openid email profile` scopes to the Google OAuth authorization URL alongside the calendar scope
- [x] 1.2 Verify the OAuth callback resolves the user's email via Google's userinfo endpoint

## 2. Auth plug

- [x] 2.1 Preload the `tenant` association in `TrebyWeb.Plugs.Auth` so `current_tenant` is a loaded tenant

## 3. Encryption & configuration

- [x] 3.1 Make `Treby.Vault` treat an empty `CLOAK_KEY` as unset and fall back to the configured `:cloak_key`
- [x] 3.2 Replace the invalid dev default encryption key in `config/dev.exs` with a valid 32-byte base64 key
- [x] 3.3 Add `Treby.ConfigHelpers` (empty env treated as unset) and use it in `config/config.exs`, `config/dev.exs`, and `config/runtime.exs`
- [x] 3.4 Make `SECRET_KEY_BASE`, S3/MinIO, and `CLOAK_KEY` in dev config env-driven with fallbacks

## 4. Local setup & verification

- [x] 4.1 Add `.env.example` documenting all environment variables
- [x] 4.2 Ignore local `.env` in `.gitignore`
- [x] 4.3 Verify the connect flow end-to-end against a real Google account (OAuth → token storage → settings "Connected")
- [x] 4.4 Verify a Google Calendar API call succeeds with the stored token (freeBusy query)