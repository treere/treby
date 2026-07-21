## ADDED Requirements

### Requirement: Locale resolution
The system SHALL resolve the user's locale using a fallback chain: browser `Accept-Language` header, session stored locale, user preference, then default `"en"`.

#### Scenario: Browser locale detection
- **WHEN** an anonymous user visits the site with `Accept-Language: it-IT`
- **THEN** the page renders in Italian

#### Scenario: Session locale override
- **WHEN** a user has `locale: "it"` in their session
- **THEN** the page renders in Italian regardless of browser header

#### Scenario: User preference
- **WHEN** a logged-in user has `locale: "it"` in their user record
- **THEN** the session and page render in Italian

#### Scenario: Default fallback
- **WHEN** no locale is detected from browser, session, or user
- **THEN** the page renders in English

### Requirement: Dynamic HTML lang attribute
The system SHALL set the `<html lang="...">` attribute to the resolved locale.

#### Scenario: HTML lang matches locale
- **WHEN** the resolved locale is `"it"`
- **THEN** the `<html>` tag has `lang="it"`

### Requirement: Gettext integration
The system SHALL call `Gettext.put_locale/1` with the resolved locale on each request.

#### Scenario: Locale applied to translations
- **WHEN** a page renders with locale `"it"`
- **THEN** all `gettext()` calls return Italian translations when available

### Requirement: Translation files
The system SHALL provide Italian translation files for UI strings.

#### Scenario: Italian translations exist
- **WHEN** the system compiles with Italian locale
- **THEN** `priv/gettext/it/LC_MESSAGES/default.po` exists with translated strings
