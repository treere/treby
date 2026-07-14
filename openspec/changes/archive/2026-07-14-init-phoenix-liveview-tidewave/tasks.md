## 1. Project Initialization

- [x] 1.1 Initialize Phoenix LiveView project using `mix phx.new . --live`
- [x] 1.2 Verify project structure and basic routing works
- [x] 1.3 Confirm LiveView examples are functional

## 2. Tidewave Integration

- [x] 2.1 Add Tidewave dependency to `mix.exs`
- [x] 2.2 Configure Tidewave in application supervision tree
- [x] 2.3 Add Tidewave configuration to `config/` files
- [x] 2.4 Verify Tidewave MCP endpoint is accessible

## 3. PostgreSQL Database Setup

- [x] 3.1 Add Postgrex and Ecto SQL dependencies to `mix.exs`
- [x] 3.2 Configure Ecto repository in application
- [x] 3.3 Set up database configuration in `config/` files
- [x] 3.4 Configure environment variable support for database connection
- [x] 3.5 Test database creation with `mix ecto.create`

## 4. Docker Compose Configuration

- [x] 4.1 Create `docker-compose.yml` with PostgreSQL service
- [x] 4.2 Configure PostgreSQL 18 with named volume for data persistence
- [x] 4.3 Add Phoenix application service (optional)
- [x] 4.4 Configure service dependencies and health checks
- [x] 4.5 Test `docker-compose up db` starts PostgreSQL successfully

## 5. opencode Configuration

- [x] 5.1 Create `.opencode/config.json` with Tidewave MCP server configuration
- [x] 5.2 Configure Tidewave endpoint URL
- [x] 5.3 Verify opencode can connect to Tidewave instance

## 6. Integration Testing

- [x] 6.1 Test full development workflow with Docker PostgreSQL
- [x] 6.2 Verify Tidewave integration works with opencode
- [x] 6.3 Confirm all services start correctly together