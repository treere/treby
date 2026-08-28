## Context

LiveView event handlers bound through `phx-change` / `phx-submit` require the input controls to be wrapped in a `<form>` element carrying those attributes. The pipeline bulk action bar renders the stage `<select phx-change>` and the move button outside any form, so the browser client raises:

```
form events require the input to be inside a form
```

The dropdown never populates because the change event never reaches the server. The same pattern exists on the Interviews filter (`interviews_live/index.ex:207-221`, interviewer `<select>`) and the Import page pipeline select (`import_live/index.ex`).

## Goals / Non-Goals

**Goals:**
- "Move to Stage" works from the pipeline board action bar with no console errors.
- Eliminate all bare `phx-change` controls outside forms.

**Non-Goals:**
- Not changing bulk operation handler logic or data flow.

## Decisions

- Wrap the bulk action bar controls in a `<.form for={...} id="bulk-action-form">` with `phx-change="bulk_change"` and `phx-submit` handlers, driving fields through the existing form assign (`to_form(%{})`).
- Apply the identical wrapping to the interviews filter `<select>` and the import pipeline `<select>`.

## Risks / Trade-offs

- [Nested forms / layout impacts in the action bar] → Mitigation: the form wraps only the bar controls; no other forms are nested inside it.
- [Behavioral regression risk from moving event bindings] → Mitigation: reuse the exact existing event names so server handlers are untouched.