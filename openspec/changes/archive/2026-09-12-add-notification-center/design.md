## Context

Treby is a multi-tenant ATS. Team authentication uses session + BCrypt; all data is scoped by `tenant_id`. Hiring events currently surface only via email pings (`Treby.Notifications`), the dashboard `Recent Activity` feed (`Treby.Activities` backed by `activity_log`), and ephemeral `Phoenix.Flash` toasts rendered by `CoreComponents.flash` / `Layouts.flash_group`. After the `2026-09-05-remove-daisyui` change, the CSS bundle no longer includes daisyUI, but `CoreComponents.flash` still emits daisyUI classes (`toast toast-top toast-end`, `alert alert-info/error`) — these now match nothing, so toasts render in-flow after `<main>` and are invisible at the top. There is no per-user, per-tenant inbox with read/unread state; `activity_log` is an immutable tenant-wide audit log, not an inbox.

Stakeholders: recruiters/admins/members on `/app` (primary inbox consumers), candidates on the portal (future inbox, out of scope for this MVP), tenant admins configuring preferences.

## Goals / Non-Goals

**Goals:**
- Fix toast rendering: toasts appear fixed top-right, stack, auto-dismiss, and respect light/dark themes using only the bespoke SaaS minimal tokens (`Feedback.toast` scale), with no daisyUI dependency.
- Add a per-user, per-tenant notification inbox with guaranteed visibility for important events: ephemeral toast previews the event, the inbox row persists as unread until the user acts.
- Make both email and inbox independently configurable per notification type, plus a tenant-level retention setting for read rows (default 30 days).
- Deliver realtime updates (badge + inbox list) via `Phoenix.PubSub` with DB fallback on mount.
- Provide bell + dropdown + full-page inbox UX that is easy to scan and act on.
- Ship a retention pruner and a best-effort backfill from recent `activity_log`.

**Non-Goals:**
- Candidate portal inbox (same table/pattern can be reused later with `recipient_type`; not in this change).
- Push notifications, desktop notifications, or external webhooks.
- Full-text search across notification bodies beyond simple `ILIKE` on title/body.
- Configurability per role (e.g., "only admins get X") — fan-out is to all tenant members for this change; role-scoped fan-out is a follow-up.
- Replacing `activity_log` or `audit_events`; they remain the compliance source.

## Decisions

### 1. New `notifications` table (not reuse of `activity_log`)

- **Chosen:** `notifications` with `id uuid PK`, `tenant_id uuid FK`, `recipient_id uuid FK → users`, `actor_id uuid nullable FK → users`, `type varchar` (enum of known types), `title text`, `body text nullable`, `link varchar nullable` (internal path like `/app/candidates/:id`), `read_at utc_datetime nullable`, `inserted_at/updated_at`. Index on `(recipient_id, read_at)` for badge counts and inbox queries; index on `(tenant_id)`.
- **Why not `activity_log`:** `activity_log` is tenant-wide, actor-centric, and immutable audit. Adding per-user `read_at` or per-user rows would conflate audit and inbox semantics and complicate retention (audit must be retained longer). A dedicated table keeps inbox retention (30 days after read, never for unread) independent from audit retention.
- **Alternative considered:** View/materialization over `activity_log` with a separate `notification_reads` join table — rejected: more joins, still needs fan-out logic, and `activity_log` entity types do not map cleanly to "who should see this."

### 2. Fan-out to all tenant members

- **Chosen:** On event, resolve recipients as all users with a `membership` for the tenant (`Treby.Memberships`). Insert one row per recipient in a single transaction (or `insert_all` with `on_conflict: :nothing` if dedup needed).
- **Why all members:** Requirement from discovery: "tutte le persone dell'azienda." Simple, predictable, no per-role matrix to maintain. If a tenant later needs role-scoped delivery, the `Inbox.create_for_tenant/4` can accept an explicit `recipient_ids` override without schema change.
- **Alternative considered:** Only admins + job owner (previous team-alert pattern) — rejected per explicit stakeholder decision.

### 3. Toast is always ephemeral, inbox persistence is the guarantee

- **Chosen:** For types where `inbox=true`, `Inbox.create` inserts the row *before* showing the toast. The toast is `put_flash` / `push_event` with 5s auto-dismiss. Clicking "View" or the notification row marks `read_at`. Dismissing the toast or letting it timeout leaves the row unread; the bell badge reflects `count unread`. For types where `inbox=false`, only the toast is shown and no row is created (pure feedback like "Pipeline created" or validation errors).
- **Why:** Toast as preview, inbox as guarantee — user never loses an important event if they miss the toast or are offline (row exists on next mount). Keeps ephemeral feedback cheap and persistent inbox auditable.
- **Alternative considered:** Toast with manual dismiss only for inbox types — rejected: toasts should never block; inbox is the persistence layer.

### 4. Realtime via `Phoenix.PubSub` topic `notifications:<user_id>`

- **Chosen:** `Inbox.create_for_tenant` broadcasts `{:new_notification, notification}` to each `notifications:<user_id>` topic. `Layouts.app` (bell) and `NotificationsLive` (full page) subscribe on mount to the current user's topic. Badge count is derived from `count where recipient_id=? and read_at is nil` on mount and incremented on push.
- **Why:** Matches existing patterns (`pipeline:<job_id>`, `conversation:<id>`). No new dependency; `Treby.PubSub` already configured. Handles multi-tab via duplicate broadcasts (idempotent by `id`).
- **Alternative considered:** Polling — rejected: higher DB load, worse UX. `Phoenix.Channel` — unnecessary for this fan-out.

### 5. Preferences shape `{email, inbox}` with backward compat

- **Chosen:** `tenant.settings["notifications"]` values become objects `{"email": bool, "inbox": bool}`. Reader normalizes: if legacy `bool`, treat as `{"email": bool, "inbox": true}` (default inbox on). Same pattern for candidate portal preferences when extended.
- **Why:** One atomic setting per type, no second map to keep in sync. Migration is lazy (on read/write), no data migration required beyond optional backfill task.
- **Alternative considered:** Two separate maps `notifications_email` / `notifications_inbox` — rejected: doubles keys and UI complexity.

### 6. Retention: delete read rows after N days, never unread

- **Chosen:** Tenant setting `tenant.settings["notifications_retention_days"]` integer 7/14/30/60/90, default 30. New `Treby.Notifications.PrunerWorker` (Oban, cron `0 3 * * *` or on-demand via `Oban.Periodic`) deletes `where read_at < now() - retention_days`. Unread rows are excluded from the delete.
- **Why Oban:** Already used for `ScheduledMessages` and `Oban.Plugins.Pruner`; no new infra. Daily sweep is cheap (indexed on `read_at`). Tenant-configurable satisfies "configurabile a livello di azienda" without per-user complexity.
- **Alternative considered:** Hard delete on mark-read — rejected: user would lose history too quickly. Soft archive — rejected: no compliance need (audit covers it).

### 7. Toast fix uses `Feedback.toast` tokens only

- **Chosen:** `CoreComponents.flash` renders inside `Layouts.flash_group` which becomes `fixed top-4 right-4 z-50 flex flex-col gap-2 pointer-events-none`; each `flash` div is `pointer-events-auto` with classes matching `Feedback.toast` (`bg-blue-50 dark:bg-blue-950 border-blue-200 ...` for info, etc., `rounded-xl border shadow-lg p-4`). Remove `toast`/`alert`/`alert-info`/`alert-error` strings.
- **Why:** `Feedback.toast` already defines the bespoke SaaS minimal scale for all four kinds (`info/success/warning/error`) with dark-mode overrides — reusing it eliminates the last daisyUI contract and keeps one source of truth.
- **Alternative considered:** Re-adding daisyUI — rejected: project explicitly removed it and the guardrail forbids it.

### 8. Backfill is best-effort, optional

- **Chosen:** Mix task `treby.notifications.backfill` (or `mix ecto.seed`-style one-off) reads `activity_log` last 30 days per tenant, maps known `action` values to inbox `type` (e.g., `new_application → new_application`, `interview_scheduled → interview_scheduled`), and inserts notifications for current members where `inbox` is enabled for that type. Idempotent via unique constraint on `(tenant_id, recipient_id, type, entity_id, inserted_at)` or dedup by not inserting if a notification with same `(tenant_id, recipient_id, type, link)` already exists in the last 30 days.
- **Why best-effort:** `activity_log` may not have all fields needed for `title/body/link` for every action; missing fields fall back to generic text. If no mappable history, inbox simply starts empty — acceptable.

## Risks / Trade-offs

- **Fan-out write amplification** (one row per member per event) → Mitigation: tenants are small (tens of members, not thousands); `insert_all` is O(members). If a large tenant emerges, batch inserts and background job fan-out can be introduced.
- **Unread never deleted → inbox growth if user never reads** → Mitigation: UI surfaces unread count prominently and "Mark all read" is one click; no auto-delete protects the guarantee. If growth becomes an issue, add a max-unread cap with archival after e.g. 500 and surface a warning.
- **PubSub missed message on disconnect** → Mitigation: badge and list always reconcile from DB on mount/reconnect; push is an optimization, not the source of truth.
- **Legacy boolean prefs misread as inbox disabled** → Mitigation: reader falls back to `inbox: true` for legacy booleans, so existing tenants get inbox without manual migration.
- **Backfill may create noisy inbox on first deploy** → Mitigation: backfill is opt-in (run manually), not automatic on migration; docs note to run only if desired.

## Migration Plan

1. **DB migration** `create_notifications` (uuid PK, FKs, indexes, `read_at` nullable, `type` check constraint).
2. **Code:** new `Treby.Notifications.Notification` schema + `Treby.Notifications.Inbox` context (create, list, counts, mark_read, mark_all_read, pruner query, prefs normalization).
3. **Code:** `Treby.Notifications.PrunerWorker` (Oban) + periodic config in `config/config.exs`.
4. **Code:** fix `CoreComponents.flash` + `Layouts.flash_group` styling (no migration).
5. **Code:** update `Treby.Notifications` prefs helpers to handle `{email,inbox}` objects + new retention helper.
6. **Code:** `TrebyWeb.SettingsLive.Notifications` — dual toggles + retention select.
7. **Code:** `Layouts.app` bell + dropdown component + `TrebyWeb.Live.NotificationsLive` (`/app/notifications`) with streams, filters, pagination, PubSub subscription.
8. **Wire call sites:** where `Activities.log_event` already fires for hiring events, also call `Inbox.create_for_tenant` when `inbox` is enabled (centralized in `Treby.Notifications` to avoid scattering).
9. **Deploy:** run `mix ecto.migrate`; no downtime. Inbox starts empty; optionally run `mix treby.notifications.backfill` (idempotent).
10. **Rollback:** drop `notifications` table and revert settings shape reader (legacy booleans still work). No data loss beyond inbox rows.

## Open Questions

- None blocking. Follow-ups: role-scoped fan-out if "all members" proves too noisy; portal inbox using same table with `recipient_type="candidate"`; richer filtering (by actor, by job) if users request it.
