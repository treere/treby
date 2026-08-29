# Design: Fix delete confirmation modal

## Context

The `<.confirm_modal>` component in `core_components.ex` builds an assigns map for
`Pattern.confirm_dialog/1` with a hard-coded `__changed__: %{}`. LiveView's component
diffing (Phoenix.Components `assign/3` + `diff.ex` `process_keyed/5`) uses `__changed__`
to decide which assigns re-render on the next diff. A forced empty map means the dialog's
**slot content** (message paragraph + footer buttons) is excluded from every subsequent
diff, so it freezes to the state from the first render.

On every page the first render happens with `confirm_delete = nil`, so:
- the message is always blank (cosmetic bug on all move-views),
- the candidates index confirm button stays wired to the fallback default
  `phx-click="confirm_delete"` instead of `do_delete_candidate`.

Clicking that button posts `confirm_delete %{"id" => ..., "value" => ""}`, which matches no
`handle_event` clause in `CandidatesLive.Index` (`index.ex:607-632` require `title`/`message`)
→ `FunctionClauseError` → LiveView crash → candidate cannot be deleted.

Verified in a running session: `:sys.get_state(pid).socket.assigns.confirm_delete` holds the
correct full map (`on_confirm: "do_delete_candidate"`, full message) while the browser DOM
keeps the stale button and an empty `<p>`.

## Goals / Non-Goals

**Goals:**
- Every confirmation dialog shows the current message of `confirm_delete`.
- The confirm button always fires the intended delete action, and confirming actually deletes.
- No LiveView crash is possible from a stale/legacy confirm button.
- All other LiveView delete flows keep working (team, fields, sources, pipeline, scorecards,
  email templates, availability, candidates show).

**Non-Goals:**
- No visual/design changes to the dialog.
- No changes to the bulk-delete flow behavior.

## Decisions

### D1. Force the confirmation dialog to fully re-diff on every render
Replace the hard-coded `__changed__: %{}` in `confirm_modal/1` with a marker that marks every
assign changed (`__changed__: nil` is the supported "everything changed" sentinel — see
`Phoenix.LiveView.Utils.changed?/2`). The dialog subtree (slots included) is then re-sent on
every render, so the message and button wiring always match the current `confirm_delete`.

- **Alternative considered:** per-key change tracking. Requires plumbing value-change detection
  through the hand-built assigns map and re-introduces the stale-slot risk; rejected for
  complexity with no benefit for a single small modal.
- **Alternative considered:** route all calls through HEEx `<.confirm_dialog>` so the compiler
  manages `__changed__`. Touches every caller and the deprecated compatibility surface; the
  minimal in-place change covers the same behavior.

### D2. Candidates index: static `on_confirm="do_delete_candidate"`
Pass a static `on_confirm` on the candidates index `<.confirm_modal>` call, matching every
other LiveView in the app (`team.ex`, `fields.ex`, `sources.ex`, …). Removes dependence on the
diff behavior for the button wiring.

- **Alternative considered:** keep the dynamic `if @confirm_delete, do: ..., else: ...`
  expression. Once D1 lands it would work, but it is fragile and inconsistent with the rest of
  the codebase; rejected.

### D3. Defensive handler for id-only `confirm_delete` payloads
Add `handle_event("confirm_delete", %{"id" => id}, socket)` that delegates to the existing
single-delete logic. Any legacy/stale client button (e.g. from a pre-fix session already in a
browser tab) then performs the delete instead of crashing the LiveView.

- **Alternative considered:** ignoring/clearing the modal on unknown payloads. Safer UX to
  actually execute the intended delete; the payload explicitly carries the entity id.

### D4. Fix success matching in the shared delete logic
When extracting `do_delete_candidate`'s body into a private `delete_candidate/2` helper, the
`Candidates.delete_candidate/2` return is matched as `{:ok, _candidate}` instead of the literal
`:ok`. `Ecto.Repo.delete/1` returns `{:ok, schema}` on success, so the previous literal never
matched and every delete fell into the `{:error, _}` branch (deletion still happened via
`Repo.delete`, but with no success flash and no list refresh).

## Risks / Trade-offs

- Always re-rendering the dialog adds a negligible per-render cost (one small component).
- [Stale-clients] A browser tab holding a pre-fix socket could still send an id-only
  `confirm_delete` → mitigated by D3.
- [Masking wiring regressions] D3 turns future wiring mistakes into (recoverable) deletes
  instead of loud crashes → acceptable for a destructive action; the modal wiring is
  covered by tests.
- [Behavior change in other pages] Force re-render makes the (currently blank) confirmation
  messages appear on all pages. Intended, consistent with the existing spec of the
  `delete-confirmations` capability.

## Migration Plan

No migration or data changes. Deploy by normal code rollout; LiveView hot-reloads modules in
dev. Rollback is a git revert of this change.

## Open Questions

None.