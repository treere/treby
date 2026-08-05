## 1. Data model

- [x] 1.1 Generate migration `create_dismissed_merge_groups` (table + unique index on `tenant_id`, `group_key`)
- [x] 1.2 Add `Treby.Candidates.DismissedMergeGroup` schema with `tenant_id`, `group_key`, `dismissed_by`, `dismissed_at` and unique constraint
- [x] 1.3 Run the migration

## 2. Context functions

- [x] 2.1 Add `Candidates.list_dismissed_group_keys/1` returning a `MapSet` of group keys
- [x] 2.2 Add `Candidates.dismiss_merge_group/3` with idempotent insert (`on_conflict: :nothing`)
- [x] 2.3 Add `Candidates.list_suggestion_groups/1` filtering dismissed groups out of `list_duplicate_groups/1`

## 3. LiveViews

- [x] 3.1 Merge center loads dismissals on mount and persists on the `dismiss_group` event
- [x] 3.2 Candidates index badge counts `list_suggestion_groups/1` (excludes dismissed groups)

## 4. Tests

- [x] 4.1 Context tests: persistence, idempotency, tenant scoping, dismissal hides suggestion groups
- [x] 4.2 LiveView test: dismissal persists across page reloads
- [x] 4.3 LiveView test: dismissed groups excluded from the duplicates badge

## 5. Verification

- [x] 5.1 `mix precommit` passes with no failures
