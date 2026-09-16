## MODIFIED Requirements

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

## ADDED Requirements

### Requirement: Inbound guard refuses off-topic and malicious prompts
The system SHALL classify every inbound message into one of `recruiter`, `analytics`, `comms`, `admin`, `:out_of_domain`, or `:malicious`. Requests classified as `:out_of_domain` or `:malicious` SHALL be refused before the agent loop runs. The refusal MUST NOT invoke any tool or stream a model answer.

#### Scenario: Off-topic example refused
- **WHEN** a user asks for an unrelated topic (for example, a recipe)
- **THEN** the chat replies with a polite message that it only helps with the hiring workspace, and no tool runs

#### Scenario: Malicious prompt refused
- **WHEN** a user attempts prompt injection, asks to ignore instructions, or tries to access another tenant's data
- **THEN** the chat refuses, logs a warning, and no agent loop or tool runs

#### Scenario: Ambiguous input keeps sticky domain
- **WHEN** the classifier returns an unrecognized value or errors
- **THEN** the system keeps the previously selected domain rather than refusing

### Requirement: Agent pipeline debug logging
The agent loop SHALL emit structured `Logger.debug` trace lines (selected domain, profile, iteration count, tool calls, token count, and outbound-control verdict) when debug logging is enabled via `Application.get_env(:treby, :ai)[:debug_logging]`. Debug logging SHALL be disabled by default so production is silent.

#### Scenario: Debug logging enabled
- **WHEN** `:treby, :ai` `debug_logging` is truthy and a turn completes
- **THEN** structured debug lines are emitted covering classification, loop iterations, and the control verdict

#### Scenario: Debug logging disabled by default
- **WHEN** `debug_logging` is not set
- **THEN** no debug trace lines are emitted during a turn
