# job-creation-preview Specification

## Purpose
Dedicated job creation page with live public preview and explicit publication controls. Provides a separate route for creating offers, shows how candidates will see the job before publishing, and lets recruiters set whether the offer is active (open/closed) and where it appears (public/private) at creation time.
## Requirements
### Requirement: Dedicated job creation page
The system SHALL provide a dedicated page for creating job postings at `/app/jobs/new` and `/:tenant_slug/app/jobs/new`, separate from the job listing. The listing's "New Job" action SHALL navigate to this page and the listing SHALL NOT host an inline creation form.

#### Scenario: Navigate to creation page from listing
- **WHEN** an authenticated user clicks "New Job" on the job listing page
- **THEN** the system navigates to `/app/jobs/new` (or `/:tenant_slug/app/jobs/new` when slug-scoped) and shows the job creation form

#### Scenario: Direct access to creation page
- **WHEN** an authenticated user navigates directly to `/app/jobs/new`
- **THEN** the creation page loads with an empty form and live preview pane

#### Scenario: Cancel returns to listing
- **WHEN** a user clicks "Cancel" on the creation page
- **THEN** the system navigates back to the job listing without creating a job

#### Scenario: Listing has no inline form
- **WHEN** a user views the job listing at `/app/jobs`
- **THEN** no inline job creation form is rendered on that page

### Requirement: Live public preview on creation page
The system SHALL display a live preview pane on the job creation page that renders the job exactly as it will appear on the public career page detail (`/:tenant_slug/careers/:job_id` / card view). The preview SHALL update on every validated change without persisting the job and SHALL faithfully reuse public rendering (Markdown, badges, conditional visibility of empty fields).

#### Scenario: Preview updates on title and description change
- **WHEN** a user types a title or Markdown description in the form
- **THEN** the preview pane updates to show the title and Markdown-rendered description

#### Scenario: Preview shows structured metadata
- **WHEN** a user fills salary range, location, employment type, or workplace type
- **THEN** the preview shows those values with the same icons/badges as the public page, and hides any field that is empty

#### Scenario: Preview reflects publication state
- **WHEN** a user toggles status to Closed
- **THEN** the preview indicates the position is closed / not publicly visible (e.g., muted banner or disabled apply CTA), consistent with the public closed-job behavior

#### Scenario: Preview visible in both themes
- **WHEN** the creation page is viewed in light and dark themes
- **THEN** the preview card remains legible with no contrast violations (uses `dark:` overrides and theme-aware tokens)

### Requirement: Publication controls at creation
The system SHALL allow the user to set publication state at creation time via two controls: `Status` (Open / Closed) and `Visibility` (Public / Private). Defaults SHALL be `Open` and `Public`. The system SHALL enforce that a closed job cannot be public and SHALL disable/hint the visibility control when status is Closed.

#### Scenario: Default publication state
- **WHEN** a user opens the creation page without changing publication controls
- **THEN** status defaults to `open` and visibility defaults to `public` (`visible=true`)

#### Scenario: Create private open job
- **WHEN** a user creates a job with status `open` and visibility `Private` (`visible=false`)
- **THEN** the job is persisted with those values, does not appear on the public boards listing, but remains reachable via direct link

#### Scenario: Create public open job
- **WHEN** a user creates a job with status `open` and visibility `Public`
- **THEN** the job appears on the public boards (`/careers` and `/:tenant_slug/careers`) as an open, visible job

#### Scenario: Attempt to create public closed job is coerced to private
- **WHEN** a user submits a job with status `closed` and visibility `Public` (e.g., via a crafted request bypassing the disabled control)
- **THEN** the server coerces `visible` to `false` and the job is created as `closed`/`private`; the underlying domain validation `validate_visible_requires_open` remains as a safety net and fails with "cannot be visible when the job is closed" if coercion is bypassed at the context layer

#### Scenario: Visibility control disabled when closed
- **WHEN** the user sets status to `Closed` on the creation form
- **THEN** the visibility control becomes disabled, shows a hint "Closed jobs are private and hidden from public boards.", and its value is treated as `false` (server coerces `visible` to `false` regardless of the submitted value)

### Requirement: Creation form completeness and validation
The creation page SHALL expose all job fields previously available inline: title, description (Markdown hint), salary range, location, employment type, workplace type, pipeline selector (tenant-scoped, default preselected), and tenant-scoped custom job fields. The system SHALL associate the job with the current tenant and SHALL handle empty pipeline gracefully. Validation errors SHALL be shown inline.

#### Scenario: Successful creation with previewed data
- **WHEN** a user submits a valid creation form
- **THEN** a job is created for the current tenant with all submitted fields and the user is redirected to the job detail page with a success flash

#### Scenario: Missing required fields on creation page
- **WHEN** a user submits without title or description
- **THEN** inline validation errors are shown and no job is created

#### Scenario: Pipeline defaults to tenant default
- **WHEN** a user opens the creation page
- **THEN** the pipeline selector lists only the tenant's pipelines with the default pipeline preselected

#### Scenario: Custom job fields on creation page
- **WHEN** the tenant has required custom job fields
- **THEN** the creation page shows them and validates required ones before creation

### Requirement: Tenant isolation on creation page
The system SHALL enforce tenant isolation on the creation page: pipelines, custom fields, and persisted jobs SHALL be scoped to the current tenant, and a user SHALL NOT create a job for another tenant.

#### Scenario: Tenant-scoped pipelines and fields
- **WHEN** a user from tenant A opens the creation page
- **THEN** only pipelines and custom fields belonging to tenant A are shown

#### Scenario: Cross-tenant creation blocked
- **WHEN** a request attempts to create a job with a tenant_id different from the session tenant
- **THEN** the system ignores the supplied tenant_id and uses the session tenant, or rejects the request

