## Why

The Google Calendar integration was implemented but could not actually be used: the OAuth flow, the callback, and the encrypted token storage all failed at runtime. Setting up the integration also surfaced configuration bugs (empty environment variables overriding dev defaults, and an invalid default encryption key).

## What Changes

- **OAuth scopes**: request `openid email profile` in addition to the calendar scope, so Google's userinfo endpoint returns the user's email (it previously returned 401/403).
- **Auth plug tenant preload**: preload the `tenant` association in `TrebyWeb.Plugs.Auth` so `current_tenant` is a loaded tenant instead of `%Ecto.Association.NotLoaded{}` (the OAuth callback and resume controller crashed on `tenant.id`).
- **Cloak encryption key handling**: `Treby.Vault` now treats an empty `CLOAK_KEY` as unset and falls back to the configured `:cloak_key`, and `config/dev.exs` now ships a valid 32-byte default key (the previous default was a 37-byte string that AES-256-GCM rejects).
- **Environment config**: new `Treby.ConfigHelpers` treats empty environment variables as absent so dev defaults apply; added `.env.example` documenting the full variable set.
- **Dev config env-driven**: `config/dev.exs` reads `SECRET_KEY_BASE`, S3/MinIO, and `CLOAK_KEY` from environment variables with the prior values as fallbacks.

## Capabilities

### New Capabilities

- `environment-config`: Centralized env var handling — empty values treated as unset, dev defaults as fallback, documented `.env` setup, and a working default encryption key.

### Modified Capabilities

- `google-calendar-integration`: OAuth consent now requests `openid email profile` alongside the calendar scope so the user's email can be resolved; the connect flow works end-to-end (redirect → consent → token exchange → encrypted token storage → settings shows "Connected").

## Impact

- `lib/treby_web/controllers/google_auth_controller.ex` — OAuth scope list.
- `lib/treby_web/plugs/auth.ex` — preload tenant association.
- `lib/treby/vault.ex` — empty-env handling for the Cloak key.
- `config/config.exs`, `config/dev.exs`, `config/runtime.exs` — env-driven config via `Treby.ConfigHelpers`.
- `.env.example`, `.gitignore` — new local configuration files.
- Runtime behavior verified end-to-end against a real Google account (freeBusy API call succeeds).