## Context

The main app navigation is defined in a single function component `app/1` in `lib/treby_web/components/layouts.ex` (line 40). It renders both a desktop nav bar (hidden on small screens) and a mobile hamburger drawer. Routes for `/app/pipeline/:job_id`, `/app/import`, and `/app/compare` already exist in the router but have no nav links pointing to them. There is zero active-link logic — all links use identical static classes.

The `app/1` component receives `@flash`, `@current_scope`, and `@locale`. The underlying `conn` is accessible via `@conn.request_path`.

## Goals / Non-Goals

**Goals:**
- Add Pipeline, Import, and Compare links to both desktop and mobile nav
- Add active-link highlighting using the current request path
- Add Logout and locale switcher to the mobile drawer (currently missing)
- Keep the nav clean and not overcrowded

**Non-Goals:**
- Redesigning the overall layout or visual style
- Adding icons to nav links
- Changing the mobile hamburger trigger behavior
- Adding new routes

## Decisions

### Active link detection: client-side JS with data-nav attributes

**Decision:** Add `data-nav` attributes to each nav link with its target path. Use a JS function `highlightActiveNav()` that reads `window.location.pathname` and toggles Tailwind classes on matching links. Runs on page load and after LiveView navigation (`phx:page-loading-stop`).

**Rationale:** The original plan was server-side detection via `@conn.request_path` + a `nav_link_class/2` helper. This was attempted but abandoned because:
1. `get_connect_info(socket, :uri)` doesn't work in `on_mount` hooks — the transport socket lacks `conn` info
2. Adding `:uri` to endpoint `connect_info` requires a server restart that wasn't picked up during development
3. The `conn` is not available as a LiveView assign for subsequent navigations

Client-side detection is simpler, works reliably for all navigation types (initial load, LiveView push_navigate, push_patch), and avoids coupling layout to LiveView socket internals.

**Alternatives considered:**
- Server-side via `@conn.request_path` — only works for initial render, not LiveView navigations
- `on_mount` hook with `get_connect_info` — transport socket lacks conn info
- Endpoint `connect_info: [:uri]` — requires server restart, not available during hot reload

### Nav link ordering

**Decision:** `Jobs | Candidates | Pipeline | Import | Compare | Interviews | Analytics | Settings`

**Rationale:** Pipeline is core ATS functionality and should be near the top. Import and Compare are supporting tools placed together. Interviews and Analytics remain in their current positions. Settings stays last (admin only).

### Mobile drawer: add logout and locale

**Decision:** Add the locale switcher and logout link to the mobile drawer, matching the desktop nav.

**Rationale:** Currently mobile users cannot log out or switch language without navigating away. This is a functional gap.

## Risks / Trade-offs

- **Nav crowding on tablet/sm screens** → Mitigate by keeping links concise and using shorter labels where needed. The `sm:` breakpoint already handles small-screen hiding. Consider grouping Import/Compare under a dropdown if needed, but initial implementation keeps them flat.
- **Prefix matching false positives** → e.g., `/app/candidates` matching `/app/candidates/123` is correct behavior. But `/app/analytics` would NOT match `/app/analytics/something` unless that route exists (it doesn't currently). Low risk.
