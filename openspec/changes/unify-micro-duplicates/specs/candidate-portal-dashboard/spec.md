## ADDED Requirements

### Requirement: Shared portal messages preload
The system SHALL provide one shared messages preload helper in the `CandidatePortal` context, and all 4 existing preload sites SHALL use it with identical assoc shape and no behavior change.

#### Scenario: All preload sites use shared helper
- **WHEN** any of the 4 portal preload sites loads messages
- **THEN** it calls the shared helper and preloads the same assocs as before

#### Scenario: Preload shape unchanged
- **WHEN** portal messages are listed via any of the 4 sites
- **THEN** returned messages carry the same preloaded assocs and ordering as before the refactor

### Requirement: Shared portal mount guard helper
The system SHALL provide portal-scoped `mount_portal/2` (tenant slug lookup plus not-found/unauthorized guard), and all 6 portal mount callbacks SHALL route through it with identical guard branches. Page titles stay inline (all 7 title strings distinct — a helper would dedup nothing).

#### Scenario: Guard branches preserved
- **WHEN** a portal view mounts with an unknown slug or unauthorized candidate session
- **THEN** the system takes the same not-found or unauthorized branch as before

#### Scenario: Title copy unchanged
- **WHEN** any portal view assigns its page title
- **THEN** the assigned title string matches the pre-refactor copy for that view
