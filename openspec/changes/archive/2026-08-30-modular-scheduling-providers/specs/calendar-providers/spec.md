# Calendar Providers

## Purpose

Provider abstraction for calendar integrations: multiple active providers per user, with Treby's internal calendar always active.

## Requirements

### Requirement: Calendar provider abstraction
The system SHALL expose a `CalendarProvider` behaviour that any calendar integration implements, with operations to fetch busy periods and to create and delete events. Providers SHALL be referenced by a stable provider name (e.g. `"google"`).

#### Scenario: Implement a provider
- **WHEN** a new calendar integration is added
- **THEN** it implements `fetch_busy/3`, `create_event/3`, and `delete_event/2` against the `CalendarProvider` behaviour
- **AND** it is registered under a stable provider name

### Requirement: Multiple connected providers per user
The system SHALL allow a user to connect more than one calendar provider in parallel. Connections SHALL be unique per `(tenant_id, user_id, provider)`.

#### Scenario: Connect two providers
- **WHEN** a user already has a Google Calendar connection and connects a second provider (e.g. Outlook)
- **THEN** the system stores both connections
- **AND** each connection is associated with its own provider

#### Scenario: Reconnect the same provider
- **WHEN** a user connects a provider they are already connected to
- **THEN** the existing connection for that provider is updated instead of creating a duplicate

### Requirement: Internal calendar always active
The system SHALL treat Treby's own calendar as a calendar provider that is always part of availability computation, even when no external calendar is connected. Its busy periods SHALL come from the user's already-scheduled `interview_events` (status `"scheduled"`).

#### Scenario: Busy from existing interviews
- **WHEN** a user already has a scheduled interview at 10:00-10:30 and availability is computed for that period
- **THEN** the 10:00-10:30 period is reported as busy by the internal calendar provider

#### Scenario: No external calendar connected
- **WHEN** a user has no external calendar connection and availability is computed
- **THEN** the internal calendar provider still contributes busy periods
- **AND** no error is raised for the missing external provider

### Requirement: Aggregate busy across all connected providers
The system SHALL compute slot availability by intersecting availability rules with the union of busy periods from the internal calendar provider and every connected external provider. A user with no external connections SHALL still get slots from the internal calendar alone.

#### Scenario: Slots consider all connected providers
- **WHEN** a user is connected to Google and has an availability rule of 09:00-17:00
- **AND** the internal calendar reports 10:00-10:30 busy and Google reports 14:00-15:00 busy
- **THEN** the returned slots exclude both busy periods (and their buffer zones)

#### Scenario: Internal-only availability
- **WHEN** a user has no external calendar connected but has availability rules
- **THEN** the returned slots exclude only the internal calendar's busy periods

### Requirement: Fail closed on provider errors
The system SHALL block slot computation when a connected external provider returns an error, rather than silently computing availability without that provider. The behavior SHALL be consistent across single- and multi-examiner slot computation.

#### Scenario: External provider errors
- **WHEN** a connected provider returns an error during busy aggregation
- **THEN** the slot computation returns an error
- **AND** the scheduling page does not show slots
- **AND** the error identifies the failing provider

#### Scenario: Provider not connected is not an error
- **WHEN** a user has no connection for a given provider
- **THEN** that provider contributes no busy periods and does not cause an error

### Requirement: Distributed provider response cache
The system SHALL cache external provider busy responses in a cache distributed across cluster nodes, keyed by `(provider, user_id, from, to)`, with a short TTL. Internal calendar busy SHALL always be read fresh from the database and SHALL never be served from the cache.

#### Scenario: Cache external response across nodes
- **WHEN** an external provider busy response is fetched on one node and requested again on another node within the TTL
- **THEN** the cached response is returned without calling the provider again

#### Scenario: Cache loss is safe
- **WHEN** the cache is lost or unavailable
- **THEN** external busy responses are fetched directly from the provider
- **AND** slot availability remains correct (internal busy is always fresh)