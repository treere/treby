## 1. Setup & Dependencies

- [x] 1.1 Add `oban` dependency to `mix.exs` and run `mix deps.get`
- [x] 1.2 Add Oban configuration to `config/config.exs`, `config/dev.exs`, `config/test.exs`, `config/runtime.exs`
- [x] 1.3 Add Oban to the supervision tree in `lib/treby/application.ex`
- [x] 1.4 Generate Oban migration with `mix oban.gen.migration`

## 2. Database

- [x] 2.1 Generate migration for `scheduled_emails` table (tenant_id, created_by_id, status, scheduled_at, send_at, jitter_minutes, to_address, from_address, subject, body, html_body, email_type, reference_type, reference_id, thread_id, sent_at, failed_at, error_reason, retry_count, timestamps)
- [x] 2.2 Generate migration to add `status`, `scheduled_at`, and `scheduled_email_id` columns to `email_messages`
- [x] 2.3 Create `Treby.EmailQueue.ScheduledEmail` Ecto schema
- [x] 2.4 Migrate the database with `mix ecto.migrate`

## 3. Core Context: EmailQueue

- [x] 3.1 Create `Treby.EmailQueue` context module with functions: `list_queued/1`, `list_sent/1`, `list_failed/1`, `list_cancelled/1`, `get_scheduled_email!/1`
- [x] 3.2 Add `create_scheduled_email/1` with support for jitter calculation
- [x] 3.3 Add `cancel_scheduled_email/1` — updates status to cancelled, updates linked email_message
- [x] 3.4 Add `edit_scheduled_email/2` — updates subject, body, and/or scheduled_at (reschedules Oban job)
- [x] 3.5 Add `force_send/1` — updates send_at to now, inserts new Oban job for immediate execution
- [x] 3.6 Add `delete_scheduled_email/1` — hard deletes the record and linked email_message
- [x] 3.7 Add `retry_failed/1` — resets status to scheduled, inserts new Oban job

## 4. Oban Worker

- [x] 4.1 Create `Treby.Workers.SendScheduledEmail` using `Oban.Worker` with `max_attempts: 5`
- [x] 4.2 Implement `perform/1`: load scheduled_email, check status, call Mailer.deliver, update status to sent/failed, update linked email_message
- [x] 4.3 Configure queue `:email` in Oban config with appropriate `max_concurrency`
- [x] 4.4 Add retry backoff: exponential from 60s to ~3600s over 5 attempts

## 5. Modify EmailThreads Context

- [x] 5.1 Modify `create_outbound_email/1` to accept an optional schedule parameter; when present, create scheduled email + scheduled message instead of sending immediately
- [x] 5.2 Modify `send_reply/4` similarly with optional schedule parameter
- [x] 5.3 Update `email_thread` queries to include status-based filtering for scheduled messages
- [x] 5.4 Create `update_email_message_status/2` for Oban worker callback to update message after delivery
- [x] 5.5 Update `email_message` schema to include new fields: `status`, `scheduled_at`, `scheduled_email_id`

## 6. Modify BulkOperations Context

- [x] 6.1 Modify `bulk_send_email/4` to accept an optional schedule parameter (scheduled_at, jitter)
- [x] 6.2 When scheduling, iterate candidates and create individual scheduled_email records + Oban jobs
- [x] 6.3 Return summary with sent/scheduled counts

## 7. Modify Stage Move Flow (PipelineLive)

- [x] 7.1 Update stage move confirmation dialog to add "Schedule" button alongside "Send Now" and "Skip"
- [x] 7.2 Add schedule picker component to the dialog with presets and custom time
- [x] 7.3 On schedule: move candidate immediately, create scheduled email for template delivery
- [x] 7.4 Wire up the flow: `confirm_stage_move` handling for schedule action

## 8. Email Queue LiveView

- [x] 8.1 Create `TrebyWeb.EmailQueueLive.Index` LiveView
- [x] 8.2 Add tabbed interface: In Coda / Inviate / Fallite / Annullate
- [x] 8.3 Implement queued tab: list scheduled emails with actions (Edit, Send Now, Cancel)
- [x] 8.4 Implement sent tab: list sent emails with metadata (read-only)
- [x] 8.5 Implement failed tab: list failed emails with error reason, actions (Retry, Delete)
- [x] 8.6 Implement cancelled tab: list cancelled emails, actions (Send Now, Delete)
- [x] 8.7 Add edit modal: edit subject, body, schedule time (not recipient)
- [x] 8.8 Add bulk selection and bulk actions (send selected, cancel selected)
- [x] 8.9 Add route `/app/email-queue` to the router inside authenticated scope

## 9. Schedule Picker Component

- [x] 9.1 Create schedule picker LiveComponent with preset buttons: "Domani 9:00", "Domani 14:00", "Lunedì", "Prossima settimana..."
- [x] 9.2 Add custom date/time picker fallback
- [x] 9.3 Add jitter toggle with configurable range
- [x] 9.4 Integrate picker into compose form, reply form, bulk send dialog, and stage move dialog

## 10. Thread Display for Scheduled Messages

- [x] 10.1 Add visual indicator for scheduled messages in email thread (clock icon, dashed border)
- [x] 10.2 Add visual indicator for cancelled messages in email thread
- [x] 10.3 Show scheduled time on pending messages
- [x] 10.4 Ensure scheduled/cancelled messages appear in chronological order

## 11. Documentation

- [x] 11.1 Create `site/features/email-scheduler.md` with feature description, screenshots, and walkthrough
- [x] 11.2 Regenerate screenshots with `node scripts/screenshots.mjs`
- [x] 11.3 Verify docs build: `cd site && npm run build`

## 12. Tests

- [x] 12.1 Test `Treby.EmailQueue` context: create, list, cancel, edit, force_send, delete, retry
- [x] 12.2 Test `Treby.Workers.SendScheduledEmail`: successful delivery, cancellation before execution, retry exhaustion
- [x] 12.3 Test modified `Treby.EmailThreads`: schedule on compose, schedule on reply, thread message status
- [x] 12.4 Test modified `Treby.BulkOperations`: schedule bulk send with jitter
- [x] 12.5 Test `EmailQueueLive.Index`: tab rendering, edit modal, bulk actions
- [x] 12.6 Test schedule picker presets compute correct dates
- [x] 12.7 Test stage move dialog with scheduling (PipelineLive)
- [x] 12.8 Verify all existing email tests still pass (no regression on immediate sends)
