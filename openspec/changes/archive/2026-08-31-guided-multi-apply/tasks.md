## 1. LiveView / UI

- [x] 1.1 Update `CareersLive.Apply.mount` to read `session["candidate_id"]` / `session["candidate_tenant_id"]`, load candidate when tenant matches, and assign prefill map; update `render` to use prefilled `to_form` values and show "Prefilled from your portal profile" hint — verify with LiveView test.
- [x] 1.2 Update `CareersLive.Index.mount` to load `MapSet` of applied job ids for authenticated candidate of that tenant; update template to render "Applied ✓" badge on matching cards.
- [x] 1.3 Update `CareersLive.Show.mount`/`render` to load applied set and swap "Apply Now" for "Already applied — View status" link when already applied.
- [x] 1.4 Update `CareersLive.GlobalIndex.mount`/`render` similarly, filtering badge by `job.tenant_id == candidate tenant`.

## 2. Tests

- [x] 2.1 Add tests: authenticated candidate sees prefilled apply form; anonymous sees empty form.
- [x] 2.2 Add tests: list shows badge for already-applied job, not for others; global board badge only for own-tenant jobs.
- [x] 2.3 Add tests: detail shows swapped CTA when already applied.
- [x] 2.4 Run `mix test test/treby_web/live/careers_live/` and fix.

## 3. Specs + Docs

- [x] 3.1 Update main specs at `openspec/specs/career-page/spec.md` and `openspec/specs/public-job-board/spec.md` (delta already captured — sync on archive).
- [x] 3.2 Sync `site/` career page user manual to document "Apply to multiple positions" with screenshots; note prefill only when logged into portal.
- [x] 3.3 Regenerate screenshots with `node scripts/screenshots.mjs`.
- [x] 3.4 Run `mix precommit` and `openspec validate --strict` and fix issues.
