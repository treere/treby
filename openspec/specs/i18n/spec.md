# i18n

## Purpose

Localize the entire application's user-facing text into the user's selected locale (Italian or English), covering auth pages, flash messages, interpolated strings, and all authenticated UI (dashboard, jobs, candidates, pipeline, interviews, analytics, settings, candidate portal, career pages).

## Requirements

### Requirement: Auth pages render in the selected locale
The system SHALL display all unauthenticated auth pages (register email step, register verify step, register setup step, login, password reset request, password reset edit, and invite accept) using the user's selected locale, so that all user-facing text is translated into Italian when the locale is Italian and into English otherwise.

#### Scenario: Register page in Italian
- **WHEN** a user selects Italian via the locale switcher and visits `/register`
- **THEN** the heading, subtitle, email field label, and submit button are shown in Italian
- **AND** the locale switcher indicates the Italian locale is active

#### Scenario: Register page in English
- **WHEN** a user selects English via the locale switcher and visits `/register`
- **THEN** all page text is shown in English

#### Scenario: All auth pages translate
- **WHEN** a user with the Italian locale selected visits each of `/register`, `/register/verify`, the account setup step, `/login`, `/reset-password`, and an invite acceptance page
- **THEN** every page's user-facing text is rendered in Italian

### Requirement: Auth flash messages are localized
The system SHALL translate all flash messages emitted by the auth controllers (registration, session, password reset, invite, candidate OTP, Google auth) according to the user's selected locale.

#### Scenario: Invalid login in Italian
- **WHEN** a user with the Italian locale submits invalid credentials at `/login`
- **THEN** the error flash message is shown in Italian

#### Scenario: Successful logout in Italian
- **WHEN** a user with the Italian locale logs out
- **THEN** the confirmation flash message is shown in Italian

#### Scenario: Registration flow messages in Italian
- **WHEN** a user with the Italian locale completes steps of the registration flow (verification code sent, code verified, invalid or expired code)
- **THEN** the corresponding flash messages are shown in Italian

### Requirement: Italian translations exist for all auth strings
The system SHALL ship Italian translations (`msgstr`) for every user-facing string in the application (not only auth) in `priv/gettext/it/LC_MESSAGES/default.po` and `priv/gettext/it/LC_MESSAGES/errors.po`, so that no Italian user sees untranslated English when the locale is Italian.

#### Scenario: No missing Italian translations
- **WHEN** the bilingual coverage is complete
- **THEN** every non-header `msgid` in `priv/gettext/default.pot` (and `errors.pot`) has a non-empty Italian `msgstr` in `priv/gettext/it/LC_MESSAGES/default.po` (and `errors.po`)

#### Scenario: Missing translation fails the guard
- **WHEN** any `msgid` has an empty Italian `msgstr`
- **THEN** `mix treby.check_translations` fails and CI blocks the change

### Requirement: Interpolated strings preserve dynamic content
The system SHALL translate full sentences that contain dynamic values (e.g., verification codes, emails, tenant names) as single units using Gettext interpolation, preserving the dynamic value in the translated output.

#### Scenario: Verification email message in Italian
- **WHEN** a user with the Italian locale requests a verification code
- **THEN** the flash message containing their email address is shown in Italian with the email address preserved

#### Scenario: Invite welcome message in Italian
- **WHEN** a user with the Italian locale accepts an invite for a tenant
- **THEN** the welcome flash message is shown in Italian with the tenant name preserved

### Requirement: Full-application bilingual UI (IT/EN)
The system SHALL render every user-facing string in the authenticated application (layouts, navigation, dashboard, jobs, candidates, pipeline, interviews, analytics, settings, candidate portal, career pages, empty states, flash messages) via Gettext (`gettext`/`ngettext`), so that switching the locale between Italian and English translates the entire interface.

#### Scenario: Dashboard renders in Italian
- **WHEN** a user with the Italian locale visits `/app` (dashboard)
- **THEN** all dashboard headings, labels, weekly-stats captions, My Actions headings, empty-state titles/descriptions, and onboarding checklist items are shown in Italian

#### Scenario: Dashboard renders in English
- **WHEN** a user with the English locale visits `/app`
- **THEN** the same dashboard content is shown in English

#### Scenario: No hardcoded user-facing strings outside Gettext
- **WHEN** the codebase is scanned for user-facing literals in `lib/treby_web/live/**` and `lib/treby_web/components/**`
- **THEN** no heading, label, button text, empty-state copy, or flash message is emitted as a raw string literal outside a `gettext` call (excluding brand names and technical identifiers)

#### Scenario: Locale switch persists and applies globally
- **WHEN** a user changes the language in Settings → Language and navigates to any page (dashboard, jobs, candidates, interviews)
- **THEN** the selected locale is applied on every subsequent request until changed again

### Requirement: Catalog extraction and Italian translation completeness
The system SHALL keep `priv/gettext/default.pot` (and `errors.pot`) in sync with source via `mix gettext.extract --merge` and ship complete Italian translations, so that `it` coverage is 100% at all times.

#### Scenario: New string appears in POT after extraction
- **WHEN** a developer wraps a new UI string with `gettext` and runs `mix gettext.extract --merge`
- **THEN** a new `msgid` entry appears in `priv/gettext/default.pot` and is merged into `priv/gettext/it/LC_MESSAGES/default.po` with an empty `msgstr` awaiting translation

#### Scenario: Italian catalog is complete
- **WHEN** `mix treby.check_translations` runs on a complete codebase
- **THEN** it reports 0 missing Italian translations

#### Scenario: Missing Italian translation is caught
- **WHEN** `priv/gettext/it/LC_MESSAGES/default.po` contains any `msgid` with an empty `msgstr`
- **THEN** the guard fails with the list of missing keys
