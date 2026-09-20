## Why

POSTing the portal login without an `email` param raised Phoenix.ActionClauseError (500), and posting a blank/whitespace email passed the search straight through: `Candidates.list_candidates(tenant_id, search: "")` returns every candidate, so the first candidate in the tenant received a login code. The HTML5 `required` attribute does not protect curl/API or JS-disabled clients.

## What Changes

- The portal login controller accepts the request defensively: missing or blank email redirects back to `/portal/login` with "Please enter your email address" and sends no code.
- The verify action applies the same guard when the session email is blank.
- The portal login page renders the generic error flash (it only showed the rate-limit banner).

## Capabilities

### New Capabilities
- (none)

### Modified Capabilities
- `candidate-otp-auth`: requesting a code requires a non-blank email; blank/missing input is rejected without enumeration or sending a code.

## Impact

- Spec: `openspec/specs/candidate-otp-auth/spec.md`.
- Code: `lib/treby_web/controllers/candidate_otp_controller.ex`, `lib/treby_web/live/candidate_portal_live/request_link.ex`.
- Tests: `test/treby_web/integration/candidate_otp_flow_test.exs`.
