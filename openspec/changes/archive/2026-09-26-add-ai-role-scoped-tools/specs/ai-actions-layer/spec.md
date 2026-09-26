# AI Actions Layer

## MODIFIED Requirements

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

## ADDED Requirements

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
