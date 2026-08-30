## Context

`CandidatesLive.Show` (`lib/treby_web/live/candidates_live/show.ex`) is the candidate profile page at `/app/candidates/:id`. Its `mount_active/6` loads:

```elixir
applications = Pipeline.list_applications_for_candidate(tenant.id, candidate.id)
application_ids = Enum.map(applications, & &1.id)
interviews =
  InterviewEvent
  |> where([e], e.application_id in ^application_ids)
  |> preload([:application, examiners: :user])   # ← line 68, buggy
  |> Repo.all()
```

`InterviewEvent` (`lib/treby/interviews/interview_event.ex`) defines:

```elixir
has_many :event_examiners, Treby.Interviews.EventExaminer
has_many :examiners, through: [:event_examiners, :user]  # if present, else no :examiners assoc
belongs_to :application, Treby.Pipeline.Application
```

The current preload `examiners: :user` assumes `InterviewEvent → :examiners → :user`, but the schema only has `:event_examiners → :user`. Ecto therefore resolves `Treby.Accounts.User` as the intermediate, raising `User has no association :user`. The template then iterates `interview.examiners` for the `Scheduled Interviews` section, so both query and render break.

Reproduction: create tenant `Friction Co 86`, job `Backend Engineer`, candidate `Alice Dome`, schedule interview as `Friction Tester` (examiner), then `GET /app/candidates/:alice_id` or `GET /app/pipeline/:job_id → Alice Dome` → crash. Fresh tenant smoke test missed it because the `application_ids == []` guard skips the query when no interviews exist.

Stakeholders: recruiters viewing candidate profiles (daily), Playwright E2E for the hire loop. The fix must not change tenant scoping (already filtered by `application_ids` derived from `tenant.id`) and must keep `site/` untouched.

## Goals / Non-Goals

**Goals:**
- `GET /app/candidates/:id` returns 200 for candidates with any number of interviews, including the Alice repro.
- `Scheduled Interviews` section shows examiner names and interview metadata (date, time, status, Meet link) without crashing.
- No regression for candidates with zero interviews or cancelled interviews (strikethrough style).

**Non-Goals:**
- No new schema fields, migrations, or `site/` doc changes.
- No change to calendar provider or availability logic.
- No refactoring of `InterviewEvent` associations beyond the preload key (keep `event_examiners` as canonical).
- The duplicate change `fix-candidate-profile-click-crash` is not separately implemented; it merges here.

## Decisions

**Decision 1 — Fix preload to `event_examiners: :user` (chosen) over aliasing `examiners`.**
- *Chosen:* Change line 68 to `preload([:application, event_examiners: :user])` and update the template to iterate `interview.event_examiners |> Enum.map(& &1.user)` (or keep `interview.examiners` if the `through:` is verified to exist, but explicitly preload `event_examiners`).
- *Why:* Matches the actual schema; minimal diff (1 line + template loop), no need to add a new `through` if missing. Verified by `InterviewEvent` source: `has_many :event_examiners` is the join; `examiners` is only a convenience `through`.
- *Alternatives considered:*
  - A) Add `has_many :examiners, through: [:event_examiners, :user]` and keep `examiners: :user` — rejected because it adds schema indirection for a hotfix.
  - B) Eager-load via `Repo.preload(interviews, event_examiners: :user)` after `Repo.all` — equivalent but more verbose; single `preload` in query is sufficient.
- *Verification:* `mount_active` with `application_ids = [fcc61…]` and one `InterviewEvent` with `EventExaminer` for `c8584e…` should return `interview.event_examiners == [%{user: %{name: "Friction Tester"}}]`.

**Decision 2 — Keep guard `if application_ids != []` and template nil-guard.**
- *Chosen:* No change to the empty-list guard; add `if @interviews != []` around the `Scheduled Interviews` block (already present at line 315) to avoid rendering when preload returns `[]`.
- *Why:* Prevents unnecessary query and keeps empty-state "No interviews" handling.

**Decision 3 — Multi-tenant isolation stays via `application_ids` filter.**
- *Chosen:* No new `where(tenant_id == ^tenant.id)` on `InterviewEvent`; `application_ids` already scoped via `list_applications_for_candidate(tenant.id, candidate.id)`.
- *Why:* Minimal change, preserves existing isolation contract (`openspec/specs/candidate-management`).

## Risks / Trade-offs

- **[Risk] Template still uses old key `interview.examiners` → `KeyError` after fix** → Mitigation: grep template for `interview.examiners` and update both mount and render in same PR; add LiveView test that asserts examiner name appears.
- **[Risk] Duplicate change `fix-candidate-profile-click-crash` diverges** → Mitigation: mark that change as `superseded` in `design.md` open question; archive it after this change merges.
- **[Risk] Live reload hides failure in dev (just logs)** → Mitigation: add regression test `live(conn, ~p"/app/candidates/#{alice_id}")` with an interview present, assert `html =~ "Friction Tester"` and `status: 200`.

## Migration Plan

- No migration. Deploy: `mix compile` only. Rollback: revert 1 line.

## Open Questions

- Is `has_many :examiners, through: [:event_examiners, :user]` defined in `InterviewEvent`? Verify via `grep examiners lib/treby/interviews/interview_event.ex`. If yes, either preload is valid, but `event_examiners: :user` is still more explicit for a hotfix.
- Should the duplicate change `fix-candidate-profile-click-crash` be archived as `superseded` or merged via `openspec archive`? Answer: archive after this ships.
