# AI Actions Layer

## Purpose

Provide thin AI-only tool modules delegating to the existing contexts, with hand-written schemas and tenant-first signatures. No behaviour, no registry, no LiveView refactor.

## Requirements

### Requirement: Thin AI-only tool modules

The system SHALL expose AI capabilities as plain modules under `Treby.AI.Tools.*`, each with
`schema/0`, `destructive?/0`, and `run/2` delegating to the existing contexts. A tool that is
admin-only SHALL additionally export `required_role/0` returning `:admin`; tools without the
declaration SHALL be treated as `:any`. Every invocation SHALL go through `Treby.AI.Tools.run/3`,
which authorizes by role and validates the arguments against the tool's schema before delegating.
`run/2` SHALL pass `ctx.actor` (the membership actor) to the context it calls. LiveView
handlers SHALL keep calling contexts directly and SHALL NOT be refactored.

#### Scenario: Tool delegates to existing context
- **WHEN** the agent executes `list_jobs`
- **THEN** the tool module calls the existing jobs context with `tenant_id` from `ctx`

#### Scenario: Write tool passes the actor
- **WHEN** a write tool calls a context that accepts an actor
- **THEN** it passes `ctx.actor` so the context's role check applies

#### Scenario: Role and input enforced for every invocation
- **WHEN** the agent executes or confirms any tool
- **THEN** `Tools.run/3` rejects admin tools for members and rejects malformed arguments before the tool body runs

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

### Requirement: Read tools verify parent ownership

A read tool that takes an entity id it does not itself scope SHALL first load the parent
scoped by `ctx.tenant_id` and refuse when the id belongs to another workspace, so tenant
isolation holds for ids passed by the model.

#### Scenario: Cross-workspace note id refused
- **WHEN** `list_notes` is called with an application id from another workspace
- **THEN** it returns `{:error, "application not found"}` and lists nothing

#### Scenario: Cross-workspace interview/scorecard id refused
- **WHEN** `list_interviews`, `list_scorecards` or `list_applications` receives an id from another workspace
- **THEN** the tool refuses instead of returning the other workspace's data
