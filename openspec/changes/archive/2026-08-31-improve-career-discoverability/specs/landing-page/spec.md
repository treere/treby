## MODIFIED Requirements

### Requirement: Navigation links
The system SHALL provide navigation links to key public pages including careers discovery.

#### Scenario: Login link
- **WHEN** a visitor views the landing page
- **THEN** a "Log in" link is visible in the header
- **AND** clicking it navigates to `/login`

#### Scenario: Register link
- **WHEN** a visitor views the landing page
- **THEN** a "Sign up" or "Get started" link is visible
- **AND** clicking it navigates to `/register`

#### Scenario: Careers discovery link in header
- **WHEN** a visitor views the landing page
- **THEN** a "Careers" (or localized equivalent) link is visible in the header
- **AND** clicking it navigates to `/careers`

#### Scenario: Careers link in footer
- **WHEN** a visitor scrolls to the footer of the landing page
- **THEN** a "Careers" link is visible alongside existing footer links
- **AND** it navigates to `/careers`
