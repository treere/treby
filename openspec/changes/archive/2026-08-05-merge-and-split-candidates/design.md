# Design: Merge and Split Candidates

## Context

Current state of the relevant model (`lib/treby/`):

```
candidates (name, email, phone, linkedin_url, custom_fields)
  └─ has_many applications (job_id, pipeline_stage_id, resume_url,
        source, custom_fields, applied_at, reviewed)
       └─ has_many notes, interview_events (→ scorecards)
candidates ─ has_many email_threads (candidate_id, tenant_id)
activity_log (entity_type, entity_id) — candidate-level and application-level events
```

- Candidate identity/dedup is `find_or_create_candidate/2` (candidates.ex:60), a case-insensitive `get_by` on `(tenant_id, email)`. The index is **not unique** (20260714103413), so duplicate records can coexist.
- **Data-loss bug**: when an existing candidate re-applies, `find_or_create_candidate` returns the stored record and the newly entered name/phone/etc. are discarded — they are not stored anywhere.
- A candidate's full history is already rendered on `CandidatesLive.Show` (applications + notes per app, interviews, scorecards, activity timeline, email threads). The gaps are *fragmented identities* (no merge/undo), *lost per-application data*, and *no cross-job visibility*.
- Three application-creation flows exist: public career page (`CareersLive.Apply`), CSV import (`CsvImport.execute_import/5`), and direct candidate creation in `CandidatesLive.Index`.

## Goals / Non-Goals

**Goals:**
- A single, complete "master" candidate profile per person, used as the internal reference (identity, emails, dedup).
- Each application permanently preserves the anagrafica the applicant entered at submission time; editing the master never rewrites history.
- Merge duplicate candidates into one, keeping *all* data; the master anagrafica is selectable (default: the first candidate).
- Reversible merges (undo/split) with zero data loss, including redirects from absorbed profiles.
- Simple duplicate-suggestion heuristics; automatic merge only for exact email.
- At-a-glance "candidate is also active elsewhere" indicator on pipeline cards; duplicate application to the same job allowed but flagged.

**Non-Goals:**
- Fuzzy/approximate matching engines (edit distance, phonetic algorithms). Only the three simple signals agreed with the user.
- Auto-merging on anything other than exact email (name+phone and name+local-part remain suggestions).
- Merging across tenants (merges are strictly per-tenant).
- Automatically updating the master anagrafica from new applications (stays manual; snapshots preserve the data for a future explicit "update profile from application" action).
- Re-attributing email threads during undo based on application content — threads are candidate-level and move with the candidate via the recorded mapping.
- Blocking re-application to the same job.

## Decisions

### D1. Anagrafica snapshot: single `anagrafica` map column on `applications`

A single nullable `:map` column `anagrafica` holding `%{name, email, phone, linkedin_url}` (keys present only when non-empty). `application.custom_fields` already captures application-level custom data, so it stays as-is.

- **Alternatives**: (a) four explicit columns — rigid, more code in every flow; (b) a separate `application_anagrafica` table — over-normalized for a frozen snapshot; (c) reuse the candidate fields only — this is the status quo and loses data. The map column matches the mental model ("everything the user typed in that application") and requires no schema evolution when fields are added later.

### D2. Master profile = existing `candidates` record

No new "master" table. The `Candidate` is the master: editable via the existing edit form (show.ex:96), identity key for dedup, target for emails and activity. The only addition is `merged_into_id` (self-referential `belongs_to`, nullable) + `merged_at` timestamp for tombstones.

**Important constraint**: do **not** add a unique index on `(tenant_id, email)`. Tombstoned (absorbed) candidates keep their original email, so uniqueness would break the tombstone design. Duplicate-email prevention remains application-level via `find_or_create_candidate`.

### D3. Snapshot written at creation in all three flows

`Pipeline.create_application/1` gains the snapshot: each caller (careers apply, CSV import, manual creation) builds the `anagrafica` from the submitted data (never from the stored candidate). Snapshot is immutable from the moment of creation.

Backfill migration: `UPDATE applications SET anagrafica = jsonb_build_object('name', c.name, 'email', c.email, 'phone', c.phone, 'linkedin_url', c.linkedin_url) FROM candidates c WHERE applications.candidate_id = c.id AND applications.anagrafica IS NULL`. (Historical entered data is unrecoverable; current candidate data is the best available default.)

### D4. Merge = reassign + tombstone + reversible log

`Candidates.merge_candidates(primary, absorbed_list, actor)` runs in a single transaction:

1. Reassign `applications.candidate_id`, `email_threads.candidate_id`, and candidate-level `activity_log` rows (`entity_type = "candidate"` and `entity_id in absorbed_ids`) → `primary.id`.
2. Insert one `candidate_merges` row per absorbed candidate carrying the entity mappings needed for undo:
   `application_mapping %{app_id => original_candidate_id}`, `thread_mapping`, `activity_mapping` (JSONB maps), plus `primary_candidate_id`, `absorbed_candidate_id`, `tenant_id`, `actor_id`, `merged_at`.
3. Set `absorbed.merged_into_id = primary.id`, `absorbed.merged_at = now`.
4. Log an activity event `candidates_merged` on the primary (metadata: absorbed ids).
5. Recompute duplicate flags for applications on the primary (see D8).

Absorbed candidates are **never deleted**. Their custom fields are untouched, so conflict resolution for `custom_fields` is free: the master keeps the primary's values, the absorbed row retains its own, and undo restores everything by reversing the mappings.

**Why a log table instead of just `merged_into_id`?** `merged_into_id` alone cannot answer "which applications belonged to the absorbed candidate" once they are reassigned. The mapping is the undo mechanism. `merged_into_id` is a cheap, indexed pointer for redirects/visibility.

### D5. Undo = reverse the mapping

`Candidates.undo_merge(merge_log_row, actor)` in a transaction:

1. For each entity id in `application_mapping`/`thread_mapping`/`activity_mapping`, set its `candidate_id` back to the recorded original candidate.
2. Clear `merged_into_id`/`merged_at` on the absorbed candidate.
3. Delete the `candidate_merges` row; log `candidates_merge_undone`.

**Chained merges**: `undo_merge` is only offered when the absorbed candidate is not itself a primary of another merge (i.e., it has no dependents — no merge log row where `primary_candidate_id = absorbed.id`). Merging a tombstoned candidate is forbidden until its merge is undone. This keeps chains strict and undo always well-defined.

### D6. Duplicate detection heuristics (suggestion, not auto)

Normalizations:
- email: `String.downcase` + `String.trim`.
- phone: keep digits only, strip leading country code for `+39`/`0039` (locale-aware for the tenant's default, defaulting to Italy).
- name: `String.downcase` + Unicode NFD decomposition (`String.normalize(name, :nfd)`) stripping combining marks + collapse whitespace. Handles accented Italian names (`Ferrè` → `ferre`).

Signals and confidence (per tenant, over non-tombstoned candidates):

| Signal | Confidence | Behavior |
|---|---|---|
| exact normalized email | high | **auto-merge** (safe bug repair) |
| normalized phone equal **and** normalized name equal | high | suggestion |
| normalized name equal **and** same email local-part (different domain) | medium | suggestion |
| name only | — | excluded (false positives) |

Grouping: process signals strongest-first; assign each candidate to at most one group (greedy); a group is meaningful only with ≥ 2 candidates. The merge center lists groups with their confidence and the matching signal; exact-email groups are merged immediately (and logged) rather than awaiting review.

### D7. Primary selection

Default primary = the **first** candidate in the group (oldest by `inserted_at`), per the user's rule ("di default è la prima"). In the merge review the primary (and thus the surviving master anagrafica) is selectable before confirming. Auto (email) merges use the default without a review step.

### D8. Duplicate application to same job: allow but flag

Add `is_duplicate :boolean, default: false` to `applications`. It is set to `true` at creation when another application exists for the same `(candidate_id, job_id)` (self excluded), and recomputed for the primary's applications after each merge (an absorbed candidate's application to a job where the primary already applied becomes a duplicate). The flag drives a badge on the pipeline card and in the applications list.

- **Alternative considered**: compute dynamically via subquery in board queries — avoids denormalization but complicates every application query and the badge logic; the stored flag is simpler and recompute is a cheap, bounded operation.

### D9. Merge center and UI placement

- New LiveView `CandidatesLive.Merge` at `/app/candidates/merge`: duplicate groups, confidence badges, side-by-side data (anagrafica + application counts), primary selector, "Merge" and "Dismiss" per group.
- `CandidatesLive.Index`: a "Duplicates" button with count (navigates to the merge center); bulk selection extended with a "Merge selected into one" action (primary selector modal). `list_candidates` excludes tombstoned candidates (`where: merged_into_id is nil`).
- `CandidatesLive.Show`: merged badge + "Undo merge" (when the profile is a tombstone and its merge is undoable — redirects to the primary on arrival, see D10); per-application anagrafica shown in each application card; duplicate-application badge.
- `PipelineLive.Index` (board): each card shows "Also in N other positions" when the candidate has applications beyond this job (batch query: candidate ids → total application counts).
- Anagrafica snapshot display: when an application's snapshot differs from the current master, show it in the application card (e.g. "as submitted: phone X"); otherwise the master values are shown.

### D10. Redirects for absorbed profiles

`Candidates.get_candidate!` keeps its strict contract. In `CandidatesLive.Show.mount`, after loading the candidate, if `candidate.merged_into_id` is set, `push_navigate` to the primary profile (rendering a brief "this profile was merged" note). The merge center additionally surfaces tombstones with an "Undo" action so a merged profile can be restored before it is permanently hidden. Absorbed candidates are excluded from the candidates list (D9), so their only entry points are stale bookmarks (redirected) or the merge center.

## Risks / Trade-offs

- **False-positive merges** (common names sharing a phone/local-part) → Mitigation: only exact email is automatic; the two suggested signals are always reviewable; undo is always available and lossless.
- **Auto-merge surprise**: merging without review may feel aggressive → Mitigation: auto-merge is limited to identical email (near-certain same person) and is logged with an activity event.
- **Heuristic scan cost**: grouping scans all of a tenant's candidates in memory → Mitigation: ATS scales are modest; run on demand (merge center open / candidates page load) with a per-tenant candidate count guard before running.
- **Backfill fidelity**: historical anagrafica for existing applications is approximated from current candidate data → Mitigation: acceptable and documented; the snapshot mechanism is correct going forward.
- **Tombstone accumulation**: absorbed rows linger → Mitigation: they are invisible in lists, cheap (single row), and required for lossless undo; a future optional hard-delete of old tombstones is possible but explicitly out of scope.
- **Merged candidates' applications to the same job become duplicates** → Mitigation: `is_duplicate` recomputed post-merge (D8) so the team is aware; no data is dropped.
- **Do not add `(tenant_id, email)` unique index** during this change → the tombstone design depends on it staying non-unique (D2).

## Migration Plan

1. **Additive migrations** (deploy-safe, no downtime):
   - `add_anagrafica_to_applications` (nullable map)
   - `add_merged_into_to_candidates` (`merged_into_id`, `merged_at`, both nullable)
   - `add_is_duplicate_to_applications` (default false)
   - `create_candidate_merges`
2. **Backfill** `applications.anagrafica` from current candidate data (same migration or a data migration).
3. **Application code** deploys after migrations; new flows write snapshots; existing code paths keep working (columns nullable/defaulted).
4. **Rollback**: standard migration rollback; any user-initiated merges are reversible in-app via undo. No destructive schema changes.
5. **Verification**: run existing suites plus new tests (see tasks) and `mix precommit`.

## Open Questions

- Should the "update master from application anagrafica" action (explicit, manual) be part of this change or a follow-up? Assumed **follow-up** (kept in non-goals); the snapshot makes it trivially possible later.
- Exact-email auto-merge: should it also update the surviving candidate's anagrafica from the absorbed candidate's (potentially newer) data? Assumed **no** — the master keeps its data; absorbed data remains visible in its snapshots and tombstone.
