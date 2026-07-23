## Why

The jobs listing page (`/app/jobs`) currently links job titles directly to the pipeline board, skipping the job detail view entirely. Users have no quick way to see a job's description or its associated candidates without navigating away. Additionally, the UI relies on plain text links for actions like "Pipeline", "Close", and "Reopen", making the interface feel bare and less scannable. Adding icons and a richer job detail view will make the jobs workflow faster and more intuitive.

## What Changes

- **Jobs index**: Job title links to the new job detail page (`/app/jobs/:id`) instead of the pipeline board
- **Job detail page**: Add a candidates section below the description showing all candidates who applied to this job, with key details (name, email, current pipeline stage, application date)
- **Icons**: Add Heroicon icons to action buttons and links across the jobs index and job detail pages (new job, pipeline, close/reopen, edit, back navigation)
- **Job detail page**: Add a link to the pipeline board from the detail page header

## Capabilities

### New Capabilities

- `job-detail-candidates`: Show candidates associated with a job on the job detail page with relevant details

### Modified Capabilities

- `job-management`: Job title in listing links to detail page instead of pipeline; action buttons gain icons

## Impact

- `lib/treby_web/live/jobs_live/index.ex` — update job title links, add icons to action buttons
- `lib/treby_web/live/jobs_live/show.ex` — add candidates section, add pipeline link, add icons
- `lib/treby/pipeline/pipeline.ex` — potentially add a query to list candidates/applications for a job
- `lib/treby_web/router.ex` — no changes needed (job show route already exists)
- Existing tests that navigate to job detail may need path updates
