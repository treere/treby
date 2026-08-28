# Message Scheduler

Schedule portal messages for a future time — from stage moves or bulk sends — and manage everything from a dedicated queue page.

![Message Queue](/screenshots/23-message-queue.png)

## Schedule any portal message

Every portal message flow can be sent immediately or scheduled for later:

| Flow | Where |
|---|---|
| **Stage move** | Moving a candidate with a message template: send now, schedule, or skip |
| **Bulk send** | In the candidates list, choose a date and time for the bulk message |

The schedule picker offers presets — **Tomorrow 9:00**, **Tomorrow 14:00**, **Next Monday** — plus a full date/time picker. A jitter option spreads scheduled messages across a time window.

## Message Queue

The **Message Queue** page (in the top navigation) lists every pending, posted, failed, and cancelled message in one place, organized into tabs.

For each queued message you can:

- **Edit** — change the body or the schedule time
- **Post Now** — deliver immediately, skipping the schedule
- **Cancel** — stop a pending message before it goes out

Cancelling is transactional: the message flips to `cancelled`, and if the background job runs anyway the worker sees the new status and no-ops.

## Reliability

- Delivery runs through **Oban** with exponential backoff on failure (1min, 4min, 15min, 60min)
- After 5 failed attempts the message is marked **failed** with the error reason recorded, and you can retry it manually
- Between attempts the message stays **scheduled**, so it can still be edited or cancelled

## Technical Details

- One `scheduled_messages` row per recipient conversation (bulk sends create one row per candidate, each independently manageable)
- `send_at` is the real posting time after jitter
- The Oban worker runs at `send_at`, not the time you originally chose