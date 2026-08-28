## Context

The Google Calendar integration shipped with code that looked correct but failed at every runtime step: the OAuth consent requested only the calendar scope (so Google's userinfo endpoint returned an error and the user's email could not be resolved), the auth plug assigned an unloaded `tenant` association (causing a `KeyError` on `tenant.id` in the callback and resume controller), and encrypted token storage crashed because `CLOAK_KEY` was set to an empty string while the vault read it directly and the bundled dev key was an invalid 37-byte string.

Configuration was also fragile: empty environment variables (e.g. `CLOAK_KEY=`) silently overrode development defaults.

## Goals / Non-Goals

**Goals:**
- Make the Google Calendar connect flow work end-to-end against a real Google account.
- Treat empty environment variables as unset so development defaults apply.
- Ship a valid dev encryption key and document local configuration via `.env.example`.

**Non-Goals:**
- Google verification / publishing the OAuth consent screen (out of scope; noted as ops work).
- New Google APIs beyond calendar + OpenID Connect userinfo.
- Changing the production deployment topology.

## Decisions

1. **Add OpenID Connect scopes to the OAuth request.** Google's `oauth2/v2/userinfo` endpoint is an OpenID Connect endpoint and requires the `openid` scope; `email` and `profile` ensure the userinfo payload includes the email and basic profile. Chosen over alternatives:
   - *Alternative: parse `id_token` from the token exchange* — viable, but requires JWT decoding logic; the existing code already calls userinfo, so extending scopes was the smallest change.
   - *Alternative: fetch email via a Calendar API call* — no simple email endpoint; userinfo is the canonical way.

2. **Preload the `tenant` association in the auth plug.** `assign(:current_tenant, user.tenant)` crashed wherever `current_tenant.id` was read (OAuth callback, resume controller). Preloading in the plug fixes all consumers at once rather than patching each caller. Alternative (loading from session id per caller) was rejected as repetitive and error-prone.

3. **Centralize env-var handling in `Treby.ConfigHelpers`.** `env/1,2` and `present?/1` treat empty strings as unset. Defined in `config/config.exs` (loaded before `dev.exs`/`runtime.exs`) so every config file can use it. The vault now goes through the same helper instead of reading `System.get_env/1` directly.

4. **Valid 32-byte dev encryption key.** The old default base64-decoded to 37 bytes, which AES-256-GCM rejects. Replaced with a generated 32-byte key (`openssl rand -base64 32`); `test.exs` already had a valid one. Prod is unaffected — `runtime.exs` only overrides `:cloak_key` when `CLOAK_KEY` is non-empty.

5. **Dev config becomes env-driven with fallbacks.** `SECRET_KEY_BASE`, the S3/MinIO block, and `CLOAK_KEY` in `config/dev.exs` read from env vars with the prior hard-coded values as defaults, matching `.env.example`.

## Risks / Trade-offs

- [Testing-mode OAuth limits] → Test users and refresh tokens expire (7 days). Documented; production requires Google verification.
- [Config helpers run at config-load time] → `Treby.ConfigHelpers` must be defined in `config.exs` before other config files; it is.
- [Dev encryption key change invalidates previously encrypted dev data] → Acceptable for a dev database; `mix ecto.reset` clears it.
- [Empty env vars silently falling back] → Desired behavior, but could mask a mis-set variable in production; required values still raise (e.g. `DATABASE_URL`, `SECRET_KEY_BASE`).