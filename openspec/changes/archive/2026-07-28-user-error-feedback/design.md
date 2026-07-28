## Context

The app has ~19 `handle_event` callbacks that process form submissions or mutations. Of these, 13 silently re-render the form on changeset failure with no user-facing signal. One (PipelineLive toggle_review) swallows errors completely. One (CareersLive.Apply) crashes on candidate creation failure due to a bare pattern match.

The existing flash infrastructure is fully functional — `put_flash(:error, ...)` works everywhere and the `<.flash_group>` component in the layout renders both `:info` and `:error` flashes. The pattern is already used in ~10+ handlers for non-changeset errors (permission failures, toggle failures, etc.). The gap is specifically in changeset validation failure branches.

## Goals / Non-Goals

**Goals:**
- Every form submission that fails validation shows a visible flash error message
- The public candidate application page handles errors gracefully instead of crashing
- The pipeline toggle_review failure shows feedback instead of being silent
- Consistent flash message pattern across all handlers

**Non-Goals:**
- Custom 404/500 error pages (separate concern, bigger scope)
- Skeleton loading states (separate concern)
- Inline error styling changes (the existing `<.input>` component already handles this)
- Error logging/metrics (operational concern, not UX)

## Decisions

### Decision 1: Flash message text

**Choice:** `"Please review the errors below"` for all changeset failures (including aligning the existing scorecards.ex pattern).

**Rationale:** Short, actionable, non-technical. Tells the user what to do (look below) rather than what went wrong ("validation failed"). Consistent across all forms.

**Alternatives considered:**
- `"Validation failed"` — too technical, doesn't guide action
- `"Please correct the errors below"` — slightly longer, same meaning
- Raw `inspect(traverse_errors(...))` (what scorecards.ex does) — ugly, not user-friendly, leaks internal data structures
- No flash, just inline errors — current behavior, proven insufficient

### Decision 2: Keep form re-render alongside flash

**Choice:** Add flash AND keep the existing `assign(socket, form: to_form(changeset))` pattern.

**Rationale:** The inline field errors from `to_form(changeset)` are valuable for users who scroll to the fields. The flash catches users who don't. Both serve different attention patterns.

**Alternatives considered:**
- Flash only, no form re-render — loses inline field errors
- Inline errors only, no flash — current behavior, proven insufficient

### Decision 3: CareersLive.Apply — wrap bare pattern match in case

**Choice:** Replace `{:ok, candidate} = find_or_create_candidate(...)` with a `case` block that handles `{:error, changeset}` and puts a flash message.

**Rationale:** The bare pattern match is a crash bug. A public applicant with an invalid email (no `@`) crashes the entire LiveView. The `case` approach is consistent with every other handler in the codebase.

### Decision 4: PipelineLive.Index toggle_review — add flash

**Choice:** Add `put_flash(:error, "Failed to update review status")` to the `{:error, _}` branch.

**Rationale:** Consistent with how other toggle failures are handled in the same file (move_candidate, confirm_stage_move both use flash).

## Risks / Trade-offs

- **Flash stacking** — If a user triggers multiple rapid failures, flashes stack. Phoenix flash replaces on the same key (`:error`), so only the latest message shows. This is fine.
- **Flash timing** — Flash auto-dismisses after 8 seconds by default in the `<.flash>` component. For forms with many errors, users might need to scroll. The inline errors persist, so this is acceptable.
- **Scorecards inconsistency** — `settings_live/scorecards.ex` currently uses `traverse_errors` with `inspect()` in flash. We should align it with the new pattern (`"Please review the errors below"`) for consistency. This is a one-line change in that handler.
