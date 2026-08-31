# Message Scheduler

Schedule portal messages for a future time — from stage moves or bulk sends — and manage everything from a dedicated queue page.

![Message Queue](/screenshots/23-message-queue.png)

## Schedule Any Portal Message

Every portal message flow can be sent immediately or scheduled for later:

| Flow | Where |
|---|---|
| **Stage move** | Moving a candidate with a message template: send now, schedule, or skip |
| **Bulk send** | In the candidates list, choose a date and time for the bulk message |

The schedule picker offers presets — **Tomorrow 9:00**, **Tomorrow 2:00 PM**, **Next Monday** — plus a full date/time picker. A jitter option spreads scheduled messages across a time window.

## Message Queue

The **Message Queue** page (in the top navigation) lists every pending, posted, failed, and cancelled message in one place, organized into tabs.

For each queued message you can:

- **Edit** — change the body or the schedule time
- **Post Now** — deliver immediately, skipping the schedule
- **Cancel** — stop a pending message before it goes out

If you cancel a message, it will no longer be sent even if delivery was already scheduled.

## Reliability

- If sending fails, Treby retries automatically with increasing delays (about 1, 4, 15, and 60 minutes)
- After 5 failed attempts the message is marked as **failed** with the error reason and you can retry manually
- While pending, the message remains editable or cancellable

## Useful Details

- In bulk sends each candidate receives an independent scheduled message — you can edit one without affecting the others
- The actual delivery time accounts for any random jitter you selected
