# pipeline Delta

## ADDED Requirements

### Requirement: Kanban access for advanced operations
The system SHALL keep the per-job Kanban board accessible from the job detail page as a secondary entry point for advanced operations such as drag-and-drop moves, bulk actions, scheduling, and scorecards.

#### Scenario: Open Kanban from job page
- **WHEN** a user clicks the pipeline entry on a job detail page
- **THEN** the Kanban board for that job is shown

#### Scenario: Secondary entry styling
- **WHEN** a user views a job detail page
- **THEN** the Kanban entry is styled as a secondary action, distinct from primary page actions