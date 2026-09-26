# AI Agent Authorization

## Purpose

Role-scoped authorization for AI agent tools based on the workspace membership role, covering tool exposure and enforcement at run and confirm time.

## Requirements

### Requirement: Membership role is the single source of truth

The agent SHALL authorize the connected user using the active workspace membership role
(`Membership.role`). It SHALL build a role-scoped actor `ctx.actor = %{id, role}` and pass
that actor to every context call. It SHALL NOT authorize on `User.role`.

#### Scenario: Admin membership grants admin tools
- **WHEN** the connected user has `Membership.role == "admin"` in the current workspace
- **THEN** admin-only tools are exposed and may execute

#### Scenario: Member membership denies admin tools
- **WHEN** the connected user has `Membership.role != "admin"` in the current workspace
- **THEN** admin-only tools are not exposed and any attempt to run one returns `{:error, :unauthorized}`

#### Scenario: Context receives the membership actor
- **WHEN** a tool calls a context that checks `actor.role`
- **THEN** the actor passed is the membership actor, so the check matches what the UI enforces

### Requirement: Per-tool role declaration

Every AI tool SHALL declare its required role, either `:any` or `:admin`. Tools that do not
declare one SHALL default to `:any`.

#### Scenario: Tool declares admin
- **WHEN** a tool is admin-only
- **THEN** it exports `required_role/0` returning `:admin`

#### Scenario: Tool without a declaration
- **WHEN** a tool exports no `required_role/0`
- **THEN** the registry treats it as `:any`

### Requirement: Role-scoped tool exposure

Before handing tools to the model, the agent SHALL filter the profile toolset by the actor
role, so a member never sees an admin-only tool.

#### Scenario: Member turn hides admin tools
- **WHEN** a member sends a message
- **THEN** the tool list given to the model contains no tool whose `required_role/0` is `:admin`

#### Scenario: Admin turn exposes admin tools
- **WHEN** an admin sends a message in a domain that has admin tools
- **THEN** those admin tools are present in the tool list given to the model

### Requirement: Enforcement at run and confirm time

The agent SHALL re-check the tool's required role before executing it, both for immediate
reads and for confirmed destructive runs. The check SHALL NOT rely on tool filtering alone.

#### Scenario: Read denied by role
- **WHEN** a tool whose `required_role/0` is `:admin` is invoked with a member context
- **THEN** `run/2` is not executed and the tool result is `{:error, :unauthorized}`

#### Scenario: Confirmation carries the role
- **WHEN** the user confirms a pending destructive run
- **THEN** the confirmation context includes the actor role and the same role check is applied before execution

#### Scenario: Member cannot escalate via confirmation
- **WHEN** a member somehow has a pending admin-only run (for example, from an older conversation) and confirms it
- **THEN** execution is refused with `{:error, :unauthorized}` and no mutation occurs

### Requirement: Candidate portal has no assistant

The assistant and its tools SHALL NOT be available to candidate-portal sessions.

#### Scenario: Portal has no widget
- **WHEN** a candidate is authenticated in the candidate portal
- **THEN** no assistant widget is rendered and no tool can be invoked
