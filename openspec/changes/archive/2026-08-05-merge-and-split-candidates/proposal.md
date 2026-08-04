# Merge and Split Candidates

## Why

Candidate history is fragmented. A candidate who applies multiple times (same or different roles, over time) can end up split across several `Candidate` records — different emails, different phones, re-application to the same job — so their full history, notes, interviews and scorecards are scattered. Additionally, today the data a candidate enters for a second application is silently discarded (`find_or_create_candidate` reuses the existing record without storing the newly submitted data). Recruiters need a single, complete profile per person while preserving exactly what each candidate submitted per application.

## What Changes

- **Per-application anagrafica snapshot**: each `Application` stores the contact data (name, email, phone, linkedin) the applicant entered at submission time, as an immutable snapshot. The `Candidate` record becomes the explicit "master" profile — editable, complete, used as internal reference (identity/dedup, emails). Editing the master never rewrites historical snapshots. Existing applications are backfilled from the current candidate data.
- **Candidate merging**: candidates can be merged into a single profile. Applications, email threads and candidate-level activities are reassigned to the surviving candidate. The surviving "master anagrafica" is selectable during the merge (default: the first candidate). All duplicate applications are kept — none are deleted.
- **Duplicate detection heuristics**: simple signals (exact email, normalized phone + name, name + email local-part) suggest likely duplicates. Exact-email matches merge automatically; all other signals are suggestions that require confirmation. Name-only matches are not used.
- **Undo merge / split**: merges are reversible. A `candidate_merges` log records which entities (applications, threads, activities) belonged to which absorbed candidate. Absorbed candidates are kept as tombstones (`merged_into_id`) so no data is lost and old profile URLs redirect to the primary. "Split" is implemented as undo-merge; chained merges are only undoable from the outermost merge.
- **Merged visibility on pipeline board**: application cards indicate when a candidate has other applications (concurrent or historical) so recruiters can see at a glance that a candidate is also active elsewhere.
- **Re-applying to the same job** remains allowed (a new application is created), but the application is flagged as a duplicate of another active application for the same job.

## Capabilities

### New Capabilities
- `candidate-anagrafica`: master candidate profile vs. immutable per-application snapshots of applicant-entered data, including backfill and display.
- `candidate-merging`: duplicate detection heuristics, automatic and suggested merges, manual multi-select merge, undo-merge (split), merge log, redirects and merged visibility.

### Modified Capabilities
- `candidate-management`: candidate profile page reflects merged status; URLs of absorbed candidates redirect to the primary; duplicate detection behavior extended beyond exact email.
- `applications`: application creation snapshots the applicant-entered anagrafica onto the application; duplicate-application flag for the same job.

## Impact

- **Data model**: `applications` gains an `anagrafica` map column; `candidates` gains `merged_into_id` (self-referential, nullable); new `candidate_merges` table (primary/absorbed ids, actor, tenant, merged_at, entity mappings).
- **Contexts**: `Candidates` (merge/undo logic, duplicate detection), `Pipeline` (anagrafica snapshot on create, duplicate flag), `Activities` (reassignment and merge events), new `Candidates.Merges` (or equivalent) for the merge log.
- **Flows**: public career-page apply, CSV import, manual application creation (all snapshot the anagrafica); candidates index (duplicates badge + merge center entry + bulk merge); candidates show (merged badge, undo-merge, snapshot display per application); pipeline board (concurrent-application indicator); new merge-center LiveView.
- **No data loss**: merges never delete candidate rows; absorbed candidates are tombstones enabling undo and redirects.
- **Site documentation**: update `site/features/candidate-management.md` (per-application anagrafica, merge center, undo) and regenerate screenshots with `node scripts/screenshots.mjs` (add a merge-center screenshot def to `scripts/screenshots.mjs`).
