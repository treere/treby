## 1. Fix Job Creation (BUG-001)

- [x] 1.1 In `lib/treby_web/live/jobs_live/index.ex`, sanitize `pipeline_id` in `handle_event("create_job")` — convert empty string to nil before passing to `create_job`
- [x] 1.2 In `lib/treby/jobs/jobs.ex`, set `tenant_id` directly on the `%Job{}` struct before calling `Job.changeset/2`, instead of passing it through attrs
- [ ] 1.3 Verify job creation works with "Default pipeline" prompt selected
- [ ] 1.4 Verify job creation works with a specific pipeline selected

## 2. Fix Candidate Creation (BUG-002)

- [x] 2.1 In `lib/treby/candidates/candidates.ex`, set `tenant_id` directly on the `%Candidate{}` struct before calling `Candidate.changeset/2`, instead of passing it through attrs
- [x] 2.2 Remove the `Map.put` of `tenant_id` into attrs in `lib/treby_web/live/candidates_live/index.ex` `handle_event("create_candidate")`
- [ ] 2.3 Verify candidate creation succeeds without tenant_id null violation

## 3. Add Mobile Navigation (BUG-003)

- [x] 3.1 In `lib/treby_web/components/layouts.ex`, add a hamburger button visible only below `sm` breakpoint
- [x] 3.2 Add a mobile navigation drawer component with all nav links (Jobs, Candidates, Interviews, Analytics, Settings)
- [x] 3.3 Add a colocated JS hook or Alpine.js toggle for open/close state with backdrop overlay
- [ ] 3.4 Verify mobile nav works at 375px viewport width
- [ ] 3.5 Verify desktop nav remains unchanged at wider viewports

## 4. Final Verification

- [x] 4.1 Run `mix precommit` and fix any lint/type issues
- [ ] 4.2 Manual smoke test: create a job, create a candidate, test mobile nav
