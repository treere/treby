## ADDED Requirements

### Requirement: Tidewave dependency
The system SHALL include Tidewave as a dependency in `mix.exs`.

#### Scenario: Dependency added
- **WHEN** developer examines `mix.exs`
- **THEN** Tidewave is listed in the dependencies section

### Requirement: Tidewave supervision tree
The system SHALL start Tidewave in the application supervision tree.

#### Scenario: Application startup
- **WHEN** the Phoenix application starts
- **THEN** Tidewave server is started and available

### Requirement: Tidewave configuration
The system SHALL configure Tidewave via application configuration.

#### Scenario: Configuration present
- **WHEN** developer examines `config/` files
- **THEN** Tidewave configuration is present with appropriate defaults

#### Scenario: Runtime configuration
- **WHEN** application starts in production
- **THEN** Tidewave configuration can be overridden via environment variables

### Requirement: Tidewave endpoint
The system SHALL expose Tidewave's MCP endpoint for AI tool integration.

#### Scenario: MCP endpoint accessible
- **WHEN** AI tools connect to the Tidewave endpoint
- **THEN** they can access Phoenix project context and capabilities