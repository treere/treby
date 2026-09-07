## Context

`Treby.Pipeline.Applications.move_application/3` wraps the post-move notification email in `try/rescue/catch → :ok` (`applications.ex:489-498`), so mail failures are invisible in logs and metrics. `Stages.detach_job_pipeline/1` (`stages.ex:259-278`) reads `pipeline_shared?/1` then clones + remaps without holding a lock, so a concurrent job attach between check and clone leaves the new job on the old shared pipeline. Smaller gaps: `recompute_duplicate_flags/1` issues reset + conditional set as two `update_all`s; `ensure_anagrafica/1` re-fetches the candidate per row even when callers hold it; `Job` allows `visible=true` with `status="closed"`. Three LiveViews still use function-level `import Ecto.Query`.

## Goals / Non-Goals

**Goals:** Make notification failures observable; close the detach race; halve duplicate-flag writes; skip redundant candidate fetch; enforce visible/status coherence; hoist remaining imports.

**Non-Goals:** No retry/backoff on notification mail (out of scope — observability first, retry policy later); no backfill or detect-task for legacy closed+visible rows; no telemetry dashboard (PromEx alerts are a separate §7 item).

## Decisions

1. **Log + telemetry, still non-blocking.** `rescue e -> Logger.warning("[pipeline] notify_stage_change failed", application_id: ..., error: Exception.message(e)))` plus `:telemetry.execute([:treby, :pipeline, :notify_failed], %{count: 1}, %{application_id: ...})`; return value stays `{:ok, app}`. Rationale: preserves the "email never blocks a move" contract while making failures greppable and countable. Alternative (let it crash / return error): rejected — a mail outage must not break Kanban drag-and-drop.
2. **`Repo.transaction` + `FOR UPDATE` lock on the pipeline row in `detach_job_pipeline`.** Lock ordering: pipeline row first, then read `pipeline_shared?`, clone, remap, update job — all inside one transaction. Rationale: minimal, Postgres-native; advisory locks rejected as less discoverable. `pipeline_shared?` counts active jobs by `pipeline_id`; the lock serializes concurrent `update_job(%{pipeline_id: ...})` attach paths that write the same pipeline row... note: attaches write the *job* row, not the pipeline row, so strict serialization requires locking the jobs of that pipeline too — design locks the pipeline row AND re-checks sharing after clone within the same transaction (check-then-act stays atomic for the detach path; concurrent attachers landing between check and commit attach to the old pipeline, which remains valid — the invariant "a shared pipeline is never mutated" holds because detach clones instead of mutating).
3. **Single `update_all` with `CASE WHEN id IN ^dup_ids`.** `from(a in Application, where: a.candidate_id == ^cid) |> update_all(set: [is_duplicate: fragment("CASE WHEN ? THEN true ELSE false END", a.id in ^dup_ids)])` — with empty `dup_ids` the `IN ()` degrades to all-false, so the conditional second query disappears entirely. Rationale: one round-trip, same semantics.
4. **Opt-in `:candidate` param, not a signature change.** `create_application(attrs, opts)` already takes opts (`skip_notification`, `actor`); add `opts[:candidate]` consumed by `ensure_anagrafica`. Callers updated where the record is in hand (notably the LiveView apply flows); others keep the lazy fetch. Rationale: zero churn, no behavior change for existing callers.
5. **Changeset-only validation for visible/status.** `validate_visible_requires_open` adds an error on `:visible` when `status == "closed"` and `visible == true` (covers both string/atom keys via `get_field`). Rationale: DB constraint rejected — would need a migration + backfill decision for legacy rows; changeset validation blocks new incoherence with zero migration.
6. **Hoist the 3 LiveView imports to module top-level** (`import Ecto.Query` once per module). Rationale: consistency with the context-layer cleanup; zero behavior change.

## Risks / Trade-offs

- [Risk] `FOR UPDATE` on a hot pipeline row could serialize concurrent detaches → Mitigation: detaches are rare admin ops, lock held for one short transaction; acceptable.
- [Risk] New visible/status validation breaks an existing form flow that toggles visible on closed jobs → Mitigation: suite covers job forms; any failure surfaces in `mix test` before merge.
- [Risk] `fragment` CASE with UUID `IN` list on Postgres → Mitigation: standard Ecto pattern; covered by existing `recompute_duplicate_flags` tests.
- [Risk] Telemetry event with no attached handler is a no-op → Mitigation: that is the point (hook for future PromEx §7 work); log line is the immediate observability win.

## Migration Plan

Single commit, no migration. Deploy normally; rollback = revert. Verify via `mix test` (existing notify/detach/recompute/job tests must stay green) + new tests per delta spec.

## Open Questions

- None blocking. Follow-up (not this change): retry/backoff policy for notification mail; PromEx counter alert on `[:treby, :pipeline, :notify_failed]`.
