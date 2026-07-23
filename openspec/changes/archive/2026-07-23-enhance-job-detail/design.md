## Context

The jobs workflow currently has two disconnected views: a listing page (`/app/jobs`) that shows a table of jobs, and a pipeline board (`/app/pipeline/:job_id`) for managing candidates through stages. The job detail page (`/app/jobs/:id`) exists but is never linked from the listing — clicking a job title goes straight to the pipeline. The detail page shows description and metadata but has no candidates section.

The UI uses plain text for all actions (e.g. "Pipeline", "Close", "Reopen") with no visual cues.

## Goals / Non-Goals

**Goals:**
- Make the jobs listing page the entry point to both job details and pipeline board
- Show candidates applied to a job directly on the job detail page
- Add Heroicon icons to key action buttons across jobs pages for better scannability
- Keep the pipeline board accessible from the job detail page

**Non-Goals:**
- Redesigning the pipeline board itself
- Adding candidate actions (move, edit) from the job detail page — that stays on the pipeline board
- Changing the candidate listing or candidate detail pages
- Adding pagination to candidates (can be done later)

## Decisions

### 1. Job title links to detail page, pipeline button stays as separate action

**Decision**: Change the job title `<.link>` in the index to point to `~p"/app/jobs/#{job.id}"` instead of `~p"/app/pipeline/#{job.id}"`. Add a dedicated "View Pipeline" icon link in the actions column.

**Rationale**: Users need to see job details before deciding to manage the pipeline. The pipeline board remains accessible via a clear icon button.

**Alternative considered**: Keep title linking to pipeline, add a separate "Details" link. Rejected because the detail view is the natural first click when exploring a job.

### 2. Candidates section uses existing `list_applications_for_job/1`

**Decision**: Reuse `Treby.Pipeline.list_applications_for_job/1` which already preloads `:candidate` and `:pipeline_stage`. No new queries needed.

**Rationale**: The function already returns exactly what we need — applications with candidate info and current stage. Adding it to the show LiveView's `mount` is sufficient.

### 3. Icons via imported `<.icon>` component

**Decision**: Use the already-imported `<.icon name="hero-..." />` component from `core_components.ex` for all icon additions. No new dependencies.

**Rationale**: Phoenix v1.8 already provides heroicons through this component. Using it avoids adding any external deps.

### 4. Candidate display format

**Decision**: Show candidates as a card list with: name, email, current pipeline stage (as a colored badge), and application date. No avatar/gravatar for now.

**Rationale**: Keeps the implementation simple while providing the key information users need at a glance.

## Risks / Trade-offs

- **[Risk]** Large number of candidates could make the detail page very long → **Mitigation**: Acceptable for now; pagination can be added as a follow-up if needed.
- **[Risk]** Existing tests that click job titles may break since URLs change → **Mitigation**: Update affected test assertions to match new link targets.
- **[Trade-off]** Icons add visual density → Accepted as improvement over plain text for action discoverability.
