# AI Actions Layer

## Purpose

Provide a unified, tenant-first action boundary used by LiveView, AI agent, and future external APIs/MCP, with auto-discovered capabilities.

## ADDED Requirements

### Requirement: Unified Action Layer

The system SHALL expose domain mutations through a unified Action Layer (`Treby.Actions` behaviour). LiveView handlers, AI tools, and future APIs/MCP SHALL delegate to this layer rather than calling contexts directly.

#### Scenario: LiveView delegates to actions
- **WHEN** a user triggers a LiveView event that mutates state
- **THEN** the handler calls `Treby.Actions.run(action, args, ctx)` with `ctx.tenant_id` from socket

#### Scenario: Agent delegates to same actions
- **WHEN** the AI agent executes a tool
- **THEN** it calls the same `Treby.Actions` module with identical `ctx` shape

#### Scenario: Tenant-first signature
- **WHEN** any action is invoked
- **THEN** `tenant_id` is the first required argument and is taken from `ctx.tenant_id`, never from LLM output

### Requirement: Auto-discovered capabilities via hybrid Beam introspection

The system SHALL auto-discover AI tools from context functions annotated with `@ai_tool` as marker only. The registry SHALL derive JSON Schema via Beam introspection: `Code.fetch_docs/1` for description, `Code.Typespec.fetch_specs/1` for types, and changeset `cast` fields for required/optional. Unannotated functions SHALL NOT be exposed. Functions with `@ai_tool` but missing `@doc`/`@spec` or without `tenant_id` as first arg SHALL fail the registry check.

#### Scenario: Annotated function becomes tool via introspection
- **WHEN** a context function is annotated with `@ai_tool %{destructive: false}` and has `@doc` and `@spec`
- **THEN** the registry exposes it as a tool with schema derived from `Code.fetch_docs` and `fetch_specs` without hand-written schema

#### Scenario: Unannotated function not exposed
- **WHEN** a public function lacks `@ai_tool`
- **THEN** it is not available to the LLM

#### Scenario: Destructive flag respected
- **WHEN** an annotated function has `destructive: true` (default for writes)
- **THEN** the tool is marked destructive and requires confirmation

### Requirement: App-level tenant scoping (no composite FKs)

The system SHALL enforce tenant isolation at the application layer via `ctx.tenant_id` taken from socket, never from LLM output. Every action query SHALL scope by `tenant_id`. New AI tables SHALL carry `tenant_id` with standard FKs. No composite-FK hardening migration SHALL be part of this change.

#### Scenario: Cross-tenant access blocked by app
- **WHEN** an action is called with an id belonging to another tenant
- **THEN** the scoped query returns nothing or validation fails and no mutation occurs

#### Scenario: AI tables tenant-scoped
- **WHEN** `ai_conversations`, `ai_messages`, `ai_tool_runs` are created
- **THEN** they include `tenant_id` and standard FKs to parent rows

### Requirement: MCP/API readiness

The system SHALL define the Action Layer as a behaviour contract so a future MCP server or external API can invoke the same actions with the same `ctx` and validation.

#### Scenario: MCP can reuse actions
- **WHEN** a future MCP server is added
- **THEN** it can call `Treby.Actions` without duplicating tenant or permission checks
