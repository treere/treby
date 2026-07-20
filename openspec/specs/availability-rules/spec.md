# Availability Rules

## Purpose

Allow users to configure their availability for interview scheduling.

## Requirements

### Requirement: Set availability rules per day
The system SHALL allow users to configure their available hours for each day of the week.

#### Scenario: Set working hours for a day
- **WHEN** a user sets their availability for Monday to 09:00-17:00
- **THEN** the system stores the rule with day_of_week, start_time, end_time, and the user's timezone

#### Scenario: Mark a day as unavailable
- **WHEN** a user does not set availability rules for a day (e.g. Saturday)
- **THEN** no slots are generated for that day

#### Scenario: Multiple time blocks per day (future)
- **WHEN** this feature is extended
- **THEN** the system SHALL support multiple non-overlapping time blocks per day
- **NOTE**: MVP supports one contiguous block per day

### Requirement: Configure timezone
The system SHALL allow users to set their timezone for availability calculations.

#### Scenario: Set timezone
- **WHEN** a user sets their timezone to "Europe/Rome"
- **THEN** all availability times are interpreted in that timezone
- **AND** slot generation converts local times to UTC for calendar integration

### Requirement: Set buffer times
The system SHALL allow users to configure buffer time before and after interviews.

#### Scenario: Default buffer
- **WHEN** a user has not configured custom buffer times
- **THEN** a 15-minute buffer is applied before and after each interview slot

#### Scenario: Custom buffer
- **WHEN** a user sets buffer_before to 30 minutes and buffer_after to 15 minutes
- **THEN** available slots exclude periods within 30 minutes before and 15 minutes after any existing commitment

### Requirement: Availability rules CRUD
The system SHALL allow viewing, creating, editing, and deleting availability rules.

#### Scenario: View weekly schedule
- **WHEN** a user navigates to the availability settings page
- **THEN** a weekly calendar view shows their configured hours for each day

#### Scenario: Update availability
- **WHEN** a user changes their Monday hours from 09:00-17:00 to 10:00-18:00
- **THEN** future slot computations reflect the updated hours
