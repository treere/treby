## ADDED Requirements

### Requirement: Realtime conversation updates
The system SHALL deliver new messages and conversation state changes to all open conversation views in realtime via PubSub, without requiring a page reload.

#### Scenario: Candidate portal thread updates in realtime
- **WHEN** a recruiter (or the system) sends a message in a conversation while the candidate has the conversation thread open in the portal
- **THEN** the new message appears in the thread automatically, without reloading the page

#### Scenario: Admin candidate view updates in realtime
- **WHEN** a candidate sends a message while a recruiter has the candidate's profile open with the conversations view expanded
- **THEN** the new message appears in the conversation automatically, without reloading the page

#### Scenario: Portal inbox refreshes
- **WHEN** a new message arrives in a conversation while the candidate is viewing the portal messages list
- **THEN** the conversation's last-message preview and ordering update automatically, without reloading the page

#### Scenario: New conversation appears in inbox
- **WHEN** a recruiter creates a new conversation while the candidate is viewing the portal messages list or dashboard
- **THEN** the new conversation appears in the list automatically, without reloading the page

#### Scenario: Closed conversation updates
- **WHEN** a recruiter closes a conversation while the candidate has its thread open in the portal
- **THEN** the thread reflects the closed status automatically, without reloading the page

#### Scenario: All message sources are realtime
- **WHEN** a message is created by any source (manual send, stage template, scheduled message, bulk send, interview notification, rejection, info request, or system status update)
- **THEN** open conversation views update automatically, since all sources share the same broadcast path