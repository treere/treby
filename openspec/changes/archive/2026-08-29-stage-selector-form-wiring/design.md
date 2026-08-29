## Context

The job-page candidate workspace renders a per-card stage selector driven by `phx-change`. Phoenix LiveView only dispatches `phx-change` reliably for inputs **inside a `<form>`**; a bare select outside a form raises `form events require the input to be inside a form` in the browser console and never reaches the server. The Kanban bulk-action bar already follows this rule (`<.form for={@bulk_form} id="bulk-action-form">` wrapping its selects in `pipeline_live/index.ex`).

## Goals / Non-Goals

**Goals:**
- Make the per-card stage move work end-to-end in the browser.
- Mirror the existing form-wiring pattern used by the Kanban bulk bar.

**Non-Goals:**
- Changing the `move_application` handler or the permission gating.
- Introducing a new component.

## Decisions

### D1. Wrap each selector in a `<.form>` with a hidden `application_id`
Each card renders `<.form for={%{}} id={"move-form-#{application.id}"} phx-change="move_application">` containing a hidden `<input name="application_id">` and the `<select name="stage_id">`. The handler's params pattern (`%{"application_id" => _, "stage_id" => _}`) is unchanged. `for={%{}}` is already used elsewhere in this view (roles and reassign forms).

### D2. Label the control "Move to stage"
A small uppercase label above the select makes the affordance explicit, addressing the "I don't understand how to change state" confusion.

### D3. Regression assertions in LiveView tests
The test asserts the select is nested inside the move form (`#move-form-#{id} #move-select-#{id}`) and that a real `move_application` params payload updates the stage — guarding against silent console-error regressions.

## Risks / Trade-offs

- **Nested forms**: cards are standalone (no outer form), so the wrapper form cannot nest — no issue.
- **Existing tests** that fire `render_change("move_application", ...)` bypass the DOM and remain valid.

## Migration Plan

- Already implemented; this change formalizes and syncs the requirement. No data migration.