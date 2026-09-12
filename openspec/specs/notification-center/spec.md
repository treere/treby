# Notification Center

## Purpose

In-app notification inbox that guarantees hiring events are seen. Every event that has inbox enabled fans out to all tenant members as an unread row, drives a bell badge and realtime push, and is cleared only by explicit user action; read rows are pruned after a configurable retention window.

## Requirements

### Requirement: Notification inbox with per-user read state
The system SHALL provide a per-user, per-tenant notification inbox. Each hiring event that has inbox enabled SHALL create one row per tenant member. Rows are unread (`read_at` is null) until the user marks them read. Unread rows are never auto-deleted.

#### Scenario: Fan-out to all tenant members
- **WHEN** a hiring event occurs (e.g., new application, interview scheduled) and inbox is enabled for that type
- **THEN** the system creates one notification row for every user with a membership in the tenant
- **AND** each row has `read_at = null`, `tenant_id` set, and `type`/`title`/`body`/`link` populated

#### Scenario: Unread count drives badge
- **WHEN** a user has unread notifications
- **THEN** the bell badge shows the count of rows where `recipient_id = current_user.id` and `read_at is null`

#### Scenario: Mark single notification as read
- **WHEN** a user clicks a notification row or its "View" action
- **THEN** the system sets `read_at` to now for that row
- **AND** the row navigates to its `link` if present

#### Scenario: Mark all as read
- **WHEN** a user clicks "Mark all read" in the dropdown or on the full page
- **THEN** the system sets `read_at` to now for all unread rows of that user

#### Scenario: Unread rows persist
- **WHEN** a notification is unread
- **THEN** it is never deleted by the retention pruner regardless of age

### Requirement: Toast is ephemeral, inbox is the guarantee
The system SHALL show an ephemeral toast for every event that creates an inbox row, and also for pure feedback events that do not create rows. The toast auto-dismisses after 5 seconds; dismissing or missing the toast does not mark the inbox row as read.

#### Scenario: Inbox event shows toast and row
- **WHEN** an event with inbox enabled occurs
- **THEN** the system inserts the inbox row(s) and shows a toast (e.g., "New application: Mario Rossi — Backend Engineer")
- **AND** the toast auto-dismisses after 5 seconds but the row remains unread

#### Scenario: Toast dismiss does not mark read
- **WHEN** a user closes the toast via the X button or the toast times out
- **THEN** the inbox row remains unread and the bell badge stays incremented

#### Scenario: Clicking toast marks read and navigates
- **WHEN** a user clicks "View" on the toast
- **THEN** the system marks the corresponding row as read and navigates to its link

#### Scenario: Pure feedback toast creates no row
- **WHEN** a form validation fails or an action succeeds with no inbox type (e.g., "Pipeline created", "Please review the errors below")
- **THEN** only a toast is shown and no inbox row is created

### Requirement: Bell, dropdown, and full-page inbox
The system SHALL show a bell icon with unread badge in the top navigation, a dropdown with the 5 most recent unread notifications, and a full-page inbox at `/app/notifications` with filters, search, and pagination.

#### Scenario: Bell badge in navigation
- **WHEN** a user views any `/app` page
- **THEN** the top nav shows a bell icon with a badge count equal to unread notifications
- **AND** the badge is hidden when count is zero

#### Scenario: Dropdown shows recent unread
- **WHEN** a user clicks the bell
- **THEN** a dropdown appears showing the 5 most recent unread notifications (title, body preview, relative time, unread dot)
- **AND** the dropdown contains "Mark all read" and "View all" (→ `/app/notifications`) actions

#### Scenario: Full-page inbox lists notifications
- **WHEN** a user navigates to `/app/notifications`
- **THEN** they see a paginated list of their notifications (most recent first) with type icon, title, body, time, and read/unread state
- **AND** unread rows are visually distinct (e.g., dot + bolder title / subtle background)

#### Scenario: Filters and search
- **WHEN** a user uses the inbox filters
- **THEN** they can filter by All vs Unread and by notification type, and search by title/body via `ILIKE`
- **AND** the list updates without full page reload

#### Scenario: Pagination
- **WHEN** there are more notifications than one page
- **THEN** the design-system Pagination component appears with Prev/Next and result count

#### Scenario: Realtime updates
- **WHEN** a new notification is created for the user while they are viewing any `/app` page
- **THEN** the bell badge increments and, if the inbox page is open, the new row appears at the top without manual refresh (via PubSub `notifications:<user_id>`)

### Requirement: Retention of read notifications
The system SHALL delete read notifications after a tenant-configurable retention period (default 30 days). Unread notifications are never deleted. A daily Oban pruner performs the deletion.

#### Scenario: Default retention is 30 days
- **WHEN** a tenant has not configured a custom retention
- **THEN** read notifications older than 30 days (from `read_at`) are deleted by the daily pruner

#### Scenario: Tenant can configure retention
- **WHEN** an admin changes retention in Settings → Notifications to 7, 14, 30, 60, or 90 days
- **THEN** the new value is persisted in `tenant.settings["notifications_retention_days"]`
- **AND** the next pruner run uses the new threshold

#### Scenario: Pruner respects tenant setting
- **WHEN** the pruner runs
- **THEN** it deletes only rows where `read_at < now() - interval retention_days` per tenant's setting, and never rows where `read_at is null`

### Requirement: Backfill from recent activity log (best-effort)
The system SHALL provide a one-off, idempotent backfill that maps recent `activity_log` rows (last 30 days) to inbox notifications for current tenant members, where a mapping exists for the action type.

#### Scenario: Backfill creates rows for current members
- **WHEN** an operator runs the backfill task
- **THEN** for each tenant and each mappable `activity_log` row from the last 30 days, one notification row per current member is created if inbox is enabled for that type

#### Scenario: Backfill is idempotent
- **WHEN** the backfill is run a second time
- **THEN** it does not create duplicate rows (deduped by tenant + recipient + type + entity/link + time window)

#### Scenario: No mappable history means empty inbox
- **WHEN** there is no mappable `activity_log` history
- **THEN** the inbox simply starts empty with no error

### Requirement: Multi-tenant isolation and authorization
The system SHALL scope all inbox queries by `tenant_id` and `recipient_id = current_user.id`. Users can only list, read, and mark-read their own notifications; they cannot access another tenant's or another user's rows.

#### Scenario: Tenant isolation
- **WHEN** a user queries notifications
- **THEN** only rows with `tenant_id = current_tenant.id` and `recipient_id = current_user.id` are returned

#### Scenario: Authorization on mark-read
- **WHEN** a user attempts to mark a notification as read that does not belong to them
- **THEN** the operation is rejected (not found / forbidden) and no row is modified
