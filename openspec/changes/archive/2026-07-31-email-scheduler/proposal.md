## Why

Email sending in Treby is entirely synchronous and immediate — every email goes out the moment it's composed. There's no way to schedule sends for a later time, no queue to review pending emails, and no visibility into failures beyond scattered activity log entries. As Treby grows to handle bulk campaigns and time-sensitive communications, recruiters need the ability to schedule emails, manage the queue, and recover from failures without losing track of what was sent or why.

## What Changes

- Add Oban as a background job processor for reliable, multi-node safe scheduled email delivery
- New `scheduled_emails` database table to track all planned, sent, failed, and cancelled emails
- New `EmailQueue` context with CRUD for scheduled emails (create, edit, cancel, delete, retry, force-send)
- New Oban worker (`Workers.SendScheduledEmail`) that performs delivery with retry logic
- Add `status` and `scheduled_at` fields to `email_messages` so scheduled emails appear in threads
- Restructure outbound email flows to optionally schedule instead of sending immediately:
  - **Compose new email** in candidate thread — schedule or send now
  - **Reply** in candidate thread — schedule or send now
  - **Bulk send email** to candidates — schedule or send now
  - **Stage change email dialog** — schedule or send now
- New `/app/email-queue` page for managing the queue (queued, sent, failed, cancelled tabs)
- Quick-schedule presets ("Tomorrow 9:00", "Next Monday", etc.) + custom date/time picker
- Configurable jitter (±N minutes) to scatter send times
- Oban retry: 5 attempts with exponential backoff (1min → ~4min → ~15min → ~60min)
- Historical view: all sent emails with metadata (to whom, why, content)
- Site documentation updated with new email queue feature pages and screenshots
- **Transactional emails (password reset, team invites) remain immediate** — no change

## Capabilities

### New Capabilities
- `email-scheduler`: Core scheduled email system — queue management, delivery via Oban with retry, jitter support

### Modified Capabilities
- `bidirectional-email`: Email messages gain a `status` field (sent/scheduled/cancelled); scheduled messages appear in threads with an indicator; compose/reply flows gain a schedule option
- `bulk-operations`: Bulk send email flow gains a schedule option alongside immediate send
- `stage-email-templates`: Stage move email dialog gains a schedule option alongside immediate send/skip

## Impact

- **New dependency**: `oban` (Postgres-backed job processor)
- **New DB tables**: `scheduled_emails`; migration to add `status` and `scheduled_at` to `email_messages`
- **New context**: `Treby.EmailQueue` with associated tests
- **New Oban worker**: `Treby.Workers.SendScheduledEmail`
- **Modified contexts**: `Treby.EmailThreads` (schedule support in compose/reply), `Treby.BulkOperations` (schedule support), `Treby.EmailTemplates` (schedule support in stage send)
- **New LiveView**: `TrebyWeb.EmailQueueLive.Index` at `/app/email-queue`
- **Modified LiveViews**: `CandidatesLive.Show` (schedule in compose/reply), `CandidatesLive.Index` (schedule in bulk), `PipelineLive.Index` (schedule in stage dialog)
- **Documentation**: New feature page in `site/features/email-scheduler.md`
- **Supervision tree**: Oban must be added to the application's supervision tree
- **Config**: Oban configuration in all environments (dev/test/prod)
