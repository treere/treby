## Context

Candidates are compared today via a standalone page (`/app/compare`) that has its own checkbox-based selection list and renders the side-by-side grid on the same page after clicking "Compare Selected". The candidates list (`/app/candidates`) already has per-row checkboxes and a floating bulk-action bar (Move to Stage, Mark as Reviewed/New, Send Email, Merge, Delete), but that bar is broken in real browsers: the action `<select>` elements use `phx-change` without being inside a `<form>`, so LiveView's JS drops the event ("form events require the input to be inside a form") and the contextual confirm button never appears. The standalone compare selection page is therefore both redundant and the only working entry point.

`Treby.Comparison.compare_candidates/1` already builds the full comparison payload (candidate + applications + notes + scorecards + custom fields) from a list of ids and is reused unchanged.

## Goals / Non-Goals

**Goals:**
- Compare becomes a bulk action on the candidates list; selection stays where selection already exists.
- The comparison view renders immediately from candidate ids carried in the URL (`/app/candidates/compare?ids=...`), with a link back to the list.
- The "Compare" entry disappears from the desktop and mobile nav menus.
- The bulk action dropdown flow actually works in the browser again (form-wrapped selects).

**Non-Goals:**
- No changes to `Treby.Comparison.compare_candidates/1` or the comparison grid rendering.
- No new data model, no persistence of selection beyond the URL.
- Not fixing the bulk email composer's own out-of-form `phx-change` inputs (same class of bug, separate concern).

## Decisions

**1. Route: `/compare` → `/candidates/compare`.**
The comparison page moves under the candidates scope and is placed before the `/candidates/:id` catch-all in the router (mirroring the existing `/candidates/merge`). This keeps the URL meaningful and groups candidate-related views. The old `/app/compare` route is removed, so the nav link and the old URL both stop working.

**2. Candidate ids travel in the query string (`?ids=id1,id2`).**
`ComparisonLive.Index` reads the ids in `mount` via `params["ids"]`, splits on comma, and runs `compare_candidates/1` immediately. Without ids (or with an invalid count) it assigns an empty/error state. The `~p` sigil only allows one interpolation per query param, so the navigation target is built with a single `Enum.join` interpolation. Alternative considered: path params (`/candidates/compare/:ids`) — rejected because commas in a path segment are awkward and the query string is conventional for id lists. Shareable URLs fall out naturally.

**3. Selection UI removed from the comparison page.**
`toggle_candidate`, `compare`, and `clear_comparison` handlers and the on-page checkbox list are deleted; `candidates` no longer needs to be loaded on mount. The page is a pure render of the URL state. The `Candidates` alias is dropped accordingly.

**4. Compare as a bulk action + `push_navigate`.**
The bulk bar gains `<option value="compare">Compare</option>` and a confirm button gated on `@bulk_action == "compare"`, exactly like Merge. The handler `bulk_execute_compare` joins `selected_ids` and calls `push_navigate` to the compare URL. `selected_ids` are UUID strings (from `phx-value-id`), which `compare_candidates/1` already accepts.

**5. Fix the broken action selects by wrapping them in `<form>`.**
LiveView JS requires a containing form to serialize `phx-change` inputs. The action select and the stage select are each wrapped in a plain `<form>` while keeping `phx-change` on the `<select>` itself. Keeping `phx-change` on the element (rather than the form) preserves `Phoenix.LiveViewTest.render_change/3` selectors used by the existing bulk-email tests, and LiveView JS reads the input's own `phx-change` while using the form for serialization. Alternative considered: moving `phx-change` to the form — rejected because existing tests target the select element directly and would break.

## Risks / Trade-offs

- [Order of `selected_ids` in the URL is selection-order dependent] → Acceptable: ids are unique and order is cosmetic in the comparison grid; tests assert the exact joined order matching the toggle handler's prepend behavior.
- [Direct visits to `/app/candidates/compare` without ids show an empty state] → Intended behavior, documented in the delta spec (empty state prompting to select from the list).
- [Commas in query-string values] → UUIDs contain no commas; splitting on comma is safe. Long lists (3 ids max) keep URLs well within limits.
- [Old `/app/compare` bookmarks stop working] → Accepted; the nav entry is removed and the comparison is reachable from the candidates list only.
