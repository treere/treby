## Why

The three most critical workflows in the app are completely broken:
1. Job creation crashes due to `tenant_id` null violation — the core ATS action is non-functional
2. Candidate creation crashes with the same `tenant_id` null violation — the second most important workflow is broken
3. Mobile navigation is completely missing — the app is unusable on phones/tablets, which is a primary device for small business owners

These must be fixed before any other work, as the platform is effectively non-functional.

## What Changes

- **BUG-001**: Fix job creation by handling empty `pipeline_id` (default prompt) and ensuring `tenant_id` is set directly on the struct before changeset, not via cast
- **BUG-002**: Fix candidate creation by setting `tenant_id` directly on the `%Candidate{}` struct before building the changeset, rather than passing it through attrs where it gets dropped
- **BUG-003**: Add a hamburger menu toggle and mobile slide-out drawer for navigation links on screens below the `sm` breakpoint

## Capabilities

### New Capabilities
- `mobile-navigation`: Hamburger menu toggle and mobile drawer for nav links on small screens

### Modified Capabilities
- `job-management`: Fix `handle_event("create_job")` to sanitize empty `pipeline_id` and set `tenant_id` on the struct directly
- `candidate-management`: Fix `create_candidate` to set `tenant_id` on the `%Candidate{}` struct directly before changeset

## Impact

- `lib/treby_web/live/jobs_live/index.ex` — job creation handler and form
- `lib/treby_web/live/candidates_live/index.ex` — candidate creation handler
- `lib/treby/jobs/jobs.ex` — `create_job` function
- `lib/treby/candidates/candidates.ex` — `create_candidate` function
- `lib/treby_web/components/layouts.ex` — main nav component
