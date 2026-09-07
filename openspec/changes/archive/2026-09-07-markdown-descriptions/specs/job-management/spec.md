# job-management (delta)

## Modified Requirements

### Requirement: Job description authoring
The job description is authored as plain Markdown in a regular textarea with
a short hint that Markdown is supported. No toolbar or preview is offered.

#### Scenario: Author job in Markdown
- **WHEN** an admin writes `**bold**` or a `- list` in the job description
- **THEN** the text is stored as-is and rendered as HTML wherever displayed
