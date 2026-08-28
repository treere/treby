## ADDED Requirements

### Requirement: Empty environment variables fall back to defaults
The system SHALL treat empty environment variables as if they were unset when resolving configuration, so configured defaults apply.

#### Scenario: Variable is unset
- **WHEN** an environment variable is not set
- **THEN** the configured default value is used

#### Scenario: Variable is present but empty
- **WHEN** an environment variable is set to an empty string
- **THEN** the configured default value is used

#### Scenario: Variable is set to a value
- **WHEN** an environment variable is set to a non-empty value
- **THEN** that value is used, overriding the default

### Requirement: Development encryption key is valid
The system SHALL provide a valid 32-byte base64-encoded encryption key as the development default for Cloak.

#### Scenario: Development runs with default key
- **WHEN** the application runs in the `dev` environment without a `CLOAK_KEY`
- **THEN** encryption of sensitive fields (e.g., Google tokens) succeeds using the default 32-byte key

#### Scenario: Explicit key overrides default
- **WHEN** a non-empty `CLOAK_KEY` is provided
- **THEN** encryption uses that key instead of the dev default

### Requirement: Local environment configuration is documented
The system SHALL document the environment variables the application reads.

#### Scenario: Example env file provided
- **WHEN** a developer sets up the project locally
- **THEN** an `.env.example` lists every environment variable with a description and dev defaults

#### Scenario: Local env file is not tracked
- **WHEN** a developer creates a local `.env` file with their own values
- **THEN** it is ignored by version control