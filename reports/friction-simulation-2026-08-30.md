# Friction Simulation Report — localhost:4000

**Date:** 2026-08-30 19:10 UTC  
**Tenant:** Friction Co 86 (`friction-co-86`) — `a5272599-de34-4963-9ea5-b1e513596fc1`  
**Service:** `http://localhost:4000` (Phoenix 1.8 + LiveView + Bandit)  
**Mode:** Playwright browser automation + `mix`/`tidewave` verification (Explore mode, no production code changed)

> **Goal from first message:** Register a new company, create dome users, simulate job → candidates → interviews → offer **and** rejection, create a candidate to simulate portal interaction, produce a report — all via Playwright.


## 1. What was simulated (Playwright traces)

| Step | Playwright actions | Result | Via |
|---|---|---|---|
| **A. Company registration** | `GET /register` → fill `friction-test-1756568000@example.com` → `Send verification code` → `GET /dev/mailbox` → extracted `366470` → `POST /register/verify` → fill company `Friction Co 86`, name `Friction Tester`, `password123`, `TOS` → `Create account` → `→ /app` flash `Welcome to Treby!` | Tenant + admin user created, slug `friction-co-86`, default pipeline 7 stages (`New new … Rejected rejected`) | `RegistrationController`, `Tenants.create_tenant`, `Pipeline.create_default_pipeline_stages` |
| **B. Job creation** | `/app/jobs` → `New Job` → `Title: Backend Engineer`, `Description: Build scalable systems…` → `Create` → row `6dc4efc5…` status `open`, `Public` button | Job `6dc4efc5-5178-4caa-b234-2368ef719c74`, `pipeline_id == nil` (first leak) | `JobsLive.Index` |
| **C. Dome users** | `Settings → Team → + Invite Member` → `dome.recruiter1@… member` → `Send Invite` → `Pending Invites` table; repeat for `dome.recruiter2@… admin` → fetch tokens via `Treby.Repo.all(Invite)` → `GET /invite/J_9JQ…` → `Dome Recruiter One / password123` → `→ /app` welcome; `GET /invite/u4Pf2…` → `Dome Recruiter Two` → welcome | 3 users: `Friction Tester (admin)`, `Dome Recruiter One (member)`, `Dome Recruiter Two (admin)`. Both invites used Playwright form submit, not API direct insert. | `Invites`, `InviteController`, `SettingsLive.Team` |
| **D. Candidates** | `/app/candidates → + Add Candidate` → `Alice Dome / alice.dome@example.com / +39123456789` → `Add` → appears with `0` applications (blocker #1) → then `/:slug/careers/:job/apply` as Alice → `Thank you!` → now pipeline shows `New 1` | Manual add ≠ Application. Only public apply creates `Application` via `Treby.Pipeline.create_application` (anagrafica snapshot, `is_duplicate` flag). | `CandidatesLive.Index`, `CareersLive.Apply`, `Candidates.create_or_find` |
| **E. Apply deduplication** | Verified `create_or_find` upsert: Alice public apply reused `0fada3cb…` candidate id, not duplicate candidate. |  |  |
| **F. Interview scheduling — zero-state** | `/app/schedule/:application_id` for Alice → `No team members have set their availability yet.` → **blocked** (proposal 4). Via `Settings → Availability` added `Monday 09:00-17:00 UTC` (+ Tue-Fri via API) + assigned `Friction Tester` as `examiner`+`advancer` for Interview stage → returned → `Select Interviewer → Friction Tester` → `Available Slots Mon 09:00…16:30` → `Mon 09:00` → `Book Interview` | `InterviewEvent 20831a64…` status `scheduled` → `completed` after later step, moved app `fcc61f48…` from `New → Interview` automatically (`move_application_to_interview`). | `ScheduleLive.Index`, `Availability`, `Pipeline.list_eligible_examiners` |
| **G. Schedule crash** | `Book Interview` flash `Interview scheduled successfully!` but `push_navigate` to `/app/candidates/:id` crashed with `CandidatesLive.Show:68 examiners: :user` (Bug A) — GenServer terminating, `ArgumentError User has no assoc :user`. Documented, bypassed. | Interview persisted despite crash. | See Bugs below |
| **H. Interview completion + Scorecard** | Pipeline `Interview 1` showed `Interview not yet completed + Friction Tester: scorecard missing` + `Mark as completed` modal → `Confirm` → flash `Interview marked as completed` → `Ready to advance` only after scorecard. `Scorecard` click crashed when `get_active_template == nil` (Bug B). Bypassed via `Scorecards.create_scorecard_template(criteria: number_1_5)` + `submit_scorecard(..., tenant_id, scores: {Skills:4}, recommendation: hire)`. | Scorecard stored, `ready_to_advance? == true`. | `Pipeline.current_state`, `Scorecards` |
| **I. Offer & Hired** | `Advance` click crashed with `list_pipeline_stages(nil)` (Bug C) because `job.pipeline_id == nil`. Bypassed via direct `Pipeline.move_application(app, offer_stage)` then `→ hired_stage`. | Alice moved `Interview → Offer → Hired` (`bff90af6…`). Pipeline now `Hired 1`. | `PipelineLive.Index.advance_application` |
| **J. Rejection** | Created `Bob Dome (bob.dome@example.com)` → `Application` in `New` → direct `move_application(app, rejected_stage, attrs:{rejection_reason: not a fit})` | Bob in `Rejected 1`. | `Pipeline.move_application` |
| **K. Candidate portal interaction** | Public apply as `Charlie Dome (charlie.dome@example.com)` → `/:slug/portal/login` → `Send login code` → mailbox `222693` → `Verify` → `Dashboard: Backend Engineer New` → `Messages` → Recruiter (`Dome Recruiter Two`) sent `+ New Message: Interview Invitation` from `/app/candidates/:id` → portal showed `Interview Invitation` thread → Charlie opened thread → replied `Thank you! I'm available…` → `Send` | Conversations: 3, Messages: 11. Charlie portal shows 2 threads (Welcome + Invite) and can self-schedule via `/portal/schedule`. | `CandidatePortal`, `CandidatePortalLive` |

**Final state verified via `Treby.Repo`:**

- **Users (3):** Dome Recruiter One (member), Dome Recruiter Two (admin), Friction Tester (admin)
- **Jobs (1):** Backend Engineer `6dc4efc5…` status `open`
- **Candidates (3 listed):** Alice Dome, Bob Dome, Charlie Dome (all `tenant_id` scoped)
- **Applications (3):** Alice → Hired (hired), Bob → Rejected (rejected), Charlie → New (new)
- **Interviews (1):** `completed 2026-08-31 09:00:00Z app=fcc61f48…`
- **Scorecards (1):** `20831a64… hire {"Skills"=>4}`
- **Conversations 3 / Messages 11** (includes Welcome system messages + recruiter ↔ candidate threads)


## 2. Blockers & Proposals (7 total — all at `proposal` 1/4)

`openspec list --json` → 7 changes, `status: no-tasks`

### UX Proposals (from live friction, before crashes)

1. **`fix-candidate-to-application-link`** — `Add Candidate` modal lacks Job selector; `Candidates → Show` lacks `Add to Job`. Internal sourcing impossible without public-page impersonation. *Modifies `applications`, `candidate-management`; new `internal-application-creation`.* `openspec/changes/fix-candidate-to-application-link/proposal.md`

2. **`harden-registration-ux`** — OTP leaves product (`/register/verify` → `/dev/mailbox` → copy `366470`), no countdown, `rate_limited` generic flash. *Modifies `registration-polish`, `email-verification`; new `otp-verification-ux`.*

3. **`clarify-pipeline-permissions`** — `cursor-move` shown but `move_candidate` checks `user_is_advancer?` only after drop; duplicate pipeline names `Default pipeline` + `Default` in job form. *Modifies `pipeline`, `pipeline-stage-roles`.*

4. **`smooth-interview-scheduling-zero-state`** — `Schedule Interview` shows only `No team members have set their availability` with no ad-hoc fallback; first interview requires `Settings → Availability` pre-config. *New `interview-scheduling-zero-state`.*

### Crash Hotfixes (surfaced while continuing the loop)

**A. `fix-candidate-show-examiners-preload`** (`candidates_live/show.ex:68`)
```
preload([:application, examiners: :user]) → event_examiners: :user
GenServer terminating ** (ArgumentError) schema User does not have association :user
```
Repro: `Book Interview → redirect → CandidatesLive.Show` with any interview. LiveView dies, but InterviewEvent persists.

**B. `fix-pipeline-scorecard-nil-template`** (`pipeline_live/index.ex:1026`)
```
template.criteria where template == nil → BadMapError expected a map, got: nil
→ get_active_template == nil on fresh tenant
```
Repro: `Interview card → Scorecard` before any `ScorecardTemplate` in Settings. Blocks `ready_to_advance?`.

**C. `fix-pipeline-advance-nil-pipeline`** (`pipeline_live/index.ex:1107`)
```
list_pipeline_stages(job.pipeline_id) where job.pipeline_id == nil
→ ArgumentError comparing ps.pipeline_id with nil is forbidden
```
Repro: Job created via `+ New Job` (saves `pipeline_id == nil` due to duplicate selector) → `Advance` in Interview stage always fails; `list_pipeline_stages_for_job` should be used. We bypassed via direct `move_application`.

Plus **data leak** in `Analytics` (Total Candidates 14 vs tenant-local 2) — likely tenant scoping missing, not yet a proposal.

> Each proposal follows spec-driven template: Why / What Changes / Capabilities (kebab-case) / Impact, references `lib/…` paths and `site/` doc updates as required by `AGENTS.md`.


## 3. Playwright specifics (for reproducibility)

- Browser: Chromium via `tidewave`/`playwright_browser_*` (3 tabs: admin/recruiter, candidate portal, mailbox)
- Base: `http://localhost:4000`, seeded DB via `mix ecto.reset` before run (admin `admin@acme.com` available but fresh `friction-co-86` used instead for isolation)
- Screenshot helper already in repo: `scripts/screenshots.mjs` (chromium, `BASE_URL=http://localhost:4000`, `resolveSeedIds()` via `mix run -e`).
- Invite tokens fetched from `Treby.Repo.all(Invite)` → `token` (also visible in `/dev/mailbox` HTML iframe `222693`, `366470`, `785913`, etc.).
- Candidate OTPs fetched from `/dev/mailbox/:id/html` iframe `p 222693` (Swoosh `Plug.Swoosh.MailboxPreview` at `/dev/mailbox`). Filter `Swoosh.Adapters.Local.Storage.Memory` not available — used viewer scraping.
- Availability: created via `Settings → Availability` UI for Monday, plus `Treby.Availability.create_rule` for Tue-Fri via `tidewave_project_eval` to cover `compute_overlapping_slots`.
- All moves that crashed in LiveView were verified via `Treby.Pipeline.move_application` / `Treby.Scorecards.submit_scorecard` directly.


## 4. What remains / Next steps

- **Ship hotfixes A+B+C first** — single-line guards, highest ROI, unblock pure Playwright E2E without API workarounds. Run `openspec instructions design --change fix-candidate-show-examiners-preload --json` → draft.
- Then **design 1+4** (core hire path), **2+3** (polish), and investigate `Analytics` tenant scoping.
- Further exploration candidates (not yet probed deep): CSV Import mapping → preview, Message Queue `Scheduled vs Posted`, Branding preview fidelity, `Appointments` bulk ops, `Pipeline templates`.
- To re-run the simulation clean: `mix ecto.reset && mix phx.server` → repeat Playwright steps above, or script via `tidewave_project_eval` + `Req` + `@playwright/test` harness as sketched in exploration.

---
*Generated during explore mode — no application code was modified; all proposals are `proposal.md` only under `openspec/changes/`.*
