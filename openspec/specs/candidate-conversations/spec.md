# Candidate Conversations

## Purpose

Enable in-platform messaging between recruiters and candidates within the candidate portal, providing a structured conversation system for lifecycle updates, information requests, and general communication.

## Requirements

### Requirement: Conversation creation
The system SHALL create conversations automatically at key lifecycle moments.

#### Scenario: Application submitted
- **WHEN** a candidate submits an application via the career page
- **THEN** the system creates a conversation with context "general", status "open", and a system message "Your application for {job_title} has been received"

#### Scenario: Pipeline stage change
- **WHEN** a candidate's application moves to a new pipeline stage
- **THEN** the system creates or updates a conversation with a system message "Your application for {job_title} has moved to {stage_name}"

#### Scenario: Recruiter sends first message
- **WHEN** a recruiter sends a message to a candidate and no conversation exists for that application
- **THEN** the system creates a new conversation with context "general" and the recruiter's message as the first message

### Requirement: Recruiter sends messages
The system SHALL allow recruiters to send messages to candidates within the candidate profile page.

#### Scenario: Send text message
- **WHEN** recruiter types a message and clicks "Send" in the conversation view
- **THEN** the system creates a message with sender_type "recruiter", the current user as sender_id, body text, message_type "text", and updates the conversation's `last_message_at`

#### Scenario: Send info request
- **WHEN** recruiter clicks "Request Info" and selects a template (portfolio, references, availability, certificates, custom)
- **THEN** the system creates a message with message_type "request_info", metadata containing the requested info type, and sets conversation status to "waiting_candidate"

#### Scenario: Initiate rejection
- **WHEN** recruiter clicks "Reject" and fills in the rejection form (reason dropdown + optional feedback)
- **THEN** the system creates a message with message_type "rejection", metadata containing the rejection reason and feedback, sets conversation context to "rejection", and moves the application to the Rejected stage

#### Scenario: Send structured messages
- **WHEN** recruiter sends a message via quick action buttons (message, request info, reject)
- **THEN** the system displays the appropriate form (text input, template selector, rejection form) and creates the correctly typed message

### Requirement: Candidate sends messages
The system SHALL allow candidates to reply to conversations in the portal.

#### Scenario: Candidate replies
- **WHEN** candidate types a message and clicks "Send" in the conversation view
- **THEN** the system creates a message with sender_type "candidate", body text, message_type "text", and updates the conversation's `last_message_at`

#### Scenario: Candidate responds to info request
- **WHEN** candidate views a conversation with an info_request message at the top
- **THEN** the system highlights the request and provides a reply form, and the candidate's response is sent as a regular text message

#### Scenario: Candidate responds to rejection
- **WHEN** candidate views a rejection conversation
- **THEN** the candidate can reply to ask for details or thank the recruiter, and the reply is sent as a regular text message

### Requirement: System messages
The system SHALL automatically generate system messages for lifecycle events.

#### Scenario: System message format
- **WHEN** a system event occurs (stage change, application created)
- **THEN** the system creates a message with sender_type "system", sender_id null, message_type "status_update", and a human-readable body describing the event

#### Scenario: System messages in timeline
- **WHEN** candidate or recruiter views a conversation
- **THEN** system messages are displayed inline with other messages, styled distinctly (e.g., centered, muted color, different background)

### Requirement: Conversation status management
The system SHALL track conversation status to indicate who should act next.

#### Scenario: Open status
- **WHEN** a conversation is created or a recruiter sends a message
- **THEN** the conversation status is "open" (recruiter action needed or general info)

#### Scenario: Waiting candidate status
- **WHEN** a recruiter sends an info request or asks a question requiring candidate response
- **THEN** the conversation status changes to "waiting_candidate"

#### Scenario: Closed status
- **WHEN** a recruiter closes a conversation or a rejection is sent
- **THEN** the conversation status changes to "closed"

### Requirement: Recruiter conversation view
The system SHALL display conversations in the candidate profile page under a dedicated tab.

#### Scenario: Conversations tab
- **WHEN** recruiter views a candidate profile
- **THEN** a "Conversations" tab is visible with a count badge showing the number of open conversations

#### Scenario: Conversation list
- **WHEN** recruiter clicks the Conversations tab
- **THEN** the system displays a list of all conversations for this candidate, each showing: job title, context badge, status, last message preview, and timestamp

#### Scenario: Expand conversation
- **WHEN** recruiter clicks on a conversation in the list
- **THEN** the system expands the conversation thread inline, showing all messages (recruiter, candidate, system) in chronological order, with a reply form at the bottom

#### Scenario: Quick actions
- **WHEN** recruiter views the conversations tab
- **THEN** the system displays quick action buttons: "New Message", "Request Info", "Reject" — each opens the appropriate form for the most recent application's conversation

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
