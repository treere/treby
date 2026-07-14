## Why

This project needs a complete development environment setup. We're starting from scratch and need to establish a modern Elixir/Phoenix foundation with LiveView, integrate Tidewave for AI-assisted development, and containerize the database for consistent development across environments.

## What Changes

- Initialize a new Phoenix LiveView project with the latest dependencies
- Add Tidewave integration for AI-assisted coding within the Phoenix app
- Configure opencode to work with Tidewave for local development assistance
- Set up PostgreSQL 18 as the primary database
- Create a docker-compose configuration for Phoenix services and PostgreSQL
- Establish a development workflow that supports both local and containerized environments

## Capabilities

### New Capabilities
- `phoenix-liveview-app`: Core Phoenix application with LiveView, HTML templates, and basic routing
- `tidewave-integration`: Tidewave server setup within the Phoenix application for AI tooling
- `opencode-tidewave`: opencode configuration to connect to the local Tidewave instance
- `postgres-database`: PostgreSQL 18 database setup with Ecto configuration
- `docker-compose-services`: Container definitions for Phoenix app and PostgreSQL with volume persistence

### Modified Capabilities
None - this is a greenfield project.

## Impact

- New Elixir/Phoenix project structure in the repository root
- Dependencies added to mix.exs (Phoenix, LiveView, Tidewave, Postgrex, Ecto)
- Configuration files for database, Tidewave, and opencode
- Docker infrastructure files (docker-compose.yml, Dockerfile)
- Environment variable templates for database and service configuration