## Context

Today, every email in Treby is sent synchronously via `Treby.Mailer.deliver/1`. There are 10 call sites spread across the codebase, each building a `%Swoosh.Email{}` and delivering it inline — blocking the LiveView handler until the adapter responds. There is no background job system, no retry logic, and no persistent queue.

The existing `email_messages` table stores only sent/received messages with no notion of pending or scheduled state. The `email_threads` and `email_messages` schemas have no status field.

The app runs on PostgreSQL. Multi-node deployment is expected. No background job library is currently installed.

## Goals / Non-Goals

**Goals:**
- Enable users to schedule email delivery for a future time (compose, reply, bulk, stage move)
- Provide a queue management UI to view, edit, cancel, retry, and force-send scheduled emails
- Scheduled emails appear in the candidate's thread with a "pending" indicator
- Survive multi-node deployment with no race conditions (no double-send, no lost jobs)
- 5 retries with exponential backoff on delivery failure
- Configurable jitter to scatter bulk send times
- Track full history: sent, failed, cancelled with metadata

**Non-Goals:**
- Changing existing immediate transactional flows (password reset, team invites, automatic notifications)
- Outbound threading headers (In-Reply-To, References) — pre-existing gap, not in scope
- Bulk send progress reporting beyond "X sent, Y failed" summary
- User-level rate limiting or throttling
- Dead letter queue UI — failed emails visible in the queue manager with manual retry instead

## Decisions

### Background job processor: Oban

**Decision**: Use Oban over a custom GenServer-based poller.

**Alternatives considered:**
- **GenServer + Ecto poller**: Poll `scheduled_emails` every N seconds, lock rows with `FOR UPDATE SKIP LOCKED`. Viable but: no built-in retry backoff, no job-level scheduling precision, no uniqueness guarantees, and each node needs careful coordination. Oban gives all of this for free.
- **Quantum + Task.Supervisor**: Quantum handles cron-like scheduling but not one-off delayed jobs. Would need significant custom orchestration.
- **Broadway**: Optimized for message consumption, not scheduled jobs.

**Rationale**: Oban is the de-facto standard for PostgreSQL-backed job processing in Elixir. It uses `FOR UPDATE SKIP LOCKED` internally for multi-node safety, supports `scheduled_at` for precise timing, has built-in retry with configurable backoff, and integrates cleanly with Phoenix supervision trees.

### Data model: Single scheduled_emails table + email_messages status field

```
scheduled_emails
├── id                    uuid (PK)
├── tenant_id             FK → tenants
├── created_by_id         FK → users (who scheduled it)
├── status                scheduled | sending | sent | failed | cancelled
├── scheduled_at          utc_datetime (user's desired time, pre-jitter)
├── send_at               utc_datetime (actual time after jitter, used by Oban)
├── jitter_minutes        integer (0 = no jitter)
├── to_address            string
├── from_address          string
├── subject               string
├── body                  text (plain text)
├── html_body             text
├── email_type            compose | reply | bulk | stage_change
├── reference_type        candidate | application | thread
├── reference_id          integer
├── thread_id             FK → email_threads (nullable)
├── sent_at               utc_datetime (nullable)
├── failed_at             utc_datetime (nullable)
├── error_reason          text (nullable)
├── retry_count           integer (default 0)
└── timestamps            inserted_at, updated_at

email_messages (modified)
├── ...existing fields...
├── status                sent | scheduled | cancelled  ← NEW
├── scheduled_at          utc_datetime (nullable)       ← NEW
├── scheduled_email_id    FK → scheduled_emails (nullable) ← NEW
```

This approach keeps the queue separate from the thread log while maintaining a clean FK link. The `email_messages` row is created at scheduling time (so the message appears in the thread immediately) but starts as `status = scheduled`. When Oban delivers it, the status flips to `sent`. If the user cancels, it flips to `cancelled`.

### Oban worker: SendScheduledEmail

```elixir
defmodule Treby.Workers.SendScheduledEmail do
  use Oban.Worker,
    queue: :email,
    max_attempts: 5

  @impl Oban.Worker
  def perform(%Oban.Job{args: %{"scheduled_email_id" => id}}) do
    # 1. Load scheduled_email
    # 2. Check status is still "scheduled" (might have been cancelled)
    # 3. Mailer.deliver()
    # 4. On success: update scheduled_email.status = "sent",
    #    update email_messages.status = "sent",
    #    log activity
    # 5. On failure: update scheduled_email.error_reason,
    #    increment retry_count; Oban handles retry
  end
```

**Backoff strategy (exponential):**
```
attempt | delay   | cumulative
──────────────────────────────
  1     |    0    |     0
  2     |  ~1 min |    ~1m
  3     |  ~4 min |    ~5m
  4     | ~15 min |   ~20m
  5     | ~60 min | ~1h 20m
```

After 5 failed attempts, status → `failed`. User can manually retry.

### Jitter implementation

When a user selects "±5 min":
1. `scheduled_emails.scheduled_at` stores the user's exact desired time (e.g., 09:00)
2. `send_at` = `scheduled_at + :rand.uniform(2 * jitter_minutes * 60) - jitter_minutes * 60`
3. Oban job is scheduled at `send_at`, not `scheduled_at`
4. The queue UI shows `scheduled_at` to the user (the "ideal" time)

### Integration with existing email flows

Each existing email flow gets an optional schedule path:

```
Flow                     | Immediate path (unchanged)    | Schedule path (new)
─────────────────────────┼──────────────────────────────┼──────────────────────────
Compose/reply in thread  │ Mailer.deliver()              │ Insert scheduled_email +
                         │ create email_message{status:   │ create email_message{
                         │   sent}]                      │   status: scheduled}
Bulk send                │ Enum.each → Mailer.deliver()  │ Insert N scheduled_email
                         │                               │ records + Oban jobs
Stage move email         │ Mailer.deliver() + move       │ Insert scheduled_email +
                         │                               │ move candidate
```

For bulk sends with scheduling, N individual `scheduled_emails` records are created (one per candidate), each with its own Oban job. This makes them independently manageable in the queue.

### UI: Schedule picker

Natural language presets + custom fallback:

```
┌─ "Invia" ─────────────────────────────────────┐
│ ○ Invia ora                                   │
│ ● Programma                                   │
│                                                │
│   [Domani 9:00]  [Domani 14:00]  [Lunedì]     │
│   [Prossima settimana...]                      │
│                                                │
│   Data: [31/07/2026]  Ora: [09:00]            │
│   ☑ ±5 min (scarta l'ora esatta)              │
│                                                │
│   [Annulla]  [Programma]                       │
└────────────────────────────────────────────────┘
```

Presets compute from current time:
- "Domani 9:00" → tomorrow at 09:00
- "Domani 14:00" → tomorrow at 14:00
- "Lunedì" → next Monday at 09:00
- "Prossima settimana..." → next Monday at 09:00 (opens the date picker pre-filled)

### UI: Email queue page (`/app/email-queue`)

Tabbed layout:

```
┌──────────────────────────────────────────────────────────────┐
│  📬 Coda Email                         [Scheduled: 3]       │
│                                                                │
│  [In Coda ▼]  [Inviate]  [Fallite]  [Annullate]               │
│                                                                │
│  ┌──────────────────────────────────────────────────────────┐ │
│  │ ☐ │ Destinatario        │ Oggetto          │ Programma   │ │
│  │ ├──┼────────────────────┼──────────────────┼─────────────┤ │
│  │ ☐ │ marco@co.it         │ Colloquio...     │ Oggi 14:30  │ │
│  │   │                     │                  │ ±5 min      │ │
│  │   │  [✏️ Modifica] [▶️ Invia ora] [✖️ Annulla]           │ │
│  │ ☐ │ anna@co.it          │ La tua candid... │ Dom 9:00    │ │
│  │   │  [✏️ Modifica] [▶️ Invia ora] [✖️ Annulla]           │ │
│  ├──┼────────────────────┼──────────────────┼─────────────┤ │
│  │   Totale: 3 programmate · 0 in invio                     │ │
│  └──────────────────────────────────────────────────────────┘ │
│                                                                │
│  [▶️ Invia selezionate]  [✖️ Annulla selezionate]             │
└──────────────────────────────────────────────────────────────┘
```

Edit modal allows changing subject, body, and schedule time (not recipient).

### Multi-node safety

Oban uses `SELECT ... FOR UPDATE SKIP LOCKED` when claiming jobs, ensuring each job is executed exactly once across the cluster. No special coordination needed.

When a user cancels an email from the UI:
1. `scheduled_emails.status = "cancelled"` (database transaction)
2. `email_messages.status = "cancelled"`
3. Oban job executes eventually but the worker checks `status != "scheduled"` and no-ops

The Oban worker always checks the current status before sending. This handles the race between "cancel in UI" and "job executing on another node."

## Risks / Trade-offs

| Risk | Mitigation |
|------|------------|
| Oban job executes after user cancels (race window) | Worker checks `status` before sending; if not `scheduled`, no-op and delete job |
| Bulk send with 500 individual Oban jobs thrashes Postgres | Use `max_concurrency` on the `:email` queue; consider bulk-specific optimization if scaling issues arise |
| User edits body but Oban job already picked up old body | Worker reads fresh from DB at execution time; edit updates the row, Oban worker picks up latest |
| Jitter causes email to arrive significantly earlier than desired | Cap jitter range to ±15min max; show the actual send_at range to the user (e.g., "tra le 8:55 e le 9:05") |
| Oban dependency adds complexity to test setup | Use Oban.Testing module for unit tests; integration tests use `perform_job` with inline execution |

## Migration Plan

1. **Add Oban dependency** to mix.exs and configure in each environment
2. **Generate migration**: `scheduled_emails` table + `email_messages` status/scheduled_at columns
3. **Create `Treby.EmailQueue` context** with basic CRUD
4. **Create `Treby.Workers.SendScheduledEmail`** Oban worker
5. **Add Oban to supervision tree** in application.ex
6. **Modify `email_threads` context** to support scheduling in compose/reply
7. **Modify `bulk_operations` context** to support scheduled bulk sends
8. **Modify stage move flow** in pipeline LiveView to support scheduling
9. **Create `EmailQueueLive.Index`** LiveView and route at `/app/email-queue`
10. **Update docs** in `site/features/email-scheduler.md`
11. **Regenerate screenshots**

**Rollback**: Remove Oban from supervision tree, drop `scheduled_emails` table, revert `email_messages` changes. All immediate email flows remain untouched.

## Open Questions

- Should `email_messages` for scheduled emails show a different visual in the thread (e.g., dashed border, clock icon)? This is a UX detail, resolved in the `bidirectional-email` delta spec.
- For bulk sends with scheduling, should the queue group them visually (e.g., "Bulk send to 25 candidates") or show each individually? Decision: show individually for independent management, but the UI could group by `email_type + reference_type + scheduled_at` for browsing convenience.
