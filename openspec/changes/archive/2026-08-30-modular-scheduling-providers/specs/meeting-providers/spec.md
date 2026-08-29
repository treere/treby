# Meeting Providers

## Purpose

Meeting link generation for scheduled interviews, resolved automatically by provider connection: Google Meet when a Google-connected examiner is available, Jitsi otherwise.

## Requirements

### Requirement: Meeting provider abstraction
The system SHALL expose a `MeetingProvider` behaviour for generating video conference links. Each meeting provider SHALL be referenced by a stable name.

#### Scenario: Implement a meeting provider
- **WHEN** a new video conference integration is added
- **THEN** it implements the `MeetingProvider` behaviour
- **AND** it is registered under a stable provider name

### Requirement: Automatic meeting provider resolution
The system SHALL resolve the meeting provider at booking time based on calendar connections. If any examiner required for the interview is connected to Google Calendar, the system SHALL create a single Google Calendar event with a Google Meet link. Otherwise the system SHALL generate a Jitsi meeting link.

#### Scenario: Examiner connected to Google
- **WHEN** an interview is booked and at least one required examiner is connected to Google Calendar
- **THEN** the system creates a single Google Calendar event with a Google Meet conference link
- **AND** uses that link as the interview's meeting link

#### Scenario: No examiner connected to Google
- **WHEN** an interview is booked and no required examiner is connected to Google Calendar
- **THEN** the system generates a Jitsi meeting link
- **AND** does not create an external calendar event

### Requirement: Single Google event with all examiners
The system SHALL create a single Google Calendar event when Google is the resolved meeting provider. The event SHALL be created on the calendar of the first connected required examiner and SHALL include all examiners plus the candidate as attendees.

#### Scenario: Single event for all examiners
- **WHEN** a multi-examiner interview is booked with Google as the meeting provider
- **THEN** exactly one Google Calendar event is created
- **AND** all examiners' emails and the candidate's email are attendees
- **AND** the event is owned by the first connected required examiner

#### Scenario: No attendee emails are sent
- **WHEN** the Google Calendar event is created
- **THEN** the system does not send email invitations to attendees (event appears on their calendars without email spam)

### Requirement: Jitsi meeting link generation
The system SHALL generate Jitsi meeting links in the format `https://meet.jit.si/treby-<tenant-slug>-<uuid>` when Jitsi is the resolved meeting provider.

#### Scenario: Generate a Jitsi link
- **WHEN** the system resolves Jitsi as the meeting provider for an interview
- **THEN** the meeting link matches `https://meet.jit.si/treby-<tenant-slug>-<uuid>`
- **AND** the `<uuid>` is unique per interview

### Requirement: Single meeting link per interview
The system SHALL store exactly one meeting link per interview in `interview_events.video_conf_url`, regardless of which meeting provider was resolved.

#### Scenario: Meeting link stored
- **WHEN** an interview is booked
- **THEN** `video_conf_url` contains the resolved meeting link (Google Meet or Jitsi)
- **AND** the confirmation and notification flows use that single link