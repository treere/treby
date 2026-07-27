## MODIFIED Requirements

### Requirement: Weekly stats
The system SHALL show summary statistics for the current week.

#### Scenario: This week's activity
- **WHEN** a user visits the dashboard
- **THEN** the following stats are shown for the current calendar week: applications received, interviews completed, offers sent, hires made

#### Scenario: New user with no activity
- **WHEN** a user with no activity this week visits the dashboard
- **THEN** stat cards display `0` values with clear labels indicating the time period ("This Week")
- **AND** the stat cards are visually present but not the focal point (the onboarding checklist and welcome message take priority above them)
