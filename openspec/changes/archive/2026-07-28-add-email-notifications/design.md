## Context

Treby is a multi-tenant ATS built with Phoenix LiveView. The email infrastructure is mature:
- `Treby.Mailer` wraps Swoosh for delivery
- `Treby.EmailTemplates` handles stage-based templates with variable interpolation (`{candidate_name}`, `{job_title}`, etc.)
- `Treby.SchedulingEmail` sends interview scheduling notifications
- `Treby.InvitesEmail` sends team invite emails
- `Treby.PasswordResetEmail` handles password reset flows
- Bidirectional email threading exists (receive replies, display threads)

The gap: **no automated notification triggers** fire on the two most important events:
1. Candidate stage transitions (`Pipeline.move_application/2`) — templates exist but the trigger is unwired
2. New application submissions (`CareersLive.Apply`) — no notification to candidates or team

The existing `stage-email-templates` spec already defines the template system and the confirmation dialog behavior. The implementation exists in `EmailTemplates.send_stage_email/4` and `EmailTemplates.render_email/2`. What's missing is the orchestration layer that detects when to send and coordinates the flow.

## Goals / Non-Goals

**Goals:**
- Send automated emails to candidates when they move between pipeline stages (using existing templates)
- Send confirmation emails to candidates after they apply via the career page
- Send "new application" alerts to job owners/admins when applications are submitted
- Make all notifications configurable per-tenant (opt-in/opt-out)
- Keep email sending non-blocking — stage moves and application submissions must never fail due to email delivery issues
- Log all sent emails in the activity audit trail

**Non-Goals:**
- Real-time email tracking (opens, clicks) — that's a future enhancement
- Email scheduling/delayed sending
- Custom notification rules beyond on/off per type
- SMS or push notifications
- Modifying the existing email template editor UI
- Implementing the full bidirectional email reply flow (that's a separate change)

## Decisions

### Decision 1: Orchestration in a dedicated `Notifications` context

**Choice**: Create `Treby.Notifications` context module that coordinates all notification logic.

**Why**: Centralizes notification triggering, template resolution, and delivery coordination in one place. Keeps `Pipeline.move_application/2` and `CareersLive.Apply` clean — they just call `Notifications.notify/2` after their primary operation.

**Alternatives considered**:
- Inline in `move_application/2`: Simpler but couples notification logic to pipeline, making it hard to add new triggers later
- PubSub-based (subscribe to events): More decoupled but adds complexity for synchronous notifications; better suited for async workers in the future

### Decision 2: Synchronous delivery with error isolation

**Choice**: Send emails synchronously within the request, but wrapped in `try/rescue` so delivery failures never crash the primary operation.

**Why**: The existing `SchedulingEmail` module already sends synchronously via `Treby.Mailer.deliver()`. Consistency with existing patterns. For a small business ATS, the volume is low enough that async processing (Oban, Task.async) adds unnecessary infrastructure complexity.

**Alternatives considered**:
- Oban job queue: Overkill for current scale; adds dependency and operational complexity
- Task.async: Fire-and-forget but no retry, no observability, potential process leaks
- Synchronous with retry: Adds complexity; Swoosh already handles transient failures at the transport level

### Decision 3: Notification preferences as a JSON settings field

**Choice**: Add a `notifications` key to the existing `tenant.settings` JSONB field rather than a separate table.

**Why**: The `tenants` table already has a `settings` JSONB column used for other preferences. A separate `notification_preferences` table would require a new schema, migration, and context module for 4 boolean flags. The JSONB approach is simpler and follows the existing pattern.

**Alternatives considered**:
- Separate `notification_preferences` table: Over-normalized for 4 booleans; adds JOIN complexity
- User-level preferences: Notifications are tenant-level (all admins see the same config), not per-user

### Decision 4: Four notification types

**Choice**: Support these configurable notification types:
1. `stage_change_candidate` — email to candidate when moved to a new stage (if template exists)
2. `new_application_candidate` — confirmation email to candidate after applying
3. `new_application_team` — alert to job owner/admin when new application arrives
4. `interview_reminder` — (not implemented now, but the preference slot exists for future use)

**Why**: Covers the two critical gaps identified in the UX audit. The preference system is extensible for future types without schema changes.

### Decision 5: Activity logging for sent emails

**Choice**: Log each sent email as an activity event with metadata (recipient, type, subject, delivery status).

**Why**: The activity audit trail already exists and is displayed in the app. Adding email events gives admins visibility into what notifications were sent and whether they succeeded.

## Risks / Trade-offs

- **[Risk] Email delivery failures silently swallowed** → Mitigation: Log failures to activity trail with error details. Admins can see failed deliveries in the audit log. No user-facing error since the primary operation (stage move) must succeed.

- **[Risk] Duplicate notifications on rapid stage changes** → Mitigation: No deduplication at this stage — if a user moves a candidate through 3 stages quickly, 3 emails send. This matches recruiter expectations (they chose to send each time). The confirmation dialog already gives the opt-out per send.

- **[Risk] Tenant settings JSONB grows unbounded** → Mitigation: Only 4 boolean keys added. The settings map is small and bounded.

- **[Trade-off] Synchronous vs async** → Chose synchronous for simplicity. At high volume (100+ applications/day), this could slow down the career page submission. For now, acceptable. Can migrate to Oban later without changing the Notifications API.

- **[Trade-off] No per-user preferences** → All team members share the same tenant notification config. This is intentional — notification settings are an organizational decision, not individual preference.
