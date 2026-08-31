## Why

Candidates can apply to multiple positions (Playwright verified: same email reused via `create_or_find` creates separate applications), but the flow is not guided: after applying to one job the form requires re-typing name/email/phone for the next, there is no indication of which positions they already applied to, and no prefill when coming from the candidate portal. This adds friction for active seekers and increases typo/duplicate risk.

## What Changes

- Pre-fill `Apply` form when candidate is portal-authenticated (session `candidate_id`): auto-populate `name`, `email`, `phone` from `Candidates.get_candidate!(candidate_id)` and show hint "Prefilled from your portal profile".
- On career list (`/:tenant_slug/careers` and `/careers` global) when portal-authenticated, show `Applied ✓` badge / disabled state on jobs the candidate already applied to (lookup via `list_applications_for_candidate`).
- On job detail (`/:tenant_slug/careers/:job_id`) when authenticated and already applied, replace `Apply Now` with `Already applied — View status` linking to `/:tenant_slug/portal`.
- Thank-you page keeps `View other positions` but, when authenticated, highlights remaining not-yet-applied jobs first (optional via query param, no major board logic change).
- All changes are tenant-scoped and only visible when `candidate_id` session exists; anonymous flow unchanged.

## Capabilities

### New Capabilities
- _none_

### Modified Capabilities
- `career-page`: prefill and applied-state awareness on form/detail.
- `public-job-board`: applied badge on listings for authenticated candidates.
- `candidate-portal-dashboard`: portal → careers navigation keeps session for prefill (no spec change, just link behavior).

## Impact

- `lib/treby_web/live/careers_live/apply.ex` — mount reads `session["candidate_id"]` (already passed as second arg) to assign `prefill_candidate`; template uses values.
- `lib/treby_web/live/careers_live/index.ex` / `show.ex` / `global_index.ex` — mount checks session candidate, loads `MapSet` of applied job ids, template conditional badge/CTA.
- `lib/treby/pipeline/pipeline.ex` — reuse `list_applications_for_candidate/2` (no new query).
- No migration, no new deps, no breaking change.
- Docs: `site/` career page documents "apply to multiple positions" flow.
