## Why

The unauthenticated auth flow (register, verify, setup, login) displays hardcoded English strings even when the user switches the locale to Italian. The i18n infrastructure (Gettext, `SetLocale` plug, locale switcher, `it/LC_MESSAGES/*.po` catalogs) already works — but the auth templates were never wrapped in `gettext()`, so there is nothing to translate. This is a visible gap: the rest of the app translates, the auth pages don't.

## What Changes

- Wrap all user-facing strings in the unauthenticated auth templates in `gettext()`:
  - `registration_html/new.html.heex` (email step)
  - `registration_html/verify.html.heex` (verification code step)
  - `registration_html/setup.html.heex` (account setup step)
  - `session_html/new.html.heex` (login)
- Wrap all user-facing flash messages in the auth controllers (`registration_controller.ex`, and any other auth controllers with user-facing strings) in `gettext()`.
- Extract the new strings (`mix gettext.extract`) and merge into the `it` catalog (`mix gettext.merge priv/gettext`).
- Provide Italian translations for all newly extracted strings.
- Keep validation error messages (handled by `errors.po`) consistent.

## Capabilities

### New Capabilities
- `i18n`: Localization of the unauthenticated authentication flow so that register, verify, setup, and login pages render in the user's selected locale (currently English and Italian).

### Modified Capabilities
<!-- None: no existing spec has localization requirements. -->

## Impact

- **Templates**: `lib/treby_web/controllers/registration_html/*.heex`, `lib/treby_web/controllers/session_html/new.html.heex`
- **Controllers**: `lib/treby_web/controllers/registration_controller.ex` (flash messages); possibly `session_controller.ex`, password-reset controllers
- **Catalogs**: `priv/gettext/en/LC_MESSAGES/default.po`, `priv/gettext/it/LC_MESSAGES/default.po` (regenerated)
- **Infrastructure**: reuses existing `Gettext`, `SetLocale` plug, and locale switcher — no new dependencies
- **Tests**: existing auth tests may need updating if they assert on English strings; new assertions on Italian where appropriate
