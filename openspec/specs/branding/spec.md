# Branding

## Purpose

Allow admins to customize the appearance and branding of the public career page.

## Requirements

### Requirement: Career page branding
The system SHALL allow admins to customize the career page appearance.

#### Scenario: Set logo
- **WHEN** an admin uploads a logo
- **THEN** the logo appears on the career page header

#### Scenario: Set primary color
- **WHEN** an admin sets a primary color (hex code)
- **THEN** the career page uses that color for buttons and accents

#### Scenario: Set page text
- **WHEN** an admin sets title and description
- **THEN** those values appear on the career page

### Requirement: Branding settings UI
The system SHALL provide a settings page for branding configuration.

#### Scenario: Branding settings page
- **WHEN** an admin navigates to Settings → Branding
- **THEN** they see fields for logo upload, primary color, title, and description
- **AND** a preview of how the career page will look

### Requirement: Branding persistence
The system SHALL store branding settings in tenant.settings JSONB.

#### Scenario: Save branding
- **WHEN** an admin saves branding settings
- **THEN** the tenant.settings JSONB is updated
- **AND** the career page reflects the changes immediately
