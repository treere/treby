## ADDED Requirements

### Requirement: Request-attributed audit events
The system SHALL populate `ip` and `user_agent` on audit events triggered from web requests (controllers and LiveViews), so the admin audit view attributes actions to their origin. Events from background jobs without request context SHALL remain valid with null `ip`/`user_agent`.

#### Scenario: Staff login records request origin
- **WHEN** a user logs in via `POST /login`
- **THEN** the `auth.login` audit event includes the request IP and user-agent header

#### Scenario: Candidate stage move records request origin
- **WHEN** a user moves an application from the pipeline board
- **THEN** the `application.stage_moved` audit event includes the request IP and user-agent when available
