# i18n

## Purpose

Localize the application's user-facing text into the user's selected locale (Italian or English), including auth pages, flash messages, and interpolated strings.

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
The system SHALL ship Italian translations (`msgstr`) for every user-facing string introduced by the auth flow localization in `priv/gettext/it/LC_MESSAGES/default.po`.

#### Scenario: No missing Italian translations
- **WHEN** the auth flow localization is complete
- **THEN** every `msgid` in the default catalog that corresponds to an auth page or flash string has a non-empty Italian `msgstr`

### Requirement: Interpolated strings preserve dynamic content
The system SHALL translate full sentences that contain dynamic values (e.g., verification codes, emails, tenant names) as single units using Gettext interpolation, preserving the dynamic value in the translated output.

#### Scenario: Verification email message in Italian
- **WHEN** a user with the Italian locale requests a verification code
- **THEN** the flash message containing their email address is shown in Italian with the email address preserved

#### Scenario: Invite welcome message in Italian
- **WHEN** a user with the Italian locale accepts an invite for a tenant
- **THEN** the welcome flash message is shown in Italian with the tenant name preserved