## Context

The app has many entity-detail LiveViews (Jobs, Candidates, Pipeline, Schedule, Careers, Candidate Portal, and several Settings sub-views). These load an entity in `mount/3` from a route param (a UUID) using bang lookups (`get_job!`, `Repo.get!`, `get_*`) or an explicit `raise Ecto.NoResultsError`. When the ID doesn't correspond to an existing record, the raise propagates as a 500, showing a developer-facing stacktrace instead of a friendly message.

Because these detail views each hold dozens of `handle_event` handlers that assume the entity is present in `assigns`, merely swapping the template while keeping the same LiveView process alive is fragile — a stray interaction would still invoke handlers that crash on a missing entity. The design therefore redirects to a dedicated Not Found page, cleanly terminating the faulty view.

## Goals / Non-Goals

**Goals:**
- Show a polished, on-brand "Not Found" page (with app shell, nav, locale, dark mode) instead of a stacktrace when a user opens a route for a non-existent entity.
- Provide a single reusable Not Found destination and a tiny, consistent way for any entity-loading LiveView to reach it.
- Apply it to the primary entity-detail routes without changing authentication/authorization behavior.
- Keep entity LiveViews safe: a missing entity never leaves a live view that renders half-initialized handlers.

**Non-Goals:**
- Not reworking authorization/role checks (those remain flash messages / redirects as today).
- Not building a global catch-all 404 for every unmatched URL (the router already 404s unknown paths); this is scoped to *known-shaped* routes whose entity lookup fails.
- Not changing the public career/apply page behavior beyond replacing stacktraces with the same friendly page (tenant-scoped lookups stay).

## Decisions

### A dedicated Not Found page rendered by its own LiveView
Create a small standalone LiveView `TrebyWeb.ErrorLive.NotFound` served at a fixed route (`/404`). It renders a styled 404 pane with a clear back link and reuses the standard authenticated app layout when navigated to from `/app/*` (and a suitable public variant for career/portal contexts).

- **Why this over a shared inline component:** Entity detail views have many `handle_event` handlers that require the entity in `assigns`. Redirecting out of the view guarantees a missing record can never be interacted with. A single destination is easy to test and reuse.
- **Alternatives considered:** (1) rendering a not-found template inside each entity view while keeping the same process — rejected because handlers would still run and crash on nil entity; (2) letting `Ecto.NoResultsError` bubble to `ErrorHTML/404` — rejected because it only cleanly works for the initial HTTP GET, breaks the LiveView socket handshake path, and doesn't reuse the app shell with current user/locale.

### Entity LiveViews redirect to the Not Found page when the entity is missing
Each affected `mount/3` becomes a lookup that, when the record is absent, returns:

```elixir
{:ok, redirect(socket, to: ~p"/404")}
```

For views using bang lookups that would raise, switch to a non-bang/safe lookup or wrap the call in a `case ... rescue Ecto.NoResultsError, ->` so mount can respond gracefully.

- **Why redirect from mount:** `redirect/2` works for both the initial HTTP request and subsequent LiveView socket navigations (`push_navigate` to a bad ID), so the behavior is consistent.
- **Alternatives considered:** `{:stop, socket}` / halting — rejected, halting drops the connection and shows no page.

### Approach B is the chosen mechanism: redirect to a not-found route
Every affected entity LiveView, when its entity lookup fails, redirects to the dedicated `/404` route via `redirect(socket, to: ~p"/404")` returned from `mount/3` (a `{:ok, redirect(...)}` tuple). The `/404` route resolves to `TrebyWeb.ErrorLive.NotFound`. Confirmed decision — no inline-component alternative will be pursued.

### Lookup helper additions
Where a bang variant is the only public API, add/reuse a non-bang lookup (several already exist, e.g. `Candidates.get_candidate/2`) or guard with a `rescue`. Prefer the least invasive change: use existing non-bang lookups when present, else add a thin safe wrapper in the relevant context module.

## Risks / Trade-offs

- [Redirect changes URL/back behavior] → Mitigation: acceptable and expected; the Not Found page provides a prominent "back to list" / breadcrumb link.
- [Wide blast radius touching many LiveViews] → Mitigation: phase the adoption; tasks cover the main user-facing detail routes first (Jobs, Candidates, Pipeline, Schedule, Careers), then secondary/settings views.
- [Missed edge: a handler that raises on a stale/cancelled entity post-mount] → Mitigation: out of scope for this change; mount-level guard addresses the reported navigation case. Note resulting `:delete_cascade`/concurrency paths are not addressed here.
