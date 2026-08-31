## 1. Context / Plug

- [x] 1.1 Harden `TrebyWeb.Plugs.CandidateAuth` to compare URL `tenant_slug` tenant vs `candidate.tenant_id`; on mismatch redirect to `/:real_slug/portal` with flash — verify via `mix test test/treby_web/plugs/candidate_auth_test.exs`.
- [x] 1.2 Add helper `Treby.Pipeline.get_application_for_candidate!(tenant_id, candidate_id, id)` with tenant+owner scoping and use it in portal lives.

## 2. LiveView / UI

- [x] 2.1 Update `CandidatePortalLive.Index` `mount` and `select_application` to enforce tenant consistency and ownership check; on failure put_flash + redirect/404.
- [x] 2.2 Update `CandidatePortalLive.{Messages,MessageThread,Schedule,Settings}` mounts to enforce same tenant+ownership checks.
- [x] 2.3 Update `CareersLive.Apply` to detect duplicate before `create_application` (check existing application by candidate+job) and render duplicate-specific UI (message + portal link) with unique DOM id `duplicate-notice`.

## 3. Tests

- [x] 3.1 Add IDOR test: candidate A cannot view candidate B's application (same tenant and cross-tenant) → 404/flash.
- [x] 3.2 Add tenant-mismatch test: authenticated candidate visiting wrong slug is redirected to own slug.
- [x] 3.3 Add duplicate apply test: second submit for same job/email shows duplicate notice, does not create second non-duplicate row.
- [x] 3.4 Run `mix test test/treby_web/live/candidate_portal_live/ test/treby_web/live/careers_live/` and fix.

## 4. Specs + Docs

- [x] 4.1 Update main specs at `openspec/specs/candidate-portal-dashboard/spec.md`, `openspec/specs/candidate-otp-auth/spec.md`, `openspec/specs/career-page/spec.md` (delta already captured — sync on archive).
- [x] 4.2 Sync `site/` user manual if portal security is documented (avoid leaking internals; describe "you only see your own applications").
- [x] 4.3 Run `mix precommit` and `openspec validate --strict` and fix issues.
