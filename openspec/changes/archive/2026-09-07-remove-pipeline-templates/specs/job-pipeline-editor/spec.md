# job-pipeline-editor (delta)

## Modified Requirements

### Requirement: Job pipeline stays dedicated to the job
No behavior change; only the origin story changes since templates no longer exist.

#### Scenario: Job with an already-dedicated pipeline
- **WHEN** a job's pipeline is already dedicated to that job (e.g. previously duplicated or detached)
- **THEN** editing stages from the job page modifies that pipeline directly without cloning again
