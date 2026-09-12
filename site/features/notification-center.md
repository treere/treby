# Notification Center

Never miss a hiring update. Every important event shows an ephemeral toast and stays as an unread row in your personal inbox until you act.

![Notifications inbox](/screenshots/43-notifications-inbox.png)

![Notification preferences](/screenshots/39-settings-notifications.png)

## What you get

- **Bell with badge** in the top navigation shows your unread count. Badge hides at zero.
- **Dropdown** — click the bell to see the 5 most recent unread notifications with title, preview, and time. Actions: **Mark all read** and **View all → Notifications**.
- **Full inbox** at **Notifications** (or `/app/notifications`) with filters, search, and pagination.
- **Realtime** — new notifications appear instantly via realtime push; if you are offline they appear on next page load.

## Using the bell

1. Look for the bell icon near the theme and language controls in the top nav.
2. Unread count badge appears when you have unread items.
3. Click the bell — dropdown opens.
4. Click a row's **View** to open the linked page and mark that notification read, or **Mark read** to dismiss without navigating.
5. **Mark all read** clears the badge in one click. **View all** opens the full inbox.

## Using the inbox page

Navigate to **Notifications** from the bell dropdown.

- **Filters:** **All** vs **Unread** tabs, plus **Type** select (New application, Interview scheduled, Interview cancelled, Stage change).
- **Search:** filter by title or body.
- **Pagination:** prev/next and result count at the bottom.
- **Per-row actions:** unread rows show a dot and bolder title; click **Mark read** or **View** to mark read and navigate.
- **Bulk:** **Mark all read** at the top marks every unread row read at once.

Notifications update live — a new row appears at the top without manual refresh.

## Toast behavior

- Every inbox event also shows a toast at the top-right (fixed, stacked, 5s auto-dismiss).
- Dismissing the toast (X or timeout) does **not** mark the inbox row read — the bell badge stays until you use **View** or **Mark read** in the bell or inbox.
- Pure feedback messages (e.g., "Please review the errors below", "Pipeline created") show only a toast with no inbox row.

## Preferences

Configure per-tenant in **Settings → Notifications** (admin only).

- **Per-type toggles:** each notification type has independent **Email** and **In-app** switches. Turning off **In-app** stops inbox rows for that type (email may still be sent if its toggle is on, and vice versa).
- **Retention:** choose how long read notifications are kept before automatic deletion — 7, 14, 30, 60, or 90 days. Default is 30 days. **Unread notifications are never auto-deleted.**

Changes save immediately and affect future events only.

## Retention and backfill

- A daily background job deletes read notifications older than your retention setting.
- On first rollout the inbox starts empty. An operator can optionally run a one-time backfill that maps recent activity (last 30 days) to notifications for current members where inbox is enabled — idempotent, safe to re-run, with a dry-run preview.
