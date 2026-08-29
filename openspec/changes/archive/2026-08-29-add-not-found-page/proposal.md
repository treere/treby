## Why

Navigating to the page of a non-existent entity (e.g. `/app/jobs/9774d9db-b21b-47cb-9d2c-031953581fee`) currently crashes with a raw stacktrace instead of a friendly message. LiveViews load entities in `mount/3` via `get_*!`/`Repo.get!` calls (or explicit `Ecto.NoResultsError` raises), which bubble up as 500 errors and expose ugly developer-facing output.

## What Changes

- Introduce a dedicated, nicely styled "Not Found" page that is shown whenever a user navigates to a route identifying a non-existent entity (job, candidate, application, pipeline, custom field, etc.).
- Handle not-found in the entity detail LiveViews: when the entity referenced by the URL param does not exist, the view renders the Not Found page (with an appropriate HTTP status) instead of raising a stacktrace.
- Provide a lightweight, reusable mechanism so future entity-loading LiveViews can adopt the same behavior consistently.
- The Not Found page keeps the app's look-and-feel (layout, nav, dark mode, locale) and offers the user a clear way back (e.g. a "Back" / breadcrumb link).
- Do **not** change the behavior of authenticated access checks (that stays as flash errors / redirects) — this change is only about *non-existent* resources.

## Capabilities

### New Capabilities
- `not-found-page`: A styled "Not Found" (404) experience for authenticated and public entity routes, including reusable handling for LiveViews that load an entity from a URL param and a redirection/status behavior that avoids stacktraces when the entity does not exist.

### Modified Capabilities
<!-- No existing spec requirements change; this is a new cross-cutting behavior. -->

## Impact

- **LiveViews** whose `mount/3` (or param-driven handlers) load an entity by UUID and would raise on missing records: `JobsLive.Show`, `CandidatesLive.Show`, `PipelineLive.Index`, `ScheduleLive.Index`, `SettingsLive` sub-views, `CareersLive.Show`/`Apply`, `CandidatePortalLive.MessageThread`, among others.
- **Context/Context modules**: may add non-bang lookups already present (e.g. `Candidates.get_candidate/2`), or add safe lookup variants used by LiveViews.
- **Layout/HTML**: a new 404 template/component reusing `Layouts.app` where appropriate.
- **Router / endpoint**: ensure a proper 404 status is returned rather than a 500.
- No database schema changes.
