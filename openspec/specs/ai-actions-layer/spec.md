# AI Actions Layer

## Purpose

Provide thin AI-only tool modules delegating to the existing contexts, with hand-written schemas and tenant-first signatures. No behaviour, no registry, no LiveView refactor.

## Requirements

### Requirement: Thin AI-only tool modules

The system SHALL expose AI capabilities as plain modules under `Treby.AI.Tools.*`, each with `schema/0`, `destructive?/0`, and `run/2` delegating to the existing contexts. LiveView handlers SHALL keep calling contexts directly and SHALL NOT be refactored.

#### Scenario: Tool delegates to existing context
- **WHEN** the agent executes `list_jobs`
- **THEN** the tool module calls the existing jobs context with `tenant_id` from `ctx`

#### Scenario: LiveView untouched
- **WHEN** a user triggers a LiveView event that mutates state
- **THEN** the handler keeps its current context call; no `Actions.run` indirection

#### Scenario: Tenant-first signature
- **WHEN** any tool is invoked
- **THEN** `tenant_id` is the first required argument and is taken from `ctx.tenant_id`, never from LLM output

### Requirement: Hand-written schemas

Each tool SHALL define its ReqLLM-compatible schema as a plain map. No markers, no Beam introspection, no registry, no CI check. A unit test per tool SHALL assert the schema shape and tenant-first validation.

#### Scenario: Schema tested
- **WHEN** the test suite runs
- **THEN** each of the 6 tools has a test asserting required keys and arg order

### Requirement: App-level tenant scoping (no composite FKs)

The system SHALL enforce tenant isolation at the application layer via `ctx.tenant_id` taken from socket, never from LLM output. Every tool query SHALL scope by `tenant_id`. New AI tables SHALL carry `tenant_id` with standard FKs. No composite-FK hardening migration SHALL be part of this change.

#### Scenario: Cross-tenant access blocked by app
- **WHEN** a tool is called with an id belonging to another tenant
- **THEN** the scoped query returns nothing or validation fails and no mutation occurs

#### Scenario: AI tables tenant-scoped
- **WHEN** `ai_conversations`, `ai_messages`, `ai_tool_runs` are created
- **THEN** they include `tenant_id` and standard FKs to parent rows

### Requirement: MCP/API readiness

The tool modules SHALL keep a stable `run/2` + `schema/0` contract so a future MCP server, Action Layer, or auto-registry can wrap them without changing call sites.

#### Scenario: Future wrapper compatible
- **WHEN** a future Action Layer or MCP server is added
- **THEN** it can delegate to `Treby.AI.Tools.*` without duplicating tenant checks
