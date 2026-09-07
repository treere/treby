## 1. Observable Notifications

- [x] 1.1 Replace `rescue/catch → :ok` in `move_application` with `Logger.warning` (application id + error) and `:telemetry.execute([:treby, :pipeline, :notify_failed], ...)`; move still returns `{:ok, app}`
- [x] 1.2 Add test: failing `notify_stage_change` keeps the move successful and logs the warning

## 2. Race-Safe Detach

- [x] 2.1 Wrap `detach_job_pipeline` check + clone + remap + repoint in `Repo.transaction` with `FOR UPDATE` lock on the pipeline row
- [x] 2.2 Add test: detach under a concurrent attach leaves the shared pipeline unmutated and the job on a clone

## 3. Duplicate Flags Single Write

- [x] 3.1 Merge reset + conditional set in `recompute_duplicate_flags` into one `update_all` with `CASE WHEN id IN ^dup_ids`
- [x] 3.2 Assert existing duplicate-flag tests still pass (semantics unchanged)

## 4. Preloaded Candidate Opt

- [x] 4.1 Accept `opts[:candidate]` in `create_application`/`ensure_anagrafica`; pass it from callers that hold the record
- [x] 4.2 Add test: creation with preloaded candidate issues no candidate fetch

## 5. Job Visible/Status Validation

- [x] 5.1 Add `validate_visible_requires_open` to `Job` changeset; add tests for closed+visible rejection and open+visible acceptance

## 6. Import Hoisting

- [x] 6.1 Hoist function-level `import Ecto.Query` to module top in `candidates_live/show.ex`, `jobs_live/index.ex`, `jobs_live/show.ex`

## 7. Verification

- [x] 7.1 Run `mix test` (expect all passing, zero warnings)
- [x] 7.2 Run `mix precommit` (expect EXIT 0)
- [x] 7.3 Run `openspec validate --all` (expect all valid)
