
# Email Scheduler

Schedule email delivery for a future time — from a candidate thread, bulk sends, or stage moves — and manage everything from a dedicated queue page.

![Email Queue](/screenshots/23-email-queue.png)

## Schedule any email

Every outbound email flow in Treby can be sent immediately or scheduled for later:

| Flow | How it works |
|---|---|
| **Compose / reply** | Open the composer on a candidate's thread and pick **Schedule** |
| **Bulk send** | In the candidates list, choose a date and time for the bulk email |
| **Stage move** | Moving a candidate to a new stage can trigger a delayed notification |

The schedule picker offers natural-language presets — **Tomorrow 9:00**, **Tomorrow 14:00**, **Next Monday** — plus a full date/time picker for custom times.

## Jitter

When spreading a bulk send over time, enable **±5 min** (up to ±15 min). Each recipient gets a slightly different send time within the window, computed at scheduling time:

- `scheduled_at` stores the time you chose
- `send_at` is the real delivery time after jitter, shown in the queue as a range (e.g., `Jul 31, 2026 06:19 ±5m`)
- The Oban job runs at `send_at`, not `scheduled_at`

## Email Queue

The **Email Queue** page (in the top navigation) lists every pending, sent, failed, and cancelled email in one place, organized into tabs.

For each queued email you can:

- **Edit** — change the subject, body, or schedule time (recipient is fixed)
- **Send Now** — deliver immediately, skipping the schedule
- **Cancel** — stop a pending email before it goes out

Cancelling is transactional: the scheduled email flips to `cancelled`, the thread message is updated, and if the background job runs anyway the worker sees the new status and no-ops — so a cancellation is never followed by a late send.

## Retries & backoff

Delivery happens in a background Oban worker. If the mail adapter fails, Treby retries automatically with exponential backoff:

| Attempt | Delay after failure | Cumulative |
|---|---|---|
| 1 | 0 | 0 |
| 2 | ~1 min | ~1 min |
| 3 | ~4 min | ~5 min |
| 4 | ~15 min | ~20 min |
| 5 | ~60 min | ~1 h 20 min |

After 5 failed attempts the email is marked **failed** with the error reason recorded, and you can retry it manually from the queue page. Between attempts the email stays **scheduled**, so it can still be edited or cancelled.

## Technical Details

- Backed by [Oban](https://hexdocs.pm/oban), which uses `SELECT … FOR UPDATE SKIP LOCKED` for safe multi-node execution — no double sends, no lost jobs
- One `scheduled_emails` row per recipient (bulk sends create one row per candidate, each independently manageable)
- Scheduled messages appear in the candidate's thread immediately, marked as pending until delivered
