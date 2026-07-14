## ADDED Requirements

### Requirement: Docker Compose file
The system SHALL provide a `docker-compose.yml` file at the project root.

#### Scenario: File exists
- **WHEN** developer examines the project root
- **THEN** `docker-compose.yml` exists with proper structure

### Requirement: PostgreSQL service
The system SHALL define a PostgreSQL service in Docker Compose.

#### Scenario: PostgreSQL container
- **WHEN** developer runs `docker-compose up db`
- **THEN** a PostgreSQL 18 container starts and is accessible on port 5432

#### Scenario: Data persistence
- **WHEN** developer stops and restarts the PostgreSQL container
- **THEN** database data is preserved via a named volume

#### Scenario: Environment configuration
- **WHEN** PostgreSQL container starts
- **THEN** it uses environment variables for database name, user, and password

### Requirement: Phoenix application service
The system SHALL define a Phoenix application service in Docker Compose (optional).

#### Scenario: Application container
- **WHEN** developer runs `docker-compose up app`
- **THEN** the Phoenix application starts and is accessible on port 4000

#### Scenario: Database dependency
- **WHEN** the Phoenix application service starts
- **THEN** it waits for the PostgreSQL service to be ready

### Requirement: Development workflow
The system SHALL support a development workflow with Docker Compose.

#### Scenario: Database only
- **WHEN** developer runs `docker-compose up db`
- **THEN** only the PostgreSQL database starts (for local Phoenix development)

#### Scenario: Full stack
- **WHEN** developer runs `docker-compose up`
- **THEN** both PostgreSQL and Phoenix services start

### Requirement: Volume configuration
The system SHALL configure named volumes for data persistence.

#### Scenario: Volume definition
- **WHEN** developer examines `docker-compose.yml`
- **THEN** a named volume is defined for PostgreSQL data

#### Scenario: Volume mounting
- **WHEN** PostgreSQL container starts
- **THEN** it mounts the named volume to the appropriate directory