## 1. Broadcast

- [x] 1.1 Add `Phoenix.PubSub.broadcast` in `Treby.Interviews.complete_interview/2` on `pipeline:#{job_id}`
- [x] 1.2 Verify `PipelineLive.Index` `handle_info {:pipeline_updated}` already reloads applications (no change)

## 2. Tests

- [x] 2.1 Manual Playwright: schedule interview, `Mark as completed` → card shows `Ready to advance` without reload; verify second session receives update

## 3. Polish

- [x] 3.1 Run `openspec validate --strict` and `mix precommit`
