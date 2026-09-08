# Branding

## Purpose

Allow admins to customize the appearance and branding of the public career page.

## Requirements

### Requirement: Career page branding
The Brand settings form contains only title, subtitle (short description), about (long Markdown story), and save — no logo upload, no color picker, no Published toggle. Branding is always live. An Edit/Preview tab switcher shows the rendered result (title, subtitle, about) exactly as the public page displays it.

#### Scenario: Set page text
- **WHEN** an admin sets title, subtitle, and about
- **THEN** those values appear on the career page

#### Scenario: Edit company story
- **WHEN** an admin writes Markdown in the about field
- **THEN** the Preview tab shows it rendered (headings, lists, links)
- **AND** saving publishes it immediately with no extra step

### Requirement: Branding settings UI
The system SHALL provide a settings page for branding configuration.

#### Scenario: Branding settings page
- **WHEN** an admin navigates to Settings → Branding
- **THEN** they see fields for title, subtitle, and about plus Edit/Preview tabs and save
- **AND** a preview of how the career page will look showing title, subtitle, and rendered about exactly as the public page displays it
- **AND** there is no logo upload, color picker, or Published toggle

### Requirement: Branding persistence
The system SHALL store branding settings in tenant.settings JSONB.

#### Scenario: Save branding
- **WHEN** an admin saves branding settings
- **THEN** the tenant.settings JSONB is updated
- **AND** the career page reflects the changes immediately
