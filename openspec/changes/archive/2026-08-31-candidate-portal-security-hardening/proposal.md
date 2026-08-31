## Why

Playwright + code review found two authorization gaps in the candidate portal: (1) `CandidatePortalLive.Index` `select_application` loads any `Application` by UUID via `get_application!(id)` without checking `candidate_id` or `tenant_id` ownership, potentially leaking another candidate's job title via the detail pane; (2) portal mounts resolve `tenant` from URL slug and `candidate` from session independently without verifying `candidate.tenant_id == tenant.id`, allowing brand confusion and weakening tenant isolation guarantees. Duplicate submissions also silently succeed with `is_duplicate=true` instead of informing the candidate.

## What Changes

- Enforce ownership check on every candidate-portal application access: `application.candidate_id == current_candidate.id AND application.tenant_id == current_tenant.id`, otherwise redirect/404 and log warning.
- Enforce tenant consistency on every portal mount (`Index`, `Messages`, `MessageThread`, `Schedule`, `Settings`, `Verify`): if `candidate.tenant_id != slug_tenant.id`, redirect to `/:candidate_tenant_slug/portal` (or show 404) and invalidate mismatched view.
- Harden `CandidateAuth` plug to also assign `current_tenant` from candidate's real tenant and optionally validate slug matches.
- Surface duplicate-application feedback on `CareersLive.Apply`: if `Candidates.create_or_find` reused candidate and `set_duplicate_flag` would mark duplicate, show inline info "You have already applied to this position on {date}" with link to portal, instead of generic "Thank you" duped.
- Add PubSub / query scoping audit: ensure all portal queries are tenant-scoped.

## Capabilities

### New Capabilities
- _none_

### Modified Capabilities
- `candidate-portal-dashboard`: ownership/tenant checks on dashboard and detail.
- `candidate-otp-auth`: tenant consistency on login/portal session.
- `career-page`: duplicate-application user feedback on submit.

## Impact

- `lib/treby_web/plugs/candidate_auth.ex` — add slug vs candidate tenant check.
- `lib/treby_web/live/candidate_portal_live/*` — all mounts + `select_application` / `send_detail_message` / thread handlers.
- `lib/treby_web/live/careers_live/apply.ex` — duplicate detection branch + UI state.
- `lib/treby/pipeline/pipeline.ex` — expose helper to check duplicate without side effect if needed.
- No migration (uses existing `is_duplicate` + `tenant_id`).
- Tests: portal IDOR tests, tenant-mismatch redirect tests, apply duplicate feedback test.
