# Landing Page

## Purpose

Public-facing landing page at the root URL that introduces the product and provides entry points for visitors.

## Requirements

### Requirement: Landing page content
The system SHALL display a public landing page at the root URL (`/`).

#### Scenario: Page loads successfully
- **WHEN** a visitor navigates to `/`
- **THEN** the landing page renders with the product name "Treby"
- **AND** a tagline describing the product is visible
- **AND** a call-to-action button is present

#### Scenario: Responsive design
- **WHEN** a visitor views the landing page on mobile (viewport < 640px)
- **THEN** the layout adapts to a single-column format
- **AND** all content remains readable and accessible

### Requirement: Navigation links
The system SHALL provide navigation links to key public pages.

#### Scenario: Login link
- **WHEN** a visitor views the landing page
- **THEN** a "Log in" link is visible in the header
- **AND** clicking it navigates to `/login`

#### Scenario: Register link
- **WHEN** a visitor views the landing page
- **THEN** a "Sign up" or "Get started" link is visible
- **AND** clicking it navigates to `/register`

### Requirement: Feature showcase
The system SHALL display key product features on the landing page.

#### Scenario: Feature cards
- **WHEN** a visitor scrolls down the landing page
- **THEN** at least 3 feature cards are visible
- **AND** each card has a title and brief description
- **AND** features include job management, candidate tracking, and interview scheduling

### Requirement: Footer
The system SHALL display a footer with basic information.

#### Scenario: Footer content
- **WHEN** a visitor scrolls to the bottom of the landing page
- **THEN** a footer is visible with the product name
- **AND** copyright or attribution text is present

### Requirement: Careers discovery
The system SHALL provide a discoverable link to the public job board from the landing page.

#### Scenario: Careers link in header
- **WHEN** a visitor views the landing page
- **THEN** a "Careers" link is visible in the header
- **AND** clicking it navigates to `/careers`

#### Scenario: Careers link in footer
- **WHEN** a visitor scrolls to the footer of the landing page
- **THEN** a "Careers" link is visible alongside existing footer links
- **AND** it navigates to `/careers`
