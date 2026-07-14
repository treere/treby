## ADDED Requirements

### Requirement: opencode configuration file
The system SHALL create an `.opencode/config.json` file for opencode configuration.

#### Scenario: Configuration file exists
- **WHEN** developer examines the project root
- **THEN** `.opencode/config.json` exists with proper structure

### Requirement: Tidewave MCP server configuration
The system SHALL configure opencode to connect to the local Tidewave MCP server.

#### Scenario: MCP server configured
- **WHEN** opencode starts
- **THEN** it connects to the local Tidewave instance at the configured endpoint

#### Scenario: Server endpoint configuration
- **WHEN** developer examines `.opencode/config.json`
- **THEN** the Tidewave server endpoint is configured (default: `http://localhost:4000/tidewave`)

### Requirement: Phoenix project context
The system SHALL configure opencode to access Phoenix project context through Tidewave.

#### Scenario: Context available
- **WHEN** opencode connects to Tidewave
- **THEN** it can access Phoenix project structure, modules, and documentation

### Requirement: Development workflow
The system SHALL support a development workflow where opencode assists with Phoenix development.

#### Scenario: Code assistance
- **WHEN** developer uses opencode in the project
- **THEN** it provides context-aware suggestions based on the Phoenix codebase