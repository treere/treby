# Tasks: Merge and Split Candidates

## 1. Data Model & Migrations

- [x] 1.1 Generate migration `add_anagrafica_to_applications` adding nullable `anagrafica` map column to `applications`
- [x] 1.2 Generate migration `add_merged_into_to_candidates` adding nullable self-referential `merged_into_id` and `merged_at` to `candidates`
- [x] 1.3 Generate migration `add_is_duplicate_to_applications` adding `is_duplicate` boolean defaulting to false
- [x] 1.4 Generate migration `create_candidate_merges` (primary_candidate_id, absorbed_candidate_id, tenant_id, actor_id, merged_at, application_mapping, thread_mapping, activity_mapping) with indexes
- [x] 1.5 Backfill migration: populate `applications.anagrafica` from the current candidate data (name, email, phone, linkedin_url)
- [x] 1.6 Add `field :anagrafica, :map` and `field :is_duplicate, :boolean` to `Treby.Pipeline.Application`; add `belongs_to :merged_into, Treby.Candidates.Candidate` (module override) and `field :merged_at` to `Treby.Candidates.Candidate`
- [x] 1.7 Add `Treby.Candidates.MergeLog` schema for `candidate_merges`

## 2. Anagrafica Snapshot

- [x] 2.1 Update `Pipeline.create_application/1` to accept and store the `anagrafica` snapshot
- [x] 2.2 `CareersLive.Apply`: build the snapshot from submitted form data (name, email, phone) and pass it when creating the application
- [x] 2.3 `CsvImport.execute_import/5`: build the snapshot from the imported row and pass it when creating the application
- [x] 2.4 Manual application creation path (admin add candidate to job): snapshot from the candidate's current master data
- [x] 2.5 Verify snapshot immutability: candidate `update_candidate` never touches `applications.anagrafica`

## 3. Merge Core Logic

- [x] 3.1 Add `Candidates.merge_candidates(primary, absorbed_list, actor)` executing in a transaction: reassign applications, email threads, and candidate-level activity log rows to the primary; insert `candidate_merges` rows with entity mappings; set tombstones on absorbed candidates; log `candidates_merged` activity event
- [x] 3.2 Add `Candidates.undo_merge(merge_log_row, actor)` executing in a transaction: reverse entity mappings, clear tombstones, delete the merge log row, log `candidates_merge_undone`
- [x] 3.3 Enforce guardrails: refuse merging tombstoned candidates; only allow undoing the outermost merge in a chain
- [x] 3.4 Add `Candidates.list_candidates/2` to exclude tombstoned candidates (`merged_into_id is nil`) and add `Candidates.get_candidate!/2` kept strict for active candidates
- [x] 3.5 Add `Candidates.list_duplicate_groups(tenant_id)` returning suggested merge groups with confidence, matching signal, and candidates
- [x] 3.6 Implement normalization helpers (email lower/trim; phone digits-only with leading +39/0039 stripped; name NFD accent-strip + lowercase + whitespace collapse)
- [x] 3.7 Implement grouping algorithm: strongest-signal-first greedy assignment, at most one group per candidate; exact-email groups auto-merge, others are suggestions

## 4. Duplicate Application Flag

- [x] 4.1 Set `is_duplicate` to true at application creation when another application exists for the same `(candidate_id, job_id)` (self excluded)
- [x] 4.2 Add helper to recompute duplicate flags for a candidate's applications; call it after every merge

## 5. Redirects & Visibility

- [x] 5.1 `CandidatesLive.Show.mount`: when the candidate is absorbed, `push_navigate` to the primary profile with a merged notice
- [x] 5.2 Pipeline board cards: batch query of total application counts per candidate; show "Also in N other positions" when the candidate has applications beyond the current job
- [x] 5.3 Show duplicate-application badge on pipeline cards and in the candidate profile applications list

## 6. UI

- [x] 6.1 New `CandidatesLive.Merge` LiveView at `/app/candidates/merge`: list duplicate groups with confidence badges, side-by-side anagrafica and application counts, primary selector, Merge and Dismiss actions
- [x] 6.2 `CandidatesLive.Index`: "Duplicates" button with count linking to the merge center; bulk action "Merge into one" with a primary picker modal
- [x] 6.3 `CandidatesLive.Show`: merged badge and "Undo merge" action (when undoable); per-application anagrafica display ("as submitted" when it differs from the master); duplicate-application badge
- [x] 6.4 Wire routes for the merge center in the router (authenticated live_session)

## 7. Tests

- [x] 7.1 Context tests: `merge_candidates` reassigns applications/threads/activities and tombstones absorbed candidates; no rows deleted
- [x] 7.2 Context tests: `undo_merge` restores all entities and re-activates the absorbed candidate; chained-merge guardrails
- [x] 7.3 Context tests: duplicate detection normalization and grouping (email, phone+name, name+local-part, name-only exclusion)
- [x] 7.4 Context tests: anagrafica snapshot written on career apply, CSV import, and manual creation; immutability on master edit
- [x] 7.5 Context tests: `is_duplicate` set on re-application and recomputed after merge
- [x] 7.6 LiveView tests: merge center lists groups, merge and dismiss actions; candidates index duplicates badge; absorbed profile redirects; undo merge flow
- [x] 7.7 LiveView tests: pipeline board concurrent-application indicator; duplicate-application badge

## 8. Documentation

- [x] 8.1 Update `site/features/candidate-management.md` with per-application anagrafica, merge center, undo merge, and concurrent-application visibility
- [x] 8.2 Add a merge-center screenshot definition to `scripts/screenshots.mjs` (and extend candidate detail/list defs if layouts changed)
- [x] 8.3 Regenerate screenshots with `node scripts/screenshots.mjs` and verify the candidate-management feature page renders correctly with `cd site && npm run build`
- [x] 8.4 Run `mix precommit` and fix any pending issues
