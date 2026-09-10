## MODIFIED Requirements

### Requirement: Create job posting
The system SHALL allow authenticated users to create job postings via a dedicated creation page (`/app/jobs/new` and `/:tenant_slug/app/jobs/new`) with a live public preview and explicit publication controls. The system SHALL associate the job with the user's tenant and handle empty pipeline selection gracefully. The job listing page SHALL NOT host an inline creation form; its "New Job" action SHALL navigate to the creation page.

#### Scenario: Successful job creation via dedicated page
- **WHEN** a user navigates to the creation page, fills title, description, and optional fields (salary range, location, employment/workplace types, pipeline, custom fields), sets status and visibility, and submits
- **THEN** a new job is created with the chosen `status` (`open`/`closed`) and `visible` (`true`/`false`) and associated with the user's tenant
- **AND** the user is redirected to the job detail page with a success flash

#### Scenario: Job creation with default pipeline
- **WHEN** a user opens the creation page
- **THEN** the pipeline selector shows only existing pipelines with the tenant's default pipeline preselected
- **AND** when the job is created without changing the selection, the job is created with that default pipeline's id

#### Scenario: Missing required fields on creation page
- **WHEN** a user submits a job without title or description on the creation page
- **THEN** the system returns inline validation errors and no job is created

#### Scenario: Creation page shows live public preview
- **WHEN** a user edits fields on the creation page
- **THEN** the preview pane updates to show the job as it will appear publicly (Markdown-rendered description, location, employment/workplace badges, salary, company context) without persisting

#### Scenario: Publication defaults on creation
- **WHEN** a user opens the creation page
- **THEN** status defaults to `open` and visibility defaults to `public`
- **AND** toggling status to `closed` disables the visibility control with hint "Closed jobs are private and hidden from public boards." and the server treats `visible` as `false` regardless of the submitted value

#### Scenario: Public closed job is coerced to private
- **WHEN** a user submits a job with `visible=true` and `status=closed` (bypassing the disabled control)
- **THEN** the server coerces `visible` to `false` and creates the job as `closed`/`private`; direct context calls with `visible=true` + `closed` without coercion fail validation with "cannot be visible when the job is closed"

#### Scenario: New Job navigates from listing
- **WHEN** a user clicks "New Job" on the job listing
- **THEN** the system navigates to the dedicated creation page

