# AI Response Control

Outbound safety controller for the Treby AI assistant. After the agent produces its final answer, the controller reviews the reply — blocking inappropriate content, normalizing formatting, and performing a best-effort check for data-exfiltration or security issues — before the message is persisted and broadcast.

## ADDED Requirements

### Requirement: Outbound controller reviews final reply
After the agent produces a `:final_answer`, the system SHALL pass the reply (and the request context) to an outbound controller before persisting and broadcasting it. The controller SHALL decide whether to pass, block, or sanitize the reply and MAY normalize formatting.

#### Scenario: In-scope reply passes
- **WHEN** the agent's final answer is appropriate and in-domain
- **THEN** the controller returns a `pass` verdict and the reply is persisted and broadcast

#### Scenario: Controller runs once per final answer
- **WHEN** the agent loop reaches a final answer
- **THEN** the controller is invoked exactly once, not on intermediate tool-loop steps

### Requirement: Controller blocks inappropriate replies
The controller SHALL block replies that are still inappropriate, off-topic, or unsafe by replacing them with a canned refusal and SHALL log the reason.

#### Scenario: Inappropriate reply blocked
- **WHEN** the controller verdict is `block`
- **THEN** the persisted/broadcast message is the canned refusal and the original reason is logged

### Requirement: Controller normalizes formatting
The controller SHALL fix and normalize markdown formatting of the reply without changing its factual meaning.

#### Scenario: Formatting fixed
- **WHEN** the agent's reply has inconsistent or broken markdown
- **THEN** the controller returns a `reply` with normalized formatting and the same content

### Requirement: Controller flags data exfiltration and security issues
The controller SHALL perform a best-effort check for data-exfiltration or security concerns (for example, another tenant's data, secrets, or out-of-scope PII) and SHALL sanitize or block such replies, logging the concern.

#### Scenario: Exfiltration attempt sanitized
- **WHEN** the controller detects another tenant's data or secrets in the reply
- **THEN** it returns a `sanitize` verdict with the sensitive content stripped and logs the concern

#### Scenario: Controller failure is safe
- **WHEN** the controller errors or returns unparseable output
- **THEN** the original reply is persisted and broadcast and the error is logged (the tenant-scoped queries and inbound guard remain the primary protection)
