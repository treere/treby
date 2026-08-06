## Context

A UI audit of the running app exposed a cross-cutting form-submission bug plus five isolated defects. The Design System button (`TrebyWeb.DesignSystem.Button`, wrapped by `core_components.button/1`) renders `type="button"` regardless of the caller's `type="submit"`, so roughly twenty `phx-submit` forms across jobs, candidates, custom fields, branding, team, and settings silently never fire their submit event. The standalone bugs are: copied public job links lack the hostname; editing a scheduled email crashes on `Time.from_iso8601!("23:49")`; the bulk email composer's `phx-change` inputs sit outside any `<form>` (LiveView raises `form events require the input to be inside a form`); pressing Enter in the candidate search triggers a native reload that ignores the query param; and the "select" custom-field type never reveals its options textarea.

All affected code is in LiveView templates and handlers. No DB schema, dependency, or routing changes are required.

## Goals / Non-Goals

**Goals:**
- Make every `.button type="submit">` render and behave as a real submit button, restoring submission for all currently-broken forms.
- Fix the five standalone defects so each affected flow works end to end.

**Non-Goals:**
- Redesigning the Design System button API or adding new variants.
- Changing `bulk_execute_send_email` behavior or the bulk email data model.
- Adding an audit trail or changing email-scheduling semantics.
- General UI/UX polish beyond what the defects require.

## Decisions

### 1. Design System button: pass `type` through (cross-cutting)
Two changes, both required:
- `core_components.ex:105` — the wrapper re-declares `attr :rest, :global, include: ~w(href navigate patch method download name value disabled)` and **omits `type`**, so `type="submit"` is silently discarded before it ever reaches the Design System component. Add `form type` to the include list.
- `design_system/button.ex:49` — replace the static `type="button"` with `type={@rest[:type] || "button"}`. LiveView gives precedence to a statically-set attribute over a value arriving via `{@rest}`, so the hardcoded value would keep winning even after the wrapper fix.

*Alternative considered:* removing the wrapper's `include:` filter entirely and letting all globals pass. Rejected — the explicit allowlist is deliberate and limiting; an additive fix is safer.

*Verification:* assert rendered DOM `<button type="submit">` on the Custom Fields Save button, then re-run the save flow and confirm `HANDLE EVENT "save_field"` in the logs. Grep all 23 `type="submit"` call sites and spot-check a job create/edit form.

### 1b. Confirm dialog: pass `extra_attrs` as `phx-value-*` (found during delete-flow tests)
The `confirm_dialog/1` component (`design_system/pattern.ex:41`) declared `attr :extra_attrs, :map` and spread `{@extra_attrs}` onto the confirm button, which rendered literal attributes like `user_id="123"` instead of `phx-value-user_id="123"`. Handlers expecting `%{"id" => id}` (all existing confirm handlers) silently received `%{}`. Fix: a private helper `phx_value_attrs/1` at `pattern.ex:74` maps each key to `:"phx-value-#{key}"`, and the button spreads `{@extra_phx_value_attrs}`. Existing callers pass `extra_attrs={%{id: @field.id}}` and their `%{"id" => id}` handlers now work unchanged.

### 2. Custom Fields: reveal options textarea and make Save work
- Add `phx-change="validate"` to the **`<.form>` element** (not the select — a form-level change event fires for any input change) on the create/edit form at `fields.ex:56` so selecting "Select (options)" round-trips to the server; today the conditional `<div :if={@form[:field_type].value == "select"}>` at `fields.ex:92` can never render because the server never learns the new type.
- Add `handle_event("validate", ...)` at `fields.ex:188` that rebuilds the form with `Customization.change_custom_field/2` and stores the raw `options_text` in a new `@options_text` assign.
- Change the options textarea value source from `Enum.join(@form[:options].value || [], "\n")` to `@options_text`, so typed options survive the re-render caused by a type change.
- Saving then works via Decision 1 (`.button type="submit">` actually submits) and the existing `save_field` handler, which already reads `params["options_text"]`.

*Alternative considered:* binding the textarea to `@form[:options]` and deleting `options_text`. Rejected — bigger refactor of the changeset cast; the existing handler already consumes `options_text`.

### 3. Email Queue: accept `HH:MM` from `<input type="time">`
In `email_queue_live/index.ex` (`handle_event("save_edit")`, ~line 101), normalize before parsing: when the value matches `HH:MM` (5 chars), append `:00` before parsing. A single small private helper `parse_time/1` (not `parse_time!/1`) at `index.ex:232` returns `{:ok, time}` or `:error` — it never raises; a genuinely invalid value surfaces a validation flash instead of crashing the LiveView.

*Alternative considered:* setting `step="1"` on the time input to force `HH:MM:SS`. Rejected — server-side normalization is robust regardless of browser time-input formatting, and existing rows already store `HH:MM`-derived values.

### 4. Bulk email composer: wrap inputs in a `<form>`
The composer inputs (`bulk_email_subject_change`, `bulk_email_body_change`, `bulk_email_schedule_date_change`, `bulk_email_schedule_time_change`) each carry their own `phx-change` and are valid once they live inside a form element. Wrap the composer body (subject, textarea, schedule date/time) in `<form id="bulk-email-composer" phx-submit="bulk_email_composer_submit">` and add a no-op `handle_event("bulk_email_composer_submit", ...)` to swallow the native submit — otherwise Enter in the subject field would do a native page reload.

*Alternative considered:* consolidating to a single form-level `phx-change` + one handler that updates all bulk assigns. Rejected — the per-field handlers and assigns already exist; wrapping is minimal and lower risk.

### 5. Candidate search: submit in place and honor URL params
- Add `phx-submit="search_submit"` to the search form (`candidates_live/index.ex:80`) and a `handle_event("search_submit", %{"search" => search}, socket)` that reuses the same filtering logic as the existing `handle_event("search", ...)` (extract a shared private helper so both paths stay identical). This prevents Enter from performing the native GET that reloads to `?search=...`.
- In `mount/3`, initialize `search`, `job_id`, and `stage_id` from the query params map (`params["search"]`, `params["job_id"]`, `params["stage_id"]`) so a page load with `?search=carol` filters immediately instead of showing all candidates.

### 6. Copy Public Link: absolute URL
At `jobs_live/show.ex:44`, build the copied value from the endpoint's configured origin: `data-url={TrebyWeb.Endpoint.url() <> ~p"/#{@current_tenant.slug}/careers/#{@job.id}"}`. `Endpoint.url()` honors the `:url` config (`host`, `port`, `scheme`), so dev (`http://localhost:4000`) and prod both get a usable absolute URL.

*Alternative considered:* reading the socket's `uri`. Rejected — `Endpoint.url()` is the established way the app already builds absolute URLs (e.g., email links) and requires no new wiring.

## Risks / Trade-offs

- **Button fix changes rendering of every `.button`** → Only templates that explicitly pass `type="submit"` change behavior; the default stays `"button"`. Grep the 23 call sites and spot-check forms that intentionally should not submit.
- **LiveView static-vs-dynamic attribute precedence** → Relying on `type={@rest[:type] || "button"}` (dynamic) instead of static, so no precedence trap remains; still verify via rendered DOM before/after.
- **Custom Fields validate re-render can lose typed options** → Mitigated by tracking `@options_text` and rendering the textarea from it, not from the changeset.
- **`Endpoint.url()` misconfigured behind a proxy** → Same origin config every other absolute URL uses; no new risk, but prod config must match the public host.
- **No automated coverage for these UI paths** → Add focused LiveView tests (or at minimum re-run the manual flows) for: custom field save, email queue edit save, bulk composer change, search Enter + `?search=` load, and copy-link markup.
  - Added: button `type` rendering tests, confirm-dialog `phx-value-*` tests, custom-field delete-flow test, empty-search test (clearing shows all candidates), and email-queue save/reschedule tests. In the test env Oban runs with `testing: :inline` (`config/test.exs`), so jobs execute in-process and are **not** persisted to `oban_jobs`; the reschedule test therefore asserts the observable outcome (the email is sent and its status flips to `"sent"` after save) rather than asserting on the jobs table.

## Migration Plan

- All changes are server-side template/handler edits; ship as one commit. No data migration or rollout ordering needed.
- Rollback: revert the commit; the app returns to its previous (broken) behavior, with no data state to unwind.
