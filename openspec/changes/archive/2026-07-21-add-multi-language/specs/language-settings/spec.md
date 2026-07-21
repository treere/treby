## ADDED Requirements

### Requirement: User locale preference
The system SHALL allow users to set their preferred language in settings.

#### Scenario: Language settings page
- **WHEN** a user navigates to `/app/settings/language`
- **THEN** they see a language selector with available languages (English, Italian)

#### Scenario: Save language preference
- **WHEN** a user selects "Italian" and saves
- **THEN** their `locale` field is updated to `"it"`
- **AND** the current session switches to Italian immediately

### Requirement: Header language switcher
The system SHALL provide a quick language switcher in the app header.

#### Scenario: Switcher visibility
- **WHEN** a user views any authenticated page
- **THEN** a language switcher dropdown is visible in the header

#### Scenario: Quick language change
- **WHEN** a user selects a language from the header switcher
- **THEN** the page re-renders in the selected language
- **AND** the preference is saved to their user profile

### Requirement: Public page language links
The system SHALL provide language switching on public pages.

#### Scenario: Landing page language links
- **WHEN** a visitor views the landing page
- **THEN** language links (EN / IT) are visible in the header
- **AND** clicking a link switches the locale for the current session
