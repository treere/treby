## Why

The app currently has a per-tenant career page, but there's no way for external candidates to discover jobs across companies or search for positions. Companies also need fine-grained control over which jobs appear publicly, and a way to share job links even for non-public listings.

## What Changes

- **Per-job visibility**: Add a `visible` boolean to jobs so companies control which open positions appear on the public board. Non-visible jobs are still accessible via direct link.
- **Global job board**: A new `/careers` page showing all visible open positions across all tenants, with company info.
- **Search**: Simple text search on the public boards (title + description).
- **Job not found page**: Closed jobs show a "position not found" page instead of working.
- **Rich job detail**: Public job detail page shows company logo, name, and description.
- **Copy public link**: Internal job detail page has a button to copy the public URL.
- **Visibility toggle**: Internal job listing shows a public/private toggle for each job.

## Capabilities

### New Capabilities

- `public-job-board`: Global and per-tenant public job boards with search, visibility filtering, and job detail pages.
- `job-search`: Simple text search functionality across public job listings.

### Modified Capabilities

- `career-page`: Add per-job visibility control, enhanced job detail with company info, and "not found" state for closed jobs.
- `job-management`: Add visibility toggle in job listing and copy-public-link in job detail.

## Impact

- **Schema**: Migration to add `visible` boolean field to `jobs` table.
- **Context modules**: `Jobs` context gains search and visibility-filtered query functions.
- **LiveViews**: New `CareersLive.GlobalIndex`, enhanced `CareersLive.Index` and `CareersLive.Show`, modified `JobsLive.Index` and `JobsLive.Show`.
- **Router**: New `/careers` route for global board.
- **Templates**: Enhanced public job detail page with company branding.
