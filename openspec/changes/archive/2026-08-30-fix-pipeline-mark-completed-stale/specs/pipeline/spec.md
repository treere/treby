## MODIFIED Requirements

### Requirement: Real-time updates

The system SHALL broadcast pipeline changes to all connected clients, including when an interview is marked as completed, so cards update without manual reload.

#### Scenario: Multi-user real-time sync

- **WHEN** one user moves a candidate to a new stage
- **THEN** all other users viewing the same pipeline see the change immediately

#### Scenario: Interview completion broadcasts pipeline update

- **WHEN** `Treby.Interviews.complete_interview/2` marks an interview as completed
- **THEN** a `{:pipeline_updated, job_id}` broadcast is sent on `pipeline:#{job_id}` so all pipeline LiveViews re-stream

#### Scenario: Mark interview as completed updates card live

- **WHEN** a user confirms `Mark as completed` for an interview in the pipeline board
- **THEN** the candidate card no longer shows `Interview not yet completed`
- **AND** the card shows `Ready to advance` or `scorecard missing` according to remaining blockers without requiring `location.reload()`
