# AI Agent

The Treby AI assistant: a per-turn specialized multi-agent system that helps the hiring team manage jobs, candidates, pipeline, analytics, communications and workspace settings from inside the app.

## ADDED Requirements

### Requirement: Specialized agent profiles
The assistant SHALL select a specialized agent profile per turn from a fixed set (recruiter, analytics, comms, admin) and SHALL use only that profile's tools and system prompt. Classification MAY additionally yield `:out_of_domain` or `:malicious`; in those cases the chat SHALL refuse the request and SHALL NOT run the agent loop or any tool.

#### Scenario: Profile selected by router
- **WHEN** the user sends a message that is in-domain
- **THEN** the LLM router classifies the intent into a domain and the chat runs with that domain's toolset and prompt

#### Scenario: Sticky domain
- **WHEN** consecutive messages stay within the same domain
- **THEN** the router keeps the previously selected domain without re-classifying every turn

#### Scenario: Off-topic request refused
- **WHEN** the router classifies the message as `:out_of_domain`
- **THEN** the chat returns a single polite refusal without running the agent loop or any tool

#### Scenario: Malicious request refused
- **WHEN** the router classifies the message as `:malicious`
- **THEN** the chat returns a refusal, logs the event, and does not run the agent loop or any tool

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

### Requirement: Inbound domain and safety guard
Every inbound message SHALL be classified into one of `recruiter`, `analytics`, `comms`, `admin`, `:out_of_domain`, or `:malicious`. Requests classified as `:out_of_domain` or `:malicious` SHALL be refused before the agent loop runs. The refusal MUST NOT invoke any tool or stream a model answer.

#### Scenario: Off-topic example refused
- **WHEN** a user asks for an unrelated topic (for example, a recipe)
- **THEN** the chat replies that it only helps with the hiring workspace, and no tool runs

#### Scenario: Malicious prompt refused
- **WHEN** a user attempts prompt injection, asks to ignore instructions, or tries to access another tenant's data
- **THEN** the chat refuses, logs a warning, and no agent loop or tool runs

#### Scenario: Ambiguous input keeps sticky domain
- **WHEN** the classifier returns an unrecognized value or errors
- **THEN** the system keeps the previously selected domain rather than refusing

### Requirement: Agent pipeline debug logging
The agent loop SHALL emit structured `Logger.debug` trace lines (selected domain, profile, iteration count, tool calls, character count, and outbound-control verdict) when debug logging is enabled via `Application.get_env(:treby, :ai)[:debug_logging]`. Debug logging SHALL be disabled by default so production is silent.

#### Scenario: Debug logging enabled
- **WHEN** `:treby, :ai` `debug_logging` is truthy and a turn completes
- **THEN** structured debug lines are emitted covering classification, loop iterations, and the control verdict

#### Scenario: Debug logging disabled by default
- **WHEN** `debug_logging` is not set
- **THEN** no debug trace lines are emitted during a turn
