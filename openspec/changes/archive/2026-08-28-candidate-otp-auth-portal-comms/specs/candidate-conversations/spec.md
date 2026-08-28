## ADDED Requirements

### Requirement: Recruiter sends templated message
The system SHALL allow recruiters to send a message composed from a stage message template into a conversation.

#### Scenario: Send from template
- **WHEN** a recruiter sends a message using a stage message template
- **THEN** the system renders the template variables with the candidate, job, and tenant values
- **AND** creates a message in the conversation with the rendered body
- **AND** updates the conversation's `last_message_at` and status

#### Scenario: Template with no conversation
- **WHEN** a recruiter sends a templated message and no conversation exists for the candidate's application
- **THEN** the system creates a conversation for that application before posting the message

### Requirement: Scheduled message posting
The system SHALL post scheduled messages to conversations at the scheduled time.

#### Scenario: Scheduled message posted
- **WHEN** the `SendScheduledMessage` worker delivers a scheduled message at its scheduled time
- **THEN** the system creates a message in the target conversation with the stored sender, body, and type
- **AND** updates the conversation's `last_message_at` and status

#### Scenario: Conversation closed before posting
- **WHEN** a scheduled message targets a conversation that has been closed before delivery
- **THEN** the system posts the message and reopens the conversation (status "open")