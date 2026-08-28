## REMOVED Requirements

### Requirement: Receive candidate replies
**Reason**: Inbound email webhook and thread matching removed; all candidate communication happens in portal conversations.
**Migration**: Candidates reply inside the portal; the webhook route `/webhooks/inbound` and `EmailWebhookController` are removed.

### Requirement: Email messages have a status
**Reason**: Email threads removed; scheduled messages in the portal carry their own status (see `email-scheduler`).
**Migration**: No equivalent — portal messages are sent or scheduled via `scheduled_messages`.

### Requirement: Display email threads
**Reason**: The email threads UI (thread list, thread detail, tabs on candidate profile) is removed.
**Migration**: Portal conversations (`candidate-conversations`) are the single communication history shown on the candidate profile.

### Requirement: Reply to email
**Reason**: Replying by email is removed; recruiters reply inside portal conversations.
**Migration**: Use the portal conversation reply flow.

### Requirement: Compose new email thread
**Reason**: Composing emails to candidates is removed; recruiters send portal messages.
**Migration**: Use the portal conversation compose flow.

### Requirement: Reply with schedule option
**Reason**: Scheduling email replies is removed; scheduling applies to portal messages (`email-scheduler`).
**Migration**: Schedule a portal message instead.

### Requirement: Compose email with schedule option
**Reason**: Scheduling email compose is removed; scheduling applies to portal messages (`email-scheduler`).
**Migration**: Schedule a portal message instead.

### Requirement: Email thread metadata
**Reason**: Email message metadata fields no longer exist; the email tables are dropped.
**Migration**: Portal messages store the existing message schema; scheduled delivery uses `scheduled_messages`.

### Requirement: Email delivery for outbound
**Reason**: Outbound email delivery with threading headers removed.
**Migration**: No equivalent — delivery is via portal messages.