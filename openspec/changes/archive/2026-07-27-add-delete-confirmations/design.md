## Context

The Treby app has ~12 delete actions spread across candidates, pipeline, and settings LiveViews. None show a confirmation dialog before executing. The app uses Phoenix LiveView with a `core_components.ex` module that already provides shared UI primitives (`flash`, `button`, `input`, `header`, `table`, `icon`). There is no existing modal or dialog component.

The pipeline stage delete already has a custom reassignment confirmation flow — this is left as-is since it has domain-specific logic.

## Goals / Non-Goals

**Goals:**
- Single reusable confirmation modal component usable from any LiveView
- Minimal boilerplate: each LiveView only needs to set an assign and handle one new event
- Consistent look and feel across all delete confirmations
- Keyboard accessible (Escape to cancel, Enter to confirm)

**Non-Goals:**
- Undo functionality (out of scope, would require a separate change)
- Confirmation for non-delete destructive actions (e.g., closing a job)
- Modifying the existing pipeline stage reassignment dialog

## Decisions

### 1. Server-side confirmation via assigns, not client-side JS confirm()

**Decision:** Use a LiveView assign (`confirm_delete`) to track pending deletions, render a modal component, and only execute the actual delete on a separate "confirm" event.

**Why:** `window.confirm()` is unstyled, inconsistent, and blocks the process. A server-rendered modal integrates with the design system and allows rich content (e.g., showing what will be deleted). The two-event pattern (click delete → confirm) is idiomatic LiveView.

**Alternatives considered:**
- Client-side `JS.confirm()` via `Phoenix.LiveView.JS` — rejected because it's unstyled and inaccessible
- Inline confirmation (button turns red on first click) — rejected because it's non-standard and easy to accidentally confirm

### 2. Modal as a core component, not a hook

**Decision:** Add `<.confirm_modal>` to `core_components.ex` as a function component that renders a styled overlay + dialog.

**Why:** Core components are already the pattern for shared UI in this app. A function component keeps everything server-rendered and avoids JS hook complexity.

### 3. Single assign pattern for all delete confirmations

**Decision:** Each LiveView that has delete actions adds a `confirm_delete` assign (default `nil`). When set to `%{id: ..., title: ..., message: ...}`, the modal renders. Two new events: `"confirm_delete"` (sets the assign) and `"cancel_delete"` (clears it). The existing delete event handler is renamed with a `do_` prefix (e.g., `do_delete_candidate`).

**Why:** Keeps the pattern consistent across all LiveViews. The `confirm_delete` assign is a simple enum/tagged tuple that the modal template pattern-matches on.

## Risks / Trade-offs

- **Boilerplate in each LiveView** → Each LiveView needs ~15 lines of new code (assign default, two event handlers, modal markup in template). Acceptable for the safety benefit.
- **Modal z-index conflicts** → Use a high z-index (50) and a backdrop overlay to prevent interaction with content behind it.
- **Mobile responsiveness** → Modal must be responsive and not overflow on small screens. Use max-w-md with responsive padding.
