## Context

This is a greenfield Elixir/Phoenix project. The goal is to establish a modern development environment that leverages:
- Phoenix LiveView for real-time, server-rendered UIs
- Tidewave for AI-assisted development tooling
- PostgreSQL 18 for robust data storage
- Docker Compose for consistent, reproducible environments

The project starts with an empty repository containing only configuration files (opencode, serena, openspec).

## Goals / Non-Goals

**Goals:**
- Create a fully functional Phoenix LiveView application that can be developed locally
- Integrate Tidewave to enable AI coding assistance within the Phoenix app
- Configure opencode to connect to Tidewave for context-aware development
- Set up PostgreSQL 18 with proper Ecto configuration
- Provide Docker Compose configuration for running Phoenix and PostgreSQL services
- Establish a development workflow that works both with and without Docker

**Non-Goals:**
- Production deployment configuration (focus on development only)
- Authentication/authorization (can be added later)
- CI/CD pipeline setup
- Monitoring and observability stack
- Custom Docker images (use official base images)

## Decisions

### 1. Project Initialization: `mix phx.new` with LiveView

**Decision**: Use the standard Phoenix generator with `--live` flag.

**Rationale**: Phoenix generators provide a well-structured starting point with:
- Proper directory layout following Phoenix conventions
- LiveView already wired up with examples
- Test infrastructure in place
- Asset pipeline configured

**Alternatives considered**:
- Manual setup: More control but higher risk of missing conventions
- Using a template repository: Adds unnecessary dependency

### 2. Tidewave Integration

**Decision**: Add Tidewave as a dependency and configure it in the application supervision tree.

**Rationale**: Tidewave provides:
- MCP server for AI tool integration
- Phoenix-specific context gathering
- Live development assistance

**Configuration**: Add to `mix.exs` dependencies and configure in `config/runtime.exs` for flexibility.

### 3. PostgreSQL 18 with Docker

**Decision**: Use the official `postgres:18` Docker image with a named volume for data persistence.

**Rationale**:
- Official images are well-maintained and secure
- Named volumes preserve data between container restarts
- Port mapping allows local tools to connect

**Alternatives considered**:
- Local PostgreSQL installation: Less consistent across development machines
- SQLite for development: Not representative of production PostgreSQL

### 4. Docker Compose Structure

**Decision**: Create a single `docker-compose.yml` with services for PostgreSQL and Phoenix.

**Rationale**:
- Simple to understand and maintain
- Can be extended later with additional services
- Uses `docker-compose` for development workflow

**Services**:
- `db`: PostgreSQL 18 with persistent volume
- `app`: Phoenix application (optional, can run locally)

### 5. opencode Configuration

**Decision**: Create `.opencode/config.json` with Tidewave MCP server configuration.

**Rationale**: Allows opencode to:
- Connect to local Tidewave instance
- Access Phoenix project context
- Provide AI-assisted coding within the IDE

## Risks / Trade-offs

### Risk: Tidewave Version Compatibility
- **Risk**: Tidewave may have specific Phoenix/Elixir version requirements
- **Mitigation**: Check Tidewave documentation for compatibility matrix before implementation

### Risk: Docker Performance on macOS/Windows
- **Risk**: File system performance may be slower with Docker volumes
- **Mitigation**: Use bind mounts for code, named volumes for database only

### Risk: PostgreSQL 18 Availability
- **Risk**: PostgreSQL 18 may not be available as a stable Docker image yet
- **Mitigation**: Fall back to PostgreSQL 16 or 17 if 18 is not stable

### Trade-off: Development vs Production Parity
- **Trade-off**: Using Docker for PostgreSQL but running Phoenix locally
- **Rationale**: Development speed and debugging experience are prioritized
- **Future**: Can add full Docker setup for staging environments

## Open Questions

1. **Tidewave Version**: Which specific version of Tidewave should be used?
2. **Phoenix Version**: Should we use the latest stable Phoenix or a specific version?
3. **Elixir Version**: What Elixir version is required for Tidewave compatibility?
4. **Database Configuration**: Should we use separate database configs for Docker vs local?
5. **opencode Configuration**: What specific Tidewave features should be enabled in opencode?