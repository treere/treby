# Bulk Operations

Act on many candidates at once from the candidates list (`/app/candidates`) and the job workspace.

Powered by `lib/treby/bulk_operations/bulk_operations.ex`.

## Supported actions

| Action | What it does | Notes |
|---|---|---|
| **Move stage** | Move selected applications to another `pipeline_stage_id` | `BulkOperations.bulk_move_stage/4`, tenant-scoped |
| **Mark reviewed / unreviewed** | Toggle the `reviewed` flag | `bulk_mark_reviewed/2`, `bulk_mark_unreviewed/2` — drives the **NEW** badge on cards |
| **Bulk message** | Post a portal message to each selected candidate | Creates one `ScheduledMessage` per conversation — send now, schedule, or skip via the template picker; see [Message Scheduler](/features/message-scheduler) |
| **Merge into one** | Merge selected candidate profiles | Picks a primary; see [Candidate Management](/features/candidate-management) |
| **Delete** | Delete applications (and orphaned candidates) | `bulk_delete_candidates/2` removes applications and auto-deletes a candidate when it has no remaining applications |

Selection is via checkboxes on `CandidatesLive.Index`; the bulk bar appears when at least one row is selected. Bulk moves broadcast pipeline updates via `Phoenix.PubSub` just like single moves.

## Scheduling

Bulk messages reuse the same scheduling picker as stage moves — **Tomorrow 9:00**, **Tomorrow 14:00**, **Next Monday** presets plus a full datetime picker, with optional **jitter** that spreads delivery across a window. Each recipient gets an independent `scheduled_messages` row that can be edited/cancelled from the **Message Queue** (`/app/messages-queue`).

## Technical

- All bulk writes are scoped by `tenant_id` — you can only act on applications you can see
- Counts and remaining-candidate cleanup are done in the repo layer, not the LiveView
