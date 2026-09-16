# AI Agent

The Treby AI assistant: a per-turn specialized multi-agent system that helps the hiring team manage jobs, candidates, pipeline, analytics, communications and workspace settings from inside the app.

## ADDED Requirements

### Requirement: Specialized agent profiles
The assistant SHALL select a specialized agent profile per turn from a fixed set (recruiter, analytics, comms, admin) and SHALL use only that profile's tools and system prompt.

#### Scenario: Profile selected by router
- **WHEN** the user sends a message
- **THEN** the LLM router classifies the intent into a domain and the chat runs with that domain's toolset and prompt

#### Scenario: Sticky domain
- **WHEN** consecutive messages stay within the same domain
- **THEN** the router keeps the previously selected domain without re-classifying every turn

### Requirement: Agent may signal domain exit
Any agent SHALL be able to indicate that the request is outside its domain.

#### Scenario: Handoff to another domain
- **WHEN** the active agent determines the request belongs to a different domain
- **THEN** it emits a handoff signal and the session re-routes the next turn to the correct profile

### Requirement: Extended tool coverage
The tool registry SHALL cover the whole system, not only job CRUD.

#### Scenario: Recruiter tools available
- **WHEN** the active profile is recruiter
- **THEN** tools include create/update/delete job, create/list/get candidate, create application, move application, add note, and search candidates

#### Scenario: Other domain tools available
- **WHEN** the active profile is analytics, comms, or admin
- **THEN** the respective domain tools are available (stats, compare, send message, templates, member management, pipeline config, csv import)

### Requirement: Page read/write interaction
The agent SHALL be able to read the current page state and SHALL be able to propose form values.

#### Scenario: Agent reads current page
- **WHEN** the user is on a page with relevant data
- **THEN** the page state is included in the agent context so the agent can answer using on-screen data

#### Scenario: Agent writes form
- **WHEN** the agent proposes form values
- **THEN** the values are sent to the LiveView which shows them as a confirmable diff (propose_form_fill)

### Requirement: Human confirmation on destructive tools
Destructive tools MUST NOT be executed by the agent directly.

#### Scenario: Destructive tool pending
- **WHEN** the agent calls a destructive tool
- **THEN** the run is stored as pending_confirm and executed only after explicit user confirmation in the UI

### Requirement: Per-user agent session
A lightweight session SHALL track the conversation and current domain per connected user.

#### Scenario: Conversation rebuilt on connect
- **WHEN** a user opens the chat
- **THEN** the session rebuilds the conversation from stored messages and the agent continues with prior history
