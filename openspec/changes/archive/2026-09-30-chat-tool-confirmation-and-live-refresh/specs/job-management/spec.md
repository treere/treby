## ADDED Requirements

### Requirement: Job pages refresh live after chat mutations

Job list and job detail pages SHALL update live when a job is created, updated, or closed via the assistant chat, without requiring a manual page reload.

#### Scenario: New chat-created job appears in list

- **WHEN** a job is created via a confirmed chat action while the jobs list is displayed
- **THEN** the list shows the new job (respecting the current search/filter) without a manual reload

#### Scenario: Chat edit reflected on detail page

- **WHEN** a job is updated via a confirmed chat action while its detail page is displayed
- **THEN** the detail page shows the updated fields without a manual reload
