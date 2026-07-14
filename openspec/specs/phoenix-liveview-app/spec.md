# Phoenix LiveView Application

## Purpose
Phoenix LiveView web application with real-time capabilities, proper configuration, and working examples.

## Requirements

### Requirement: Phoenix project initialization
The system SHALL be initialized using `mix phx.new` with the `--live` flag to create a Phoenix LiveView application.

#### Scenario: Project creation
- **WHEN** developer runs `mix phx.new . --live`
- **THEN** a complete Phoenix LiveView project structure is created with:
  - Application module and supervision tree
  - LiveView router and examples
  - HTML templates and layouts
  - Asset pipeline configuration
  - Test infrastructure

### Requirement: LiveView examples
The system SHALL include working LiveView examples that demonstrate real-time functionality.

#### Scenario: LiveDashboard access
- **WHEN** developer navigates to `/dashboard`
- **THEN** the Phoenix LiveDashboard is accessible showing application metrics

#### Scenario: LiveView page
- **WHEN** developer navigates to the root path
- **THEN** a LiveView page is rendered with real-time updates

### Requirement: Application configuration
The system SHALL have proper application configuration for development, test, and production environments.

#### Scenario: Development configuration
- **WHEN** application starts in development mode
- **THEN** it uses development-specific configuration (debug logging, code reloading, etc.)

#### Scenario: Environment variables
- **WHEN** application starts
- **THEN** it reads configuration from environment variables where appropriate
