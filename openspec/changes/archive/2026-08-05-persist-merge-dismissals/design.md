## Context

The merge center (`TrebyWeb.CandidatesLive.Merge`) detects duplicate candidate groups via `Candidates.list_duplicate_groups/1`. Each group has a deterministic id: a SHA-256 hex hash of the sorted member candidate ids. Dismissals were tracked in an in-memory `MapSet` assigned on mount, so they never survived a page reload, and the candidates index (`TrebyWeb.CandidatesLive.Index`) computed its "Duplicates" badge without accounting for dismissals.

## Goals / Non-Goals

**Goals:**
- Persist dismissed merge-suggestion groups per tenant so they stay hidden across page loads.
- Make the candidates-list "Duplicates" badge reflect dismissed groups.
- Keep dismissal idempotent and tenant-scoped, recording who dismissed.

**Non-Goals:**
- Restoring/undoing a dismissal from the UI (no "show dismissed" view).
- Per-user dismissal visibility — a dismissal is a shared, tenant-wide decision on the merge center.
- Changes to duplicate detection heuristics.

## Decisions

### Persist dismissals in a dedicated `dismissed_merge_groups` table
Rows hold `tenant_id`, `group_key` (the deterministic group id string), optional `dismissed_by` (user id, `:nilify_all` on delete), and `dismissed_at`. A unique index on `(tenant_id, group_key)` makes dismissal idempotent via `on_conflict: :nothing`.

- *Why a table instead of a column/flag on candidates?* A suggestion group is a set of 2+ candidates, not a single row; a per-group key maps 1:1 to suggestions and stays stable as long as the member set is unchanged.
- *Why not a per-user row?* The merge center is a shared curation surface; dismissing a suggestion is a team decision. `dismissed_by` is kept for audit.

### Stable dismissal key
`group.id` (SHA-256 over sorted candidate ids) is the persistence key. If the member set later changes (e.g., a third candidate joins), a new hash forms and a fresh suggestion appears — the stale dismissal row is harmless and simply never matches again.

### Centralized dismissal-aware listing
`Candidates.list_suggestion_groups/1` filters `list_duplicate_groups/1` against `Candidates.list_dismissed_group_keys/1` (a `MapSet` loaded once). Both the merge center and the candidates index use it, so filtering lives in one place.

## Risks / Trade-offs

- **Stale dismissal rows** for groups that no longer exist (e.g., after a merge) accumulate → Mitigation: rows are tiny and per-tenant; they stop matching as soon as the member set changes. Acceptable without cleanup.
- **Tenant-wide dismissal hides a suggestion for all users** → Mitigation: intentional decision matching the shared merge center; `dismissed_by` provides an audit trail.
- **Concurrent mount race** (two dismissals same group) → Mitigation: unique index + `on_conflict: :nothing` makes it safe.
