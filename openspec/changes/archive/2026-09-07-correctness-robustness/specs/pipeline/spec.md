## ADDED Requirements

### Requirement: Observable stage-change notification failures
When the post-move notification email fails, the system SHALL log a warning with the application id and error AND emit a `:telemetry` event; the stage move itself SHALL still succeed (notifications never block moves).

#### Scenario: Notification mail fails
- **WHEN** a stage move succeeds but the notification email raises or throws
- **THEN** the move returns success
- **AND** a warning is logged identifying the application and the error
- **AND** a `[:treby, :pipeline, :notify_failed]` telemetry event is emitted

### Requirement: Race-safe pipeline detach
Detaching a job from a shared pipeline (check sharing, clone, remap applications, repoint job) SHALL execute atomically so a concurrent attach cannot interleave between the share check and the clone; the shared pipeline SHALL never be mutated by a detach.

#### Scenario: Concurrent attach during detach
- **WHEN** another job attaches to the pipeline while a detach is in progress
- **THEN** the detaching job still gets its own cloned pipeline with remapped applications
- **AND** the shared pipeline remains unmodified
