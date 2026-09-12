## 1. Fix toast rendering (daisyUI removal)

- [x] 1.1 Replace daisyUI `toast`/`alert` classes in `CoreComponents.flash` with bespoke `Feedback.toast` scale; make `Layouts.flash_group` `fixed top-4 right-4 z-50 flex flex-col gap-2 pointer-events-none` with `pointer-events-auto` rows, stacked, auto-dismiss 5s; verify `rg "class=\"(toast|alert)" lib/treby_web --exclude-dir=design_system` is clean and screenshots pass in light/dark
- [x] 1.2 Verify guardrail: `mix precommit` + `node scripts/screenshots.mjs --axe` (contrast on toast variants)

## 2. Data model and migration

- [x] 2.1 Generate migration `create_notifications` (`mix ecto.gen.migration create_notifications`) with `id uuid PK`, `tenant_id uuid FK`, `recipient_id uuid FK → users`, `actor_id uuid nullable`, `type varchar`, `title text`, `body text`, `link varchar`, `read_at utc_datetime`, `inserted_at/updated_at`, indexes on `(recipient_id, read_at)` and `(tenant_id)`; run `mix ecto.migrate`
- [x] 2.2 Create `Treby.Notifications.Notification` schema and `Treby.Notifications.Inbox` context: `create_for_tenant/4` (fan-out to all tenant members via `insert_all`), `list_for_user/3` (filters: All/Unread, type, search ILIKE, pagination), `counts/1`, `mark_read/2`, `mark_all_read/1`, `delete_read_older_than/2` — all scoped by `tenant_id` + `recipient_id` with authorization checks

## 3. Preferences and retention

- [x] 3.1 Update `Treby.Notifications` prefs helpers to handle `{email,inbox}` objects with backward compat for legacy booleans; add `get_retention_days/1` and `set_retention_days/2` (validate 7/14/30/60/90); wire to `tenant.settings`
- [x] 3.2 Update `TrebyWeb.SettingsLive.Notifications` UI: dual toggles per type (Email + In-app) + retention select (7/14/30/60/90); handle `toggle_preference` for `email` vs `inbox` and `set_retention` event; `mix test test/treby/notifications_test.exs` green

## 4. Realtime and pruner

- [x] 4.1 Wire PubSub fan-out in `Inbox.create_for_tenant`: broadcast `{:new_notification, notification}` to `notifications:<user_id>` for each recipient; add `Oban` `Treby.Notifications.PrunerWorker` (daily, deletes `read_at < now() - retention_days` per tenant, never unread); register periodic in `config/config.exs`
- [x] 4.2 Backfill task `mix treby.notifications.backfill` (idempotent): map recent `activity_log` (30d) actions → notification types, insert for current members where inbox enabled; dry-run flag

## 5. Bell, dropdown, and inbox page

- [x] 5.1 Add bell component to `TrebyWeb.Layouts.app` nav (right side near theme/locale): badge with unread count, click toggles dropdown; subscribe to `notifications:<user_id>` on mount, handle `{:new_notification, _}` to increment badge and optionally push toast; dropdown shows 5 most recent unread with mark-read + "Mark all read" + "View all → /app/notifications"
- [x] 5.2 Create `TrebyWeb.Live.NotificationsLive` at `/app/notifications` (add `live` route in `router.ex` under authenticated `live_session`): stream with `phx-update="stream"`, filters (All/Unread, type), search, `DesignSystem.Pagination`, per-row mark-read + bulk mark-all-read, PubSub live insert; wire call sites that currently `log_event` for hiring events to also call `Inbox.create_for_tenant` when inbox is enabled (centralized helper)
- [x] 5.3 Tests: `test/treby/notifications/inbox_test.exs` (fan-out, counts, mark read, isolation), `test/treby_web/live/notifications_live_test.exs` (bell badge, dropdown, list, filters, mark all read, realtime via PubSub, auth/tenant isolation)

## 6. Wire event sources

- [x] 6.1 Audit existing event sites (`Pipeline.move_application`, `Interviews.schedule_interview`/`cancel`, `Applications` creation, `CandidatePortal` messages if team-visible) — add `Inbox.create_for_tenant` calls behind `inbox` pref check; ensure each also triggers a toast (via `put_flash` with appropriate `kind`) and that toast dismiss does not auto-mark read
- [x] 6.2 Toast wiring: ensure `put_flash(:info/:success/:warning/:error, ...)` for inbox events uses ephemeral toast only; verify toast auto-dismiss 5s and "View" action marks read + navigates

## 7. Specs and docs

- [x] 7.1 Update specs at `openspec/specs/notification-center/spec.md`, `openspec/specs/notification-preferences/spec.md`, `openspec/specs/error-feedback/spec.md` — add Purpose/Requirements and WHEN/THEN scenarios per delta specs; run `openspec validate --strict`
- [x] 7.2 Sync docs: update `site/features/index.md` + add `site/features/notification-center.md` (bell, inbox, preferences, retention — English only, no code references, user manual style) + sidebar in `site/.vitepress/config.ts`; regenerate screenshots with `node scripts/screenshots.mjs` and update feature page screenshots; run `node scripts/screenshots.mjs --axe`

## 8. Final verification

- [x] 8.1 Run `mix precommit` and `openspec validate --strict` and fix issues
