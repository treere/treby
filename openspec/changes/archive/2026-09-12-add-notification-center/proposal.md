## Why

Toast notifications are invisible (fixed positioning broken after daisyUI removal) and there is no in-app notification inbox. Hiring events (new applications, stage changes, interviews) are only surfaced via email pings or the dashboard "Recent Activity" audit feed, so recruiters miss time-sensitive updates unless they poll. Users need ephemeral feedback for actions plus a persistent, per-user inbox that guarantees important notifications are seen.

## What Changes

- **Fix toast positioning and styling:** replace remaining daisyUI `toast`/`alert` classes in `CoreComponents.flash` with bespoke Tailwind (`fixed top-4 right-4` + `Feedback.toast` scale), so toasts appear at the top-right, stack, auto-dismiss, and render correctly in light/dark themes. No daisyUI dependency remains.
- **Add notification center (in-app inbox):**
  - New `notifications` table (per-user, per-tenant, `read_at` nullable, `type`/`title`/`body`/`link`/`actor_id`).
  - Creating a notification fans out to **all members of the tenant** (not just admins) when the event type has inbox enabled.
  - Every event that creates an inbox row also shows an ephemeral toast; the toast auto-dismisses after 5s but the row stays unread until the user interacts (click "View" or marks read). Pure feedback toasts (e.g., form validation) remain ephemeral-only with no row.
  - Realtime delivery via `Phoenix.PubSub` on `notifications:<user_id>` — bell badge and inbox list update live; fallback to DB count on mount/reconnect.
  - UI: bell icon with unread badge in `Layouts.app` nav → dropdown with 5 most recent unread + "Mark all read" + "View all" link → full page at `/app/notifications` with filters (All/Unread, by type), search, pagination, per-row mark-read and bulk mark-all-read.
  - Configurability: each notification type has independent `email` and `inbox` toggles in `Settings → Notifications` (stored in `tenant.settings["notifications"]` as `{email, inbox}` objects with backward compat for legacy booleans). Retention of read notifications is tenant-configurable (`tenant.settings["notifications_retention_days"]`, default 30 days, options 7/14/30/60/90).
  - Retention: `Oban` daily pruner deletes rows where `read_at < now() - retention_days`; unread rows are never auto-deleted.
  - Backfill (best-effort): one-off mix task/seed that maps recent `activity_log` rows (last 30 days) to notifications for current members, where a mapping exists; inbox starts empty if no mappable history.
- **BREAKING:** `tenant.settings["notifications"]` shape changes from `bool` to `{email,inbox}` object; old booleans are migrated on read (treated as `email` value, `inbox` defaults to `true`).

## Capabilities

### New Capabilities
- `notification-center`: in-app inbox, bell + dropdown + full page, realtime, per-user read state, bulk actions, filters/search/pagination, retention pruner, backfill.
- `notification-preferences`: per-type `email`/`inbox` toggles plus tenant-level retention setting.

### Modified Capabilities
- `error-feedback`: toast rendering moves fully to bespoke `Feedback.toast` styling and fixed positioning; remove remaining daisyUI `toast`/`alert` classes. Guardrail for `class="alert`/`toast` outside DS must pass.
- `design-system`: no functional addition, but `Feedback.toast` becomes the sole toast contract (already exists) — verify no daisyUI classes remain via existing guardrail.

## Impact

- **DB:** new migration `create_notifications` + migration or on-read compat for `tenant.settings` shape; new index `(recipient_id, read_at)`.
- **Modules:** new `Treby.Notifications.Inbox` / `Treby.Notifications.Notification` schema, `Treby.Notifications.PrunerWorker` (Oban), `TrebyWeb.Live.NotificationsLive` + bell component, updates to `Treby.Notifications` (fan-out, prefs with inbox), `TrebyWeb.Layouts` (bell), `TrebyWeb.SettingsLive.Notifications` (dual toggles + retention), `TrebyWeb.CoreComponents` (flash fix).
- **Realtime:** `Treby.PubSub` topic `notifications:<user_id>`.
- **No new dependencies.** Existing `Oban`, `Phoenix.PubSub`, `Tailwind 4`, `heroicons` reused.
