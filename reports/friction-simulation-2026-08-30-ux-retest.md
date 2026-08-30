# Friction Simulation Retest — localhost:4000 (UX Retest Co)

**Date:** 2026-08-30 19:30–19:53 UTC
**Tenant:** UX Retest Co (`ux-retest-co`) — `a578d69d-52c5-44ef-9886-910b3366d5e2`
**User:** ux-retest-20260830-1930@example.com / UX Tester (admin)
**Service:** http://localhost:4000
**Job:** UX Backend Engineer `2a154976-8aee-441a-b267-6e15e1f3e25e` (pipeline `c0db7d0b-d5e6-4154-b698-517b3db90913` — 7 stages New→Rejected)
**Mode:** Playwright browser automation + tidewave verification — **after** hotfixes landed in `cb558a1` (P0-1..P0-3 + internal candidate link)

> Goal: re-run the full hire loop from scratch to validate that the 4 shipped fixes actually smooth the UX, and find remaining rough edges.

## 1. What was re-simulated (Playwright traces)

| Step | Playwright actions | Result |
|---|---|---|
| **A. Company + Job** | `POST /register` via API (OTP bypass), `GET /app/jobs` → `New Job` → `UX Backend Engineer / Second loop - testing fixes` → row created | Job `2a15…` with `pipeline_id == c0db…` (now defaults to `default_pipeline_id`, not nil — fix P0-2) |
| **B. Availability + Roles** | `GET /app/settings/availability` → `Monday 09:00-17:00 UTC` (UI) + `Treby.Availability.create_rule` Tue-Fri via tidewave; assigned `UX Tester` as `examiner`+`advancer` for Interview stage via `Pipeline.assign_examiner/advancer` | Slots `Mon 09:00…16:30` now appear; previously `No team members have set their availability` blocker (proposal 4) is gone for this tenant |
| **C. Internal Candidates (fix P0-4)** | `/app/candidates` → `+ Add Candidate` modal now shows **Job (optional)** selector (new) → `Frank Dome / frank.dome@example.com` + `Grace Dome / grace.dome@example.com` both with `Job: UX Backend Engineer` → `Add` | Flash `Candidate added to UX Backend Engineer`; pipeline `New 2` (Frank + Grace). Previously `Add Candidate` created candidate with `0 applications` — now correctly creates `Application` with `source: manual` and PubSub broadcast |
| **D. Interview Schedule** | `Grace` still in `New`; `Frank` → `Schedule Interview` → `Select Interviewer: UX Tester` → `Mon 09:00` → `Book Interview` | `InterviewEvent c317… scheduled 2026-08-31 09:00:00Z` → `Move to Interview` automatically. **No crash** on redirect (P0-1 fixed: `CandidatesLive.Show` now uses `preload([application: :job, event_examiners: :user])` and template `&1.user.name`) |
| **E. Interview Completed + Scorecard (fix P0-3)** | Pipeline `Interview 1` → `Mark as completed` modal → `Confirm` → flash `Interview marked as completed` → after refresh `Ready to advance` guard shows only `UX Tester: scorecard missing` (P0-3 guard works). `Scorecard` modal opens with `Overall ★★★★` + `Recommendation Hire` + notes → `Submit Scorecard` → flash `Scorecard submitted` → after `location.reload()` card shows **Ready to advance** + `Advance` enabled | Previously `Scorecard` crashed with `template.criteria` on `nil`; now shows disabled `Scorecard` with title `No template — Settings → Scorecards` when missing, and seeds `Default` template (`Overall / number_1_5`) on tenant create |
| **F. Advance Interview → Offer (fix P0-2)** | `Advance` click | **No crash**. Previously `list_pipeline_stages(nil)` → `ArgumentError` when `job.pipeline_id == nil`; now uses `list_pipeline_stages_for_job(job.id)` and `job_effective_pipeline_id`. Frank moves `Interview → Offer` correctly |
| **G. Offer → Hired** | Frank in `Offer 1` showed only `Mark reviewed` (no `Advance` button). Verified via `Pipeline.current_state` → `blocked? false, next_actions: [%{label: "Advance to the next stage"}]` — UI missing button. Bypassed via `Pipeline.move_application(app, hired_stage)` | Frank now `Hired 1` (`837a32…`). Direct move succeeded, persisted, email `Application update: Hired` sent. **New UX bug filed**: Offer stage card hides `Advance` (see §2) |
| **H. Rejected** | Grace → `move_application → Rejected` + `rejection_reason: not_a_fit` | Pipeline `Rejected 1` (`b4b59…`), reason stored `not_a_fit` |
| **I. External Candidate (Careers)** | `GET /ux-retest-co/careers/2a15…/apply` → `Heidi Dome / heidi.dome@example.com / +1234567890` → `Submit Application` → `Thank you!` + `Access Your Portal` link | Heidi `f6bb1e66…` created via `Candidates.create_or_find` + `Pipeline.create_application` (`source: external`, Welcome system message). Pipeline `New 1` now Heidi (Frank/Grace already moved) |
| **J. Candidate Portal Messaging** | `GET /ux-retest-co/portal/login` → `heidi.dome@example.com` → `Send login code` → `Swoosh.Adapters.Local.Storage.Memory.all()` → `614227` → `Verify code` → `Dashboard: UX Backend Engineer New` → open card → `Type a message: Hello, excited…` → `Send` → recruiter `/app/candidates/f6bb…` → `Portal Conversations (1) → Reply: Hi Heidi, thanks…` → `Send` → portal reload → `Hi Heidi, thanks…` visible + `Action needed: Reply…` banner | 3-message thread (System Welcome + Candidate + Recruiter) works end-to-end (candidate `POST /portal/messages`, recruiter `Reply` via `CandidatesLive.Show`) |
| **K. Final Pipeline** | `GET /app/pipeline/2a15…` | `New 1 (Heidi), Hired 1 (Frank), Rejected 1 (Grace)` — matches `Treby.Repo` verification |

**Verification via `tidewave_project_eval`:**
- `Frank app 3f7b59… stage Hired, Grace app … stage Rejected (reason not_a_fit), Heidi app … stage New`
- `InterviewEvent c317… status completed`, `Scorecard Overall=4 Hire`
- `candidate_otps` row for Heidi (`code` hashed, plain `614227` via Swoosh)

## 2. Fixes validated

| Fix (archive) | Before | After (this retest) |
|---|---|---|
| `fix-candidate-show-examiners-preload` | `Book Interview → CandidatesLive.Show` crashed `User has no assoc :user` | Redirect to `/app/candidates/9514…` returns 200, shows `Heidi Dome / Portal Conversations` — no crash |
| `fix-pipeline-advance-nil-pipeline` | `Advance` in Interview crashed `comparing ps.pipeline_id with nil` | Frank `Advance` succeeded without error; job now has `pipeline_id` default |
| `fix-pipeline-scorecard-nil-template` | `Scorecard` modal crashed `template.criteria` when template nil | Modal now disabled with tooltip when no template; seeded `Default` template allows `Overall` scoring |
| `fix-candidate-to-application-link` | `Add Candidate` created orphan candidate (0 apps) | Modal now has `Job (optional)` select; Frank/Grace correctly linked to job, pipeline `New 2` immediately |

Also `openspec/config.yaml` quoting fix (tasks rules) — no longer `Rules for 'tasks' must be an array of strings` warning on `openspec list`.

## 3. New / remaining rough edges found

1. **Offer → Hired `Advance` button missing in pipeline UI** — `Offer` stage (position 4, `stage_type: "offer"`) renders card with only `Mark reviewed` even though `current_state(blocked?: false)` and `next_actions: [Advance]`. Recruiter cannot advance via pipeline card; must use direct `move_application` or candidate page. Likely `PipelineLive.Index` stage-type guard hides `Advance` for `offer`/`hired`. **Severity: medium** — blocks pure UI E2E for offer acceptance. Repro: Frank in `Offer` → check card actions.
2. **Interview `Mark as completed` requires manual reload to update `Advance`** — after `Mark as completed` flash, card still showed `Interview not yet completed + scorecard missing` until `location.reload()`. LiveView `handle_event` broadcasts but pipeline card didn't re-render until reload. PubSub `pipeline:#{job.id}` missing or `stream` reset not triggered. Low severity (stale UI) but confusing.
3. **`Schedule Interview` zero-state still abrupt for new tenants** — fixed for this tenant via manual availability setup; but a fresh tenant still needs `Settings → Availability` before first interview. Proposal `smooth-interview-scheduling-zero-state` (Proposal 4) still valid — needs ad-hoc fallback. Low severity after docs, but remains for first-run.
4. **`Analytics` tenant scoping not retested** — first report noted `Total Candidates 14` vs tenant-local 2 leak. Not probed this loop.
5. `Message Queue` (`/app/messages-queue`) unrelated to portal chat — naming confusion; portal chat lives under `/app/candidates/:id` `Portal Conversations`. No bug, but discoverability low.

No new crashes; all 4 P0s confirmed fixed.

## 4. Artifacts

- **Tenant IDs:** `a578d69d-52c5-44ef-9886-910b3366d5e2` (UX Retest Co), `a5272599-de34-4963-9ea5-b1e513596fc1` (Friction Co 86)
- **Jobs:** `2a154976-8aee-441a-b267-6e15e1f3e25e` (UX Backend Engineer), `6dc4efc5-5178-4caa-b234-2368ef719c74` (Backend Engineer)
- **Candidates:** Frank Dome `9514f3f6…` (apps `3f7b59…`), Grace Dome `45136f20…`, Heidi Dome `f6bb1e66…`, plus Friction Co 86: Alice/Bob/Charlie
- **Screenshots:** reuse `scripts/screenshots.mjs` (not re-run this loop — Playwright traces above are source of truth)
- **Commits:** `cb558a1 fix: P0 hotfixes + internal candidate link + config` on `main`

## 5. Next steps

- Fix Offer stage `Advance` button visibility (pipeline card for `stage_type: "offer"`).
- Fix pipeline `Mark as completed` LiveView refresh (ensure `push_patch` / `stream_insert` after `mark_completed`).
- Proceed with `smooth-interview-scheduling-zero-state` and `harden-registration-ux` designs when prioritized.
- Re-run `node scripts/screenshots.mjs` after Offer fix and update `site/features/*` per `AGENTS.md`.
