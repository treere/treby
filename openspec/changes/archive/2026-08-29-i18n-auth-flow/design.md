## Context

The app supports English and Italian via Gettext. The i18n infrastructure is complete and working:

- `TrebyWeb.Plugs.SetLocale` resolves the locale per-request (session → Accept-Language → default) and assigns `@locale` to the connection, so controller-rendered templates already receive the locale.
- `TrebyWeb.Hooks.SetLocale` does the same for LiveViews inside `live_session`.
- The `LocaleController` persists the locale in session; the `locale_switcher` component renders on auth pages and the app shell.
- Catalan files exist at `priv/gettext/en/` and `priv/gettext/it/`, and LiveView pages (home, settings, etc.) translate correctly.

The gap: the **unauthenticated auth pages** are controller-rendered templates whose strings are hardcoded English. No `gettext()` calls were ever added, so the strings were never extracted and never translated. Verified with Playwright: switching locale to Italian on `/register` keeps the whole page in English.

Affected surfaces (all hardcoded English, no `gettext()`):

| Surface | Files |
|---|---|
| Register (email step) | `registration_html/new.html.heex` |
| Register (verify step) | `registration_html/verify.html.heex` |
| Register (setup step) | `registration_html/setup.html.heex` |
| Login | `session_html/new.html.heex` |
| Password reset (request) | `password_reset_html/new.html.heex` |
| Password reset (edit) | `password_reset_html/edit.html.heex` |
| Invite accept | `invite_html/show.html.heex` |
| Controller flash messages | `registration_controller.ex`, `session_controller.ex`, `password_reset_controller.ex`, `invite_controller.ex`, `candidate_otp_controller.ex`, `google_auth_controller.ex` |

Email templates (`registration_otp_email.ex`, `password_reset_email.ex`, `invites_email.ex`) are also hardcoded English but are **out of scope** for this change.

## Goals / Non-Goals

**Goals:**
- All unauthenticated browser-rendered auth pages display the user's selected locale (en/it).
- All auth controller flash messages are translated.
- Italian translations provided for every newly extracted string.
- Existing test suite remains green (English assertions updated only where strings change).

**Non-Goals:**
- Translating email templates (OTP, password reset, invites) — separate concern, follow-up.
- Adding new locales beyond en/it.
- Refactoring the locale resolution infrastructure (it works).
- Translating the candidate portal or the authenticated app shell (already handled or separate scope).

## Decisions

### D1. Use existing `gettext()` in templates and controllers
The infrastructure already exists; this is purely about wrapping strings. Wrap literal strings in `gettext/1` in HEEx templates (`gettext("Create your account")`) and controllers (`put_flash(:error, gettext("Invalid or expired code"))`).

- *Alternative considered*: a translation dictionary / Fluent-style system — rejected, Gettext is already the app standard.
- *Alternative considered*: `dgettext` with a custom domain — unnecessary, one default domain is fine.

### D2. Interpolated strings use `gettext("...")` with placeholders
For strings with interpolation, use Gettext interpolation: `gettext("We sent a verification code to %{email}", email: email)`. This keeps the full sentence translatable as a unit rather than string concatenation. Same for `gettext("Welcome to %{name}!", name: tenant.name)`.

### D3. Dynamic `message` variables in `password_reset_controller` must be sourced from gettext at the call site
Lines 19 and 31 pass a `message` variable built elsewhere. Move the `gettext()` call to where the literal message is defined (likely `PasswordResetEmail` or a helper), so the string is extracted and translated.

### D4. Validation errors already handled by `errors.po`
Schema-level errors like "has already been taken" are rendered by `<.input>`/CoreComponents through the `errors.po` catalog. Verify they have Italian translations; add any missing ones. Do not re-wrap these in templates.

### D5. Extraction workflow
After wrapping:
1. `mix gettext.extract` — regenerates `.pot` and updates `.po` reference comments
2. `mix gettext.merge priv/gettext` — syncs catalogs
3. Add Italian `msgstr` for all new `msgid`s in `it/LC_MESSAGES/default.po`
4. `mix compile --warnings-as-errors` to catch any missed/unwrapped strings? No — Gettext falls back to the `msgid` if no translation exists, so compile won't catch it. Instead rely on the spec verification step + Playwright check.

### D6. Test strategy
- Existing controller tests that assert on English UI/flash strings must be updated if the underlying string changed (most won't, since `msgid` stays English).
- Add a Playwright/manual verification step: switch locale to Italian on each auth page and assert translated text.
- Gettext's behavior: when `msgid` == English text and no `it` translation exists, fallback renders English. After adding translations, Italian renders.

## Risks / Trade-offs

- **Missed strings** (some template literal still not wrapped) → run a codebase grep for remaining literal English in auth templates during verification; Playwright checks each page.
- **Flash message duplication** (`gettext` on a message that's also passed as a variable) → D3: always call `gettext` at the point where the literal lives, never wrap an already-translated variable.
- **Extraction churn** (`mix gettext.extract` rewrites reference line comments across the whole catalog) → expected and harmless; the .po files are autogenerated.
- **English msgid vs Italian copy divergence** — translations could drift out of sync over time → accept as standard Gettext tradeoff; keep msgids stable.
- **Tests asserting English strings break** if a msgid is changed → keep msgids equal to current English strings so tests stay green; only add `msgstr` for Italian.

## Migration Plan

1. Wrap template strings + controller flash messages in `gettext()`.
2. Run `mix gettext.extract` and `mix gettext.merge priv/gettext`.
3. Fill in Italian `msgstr` for all new entries.
4. Update any tests asserting changed strings.
5. Run `mix test` and Playwright verification across all auth pages in Italian.

Rollback: revert the change; Gettext fallback renders English, so worst case is English UI (current state).

## Open Questions

- Should the invite flow translate tenant-provided content (e.g. "Join {tenant.name}")? Tenant names are user data and stay as-is; only the surrounding UI text translates.
- Are there other controller-rendered pages beyond auth with the same gap (e.g. static pages like terms/privacy)? Confirm during implementation and note as follow-up if found.