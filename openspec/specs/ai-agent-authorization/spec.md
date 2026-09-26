# AI Agent Authorization

## Purpose

Permission-scoped authorization for AI agent tools based on the workspace membership effective set, covering tool hiding and enforcement at run and confirm time.

## Requirements

### Requirement: Membership permissions are the single source of truth

The agent SHALL authorize the connected user using the effective permission set resolved from the active workspace membership (preset role plus workspace overrides). It SHALL build an actor carrying the membership id, role, and effective permissions and pass that actor to every context call. It SHALL NOT authorize on raw role strings or on `User.role`.

#### Scenario: Admin membership grants all tools
- **WHEN** the connected user has `Membership.role == "admin"` in the current workspace
- **THEN** all tools are exposed and may execute

#### Scenario: Recruiter membership exposes only allowed tools
- **WHEN** the connected user is a recruiter whose effective set denies `candidates_delete`
- **THEN** delete/merge/bulk-delete tools are hidden and any attempt to run one returns `{:error, :unauthorized}`

#### Scenario: Interviewer membership exposes scoped tools only
- **WHEN** the connected user is an interviewer
- **THEN** only viewing, interview listing, scorecard submission, and availability tools are exposed

#### Scenario: Context receives the permissioned actor
- **WHEN** a tool calls a context that checks permissions
- **THEN** the actor passed carries the effective permission set, so the check matches what the UI enforces

### Requirement: Per-tool action declaration

Every AI tool SHALL resolve to exactly one required action key, either via its own `required_action/0` callback or via the central registry map. Unmapped tools SHALL fail closed (denied) until mapped.

#### Scenario: Tool declares action
- **WHEN** a tool is checked
- **THEN** it exposes its required action key

#### Scenario: Tool without a mapping denies
- **WHEN** a tool resolves to no known action
- **THEN** the registry treats it as denied for non-admins and flags it in tests

### Requirement: Permission-scoped tool exposure

Before handing tools to the model, the agent SHALL filter the profile toolset by the actor effective permissions, so a user never sees a tool whose required action is denied. Denied tools SHALL be hidden from the model, not merely blocked at execution.

#### Scenario: Denied turn hides tools
- **WHEN** a recruiter without `webhooks_manage` sends a message
- **THEN** the tool list given to the model contains no webhook-manage tools

#### Scenario: Allowed turn exposes tools
- **WHEN** a recruiter with explicitly allowed `pipeline_manage` sends a message in a domain that has pipeline tools
- **THEN** those pipeline tools are present in the tool list given to the model

#### Scenario: Override change hides on next turn
- **WHEN** an admin revokes an action and the affected user sends a new message
- **THEN** the rebuilt context carries the new effective set and the tool list excludes the revoked tools

### Requirement: Enforcement at run and confirm time

The agent SHALL re-check the tool's required action against current effective permissions before executing it, both for immediate reads and for confirmed destructive runs. The check SHALL NOT rely on tool filtering alone.

#### Scenario: Read denied by permission
- **WHEN** a tool whose required action is denied is invoked
- **THEN** `run/2` is not executed and the tool result is `{:error, :unauthorized}`

#### Scenario: Confirmation carries current permissions
- **WHEN** the user confirms a pending destructive run
- **THEN** the confirmation context rebuilds effective permissions and the same action check is applied before execution

#### Scenario: User cannot escalate via confirmation
- **WHEN** a user has a pending run for an action that is now denied (e.g. revoked after proposal) and confirms it
- **THEN** execution is refused with `{:error, :unauthorized}` and no mutation occurs

### Requirement: Candidate portal has no assistant

The assistant and its tools SHALL NOT be available to candidate-portal sessions.

#### Scenario: Portal has no widget
- **WHEN** a candidate is authenticated in the candidate portal
- **THEN** no assistant widget is rendered and no tool can be invoked
