## Why

A candidate with no applications (for example, one added via "+ Add Candidate" into the pool) crashes the LiveView process when the recruiter uses "Request Info" or "Reject" from the candidate profile. Both handlers call `List.first(applications).id` on an empty list, raising a `BadMapError` and disconnecting the page.

## What Changes

- Guard all `List.first(applications).id` accessors on the candidate profile (`submit_request_info` at show.ex:1175, `submit_rejection` at show.ex:1239).
- "Request Info" and "Reject" show a clear error message (instead of crashing) when the candidate has no application.
- Keep "+ New Message" nil-safe behavior unchanged (it already guards with `if(application, do: application.id)`).

## Capabilities

### New Capabilities
- None.

### Modified Capabilities
- `candidate-management`: profile portal actions are safe for candidates with no applications.

## Impact

- `lib/treby_web/live/candidates_live/show.ex` (lines 1103, 1175, 1239).
- Candidate profile integration tests.