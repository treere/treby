## 1. Design System submit button fix (cross-cutting)

- [x] 1.1 Add `type` and `form` to the `attr :rest` include list in `core_components.ex:105` so the wrapper stops discarding `type="submit"`
- [x] 1.2 Replace the static `type="button"` with `type={@rest[:type] || "button"}` in `design_system/button.ex:49`
- [x] 1.3 Verify rendered DOM: a `<.button type="submit">` (e.g. Custom Fields Save) now renders `<button type="submit">`
- [x] 1.4 Spot-check the 23 `type="submit"` call sites (create/edit job, add/edit candidate, branding, team, sources, pipeline stages, email templates, language, availability) and confirm their `phx-submit` events now reach the server

## 2. Custom Fields: options textarea + working save

- [x] 2.1 Add `phx-change="validate"` to the custom-field form in `settings_live/fields.ex` so changing type round-trips the whole form to the server
- [x] 2.2 Add `handle_event("validate", ...)` that rebuilds the form via `Customization.change_custom_field/2` and preserves the raw `options_text` in an `@options_text` assign
- [x] 2.3 Change the options textarea value source to `@options_text` (initialized to `""`) so typed options survive re-renders
- [x] 2.4 Verify: selecting "Select (options)" immediately reveals the options textarea; toggling the type preserves typed options; Save creates the field and closes the form

## 3. Email Queue: fix time parsing crash

- [x] 3.1 Add a `parse_time/1` helper in `email_queue_live/index.ex` that appends `:00` for `HH:MM` values before parsing
- [x] 3.2 Use it in `handle_event("save_edit")` (~line 102) and surface a validation flash for genuinely malformed times instead of raising
- [x] 3.3 Verify: editing a scheduled email, saving with a time like `23:55` succeeds, reschedules the Oban job, and does not crash the LiveView

## 4. Bulk email composer: wrap inputs in a form

- [x] 4.1 Wrap the subject, body, and schedule date/time inputs in `<form id="bulk-email-composer" phx-submit="bulk_email_composer_submit">` in `candidates_live/index.ex`
- [x] 4.2 Add a no-op `handle_event("bulk_email_composer_submit", ...)` so Enter in the composer does not trigger a native page reload
- [x] 4.3 Verify: typing in subject/body/date/time produces no "form events require the input to be inside a form" error and the per-field `phx-change` events reach the server

## 5. Candidate search: no reload + URL params honored

- [x] 5.1 Extract the search filtering logic into a shared private helper and add `handle_event("search_submit", ...)` in `candidates_live/index.ex`
- [x] 5.2 Add `phx-submit="search_submit"` to the search form (~line 80)
- [x] 5.3 Initialize `search`, `job_id`, and `stage_id` from the mount query params (`params["search"]`, `params["job_id"]`, `params["stage_id"]`)
- [x] 5.4 Verify: Enter performs the search in place (no reload, term preserved) and loading `/app/candidates?search=carol` filters immediately

## 6. Copy Public Link: absolute URL

- [x] 6.1 Build the link value in `jobs_live/show.ex:44` as `TrebyWeb.Endpoint.url() <> ~p"/#{@current_tenant.slug}/careers/#{@job.id}"`
- [x] 6.2 Verify the clipboard receives the full absolute URL including hostname (e.g. `http://localhost:4000/acme/careers/...`)

## 7. Verification & polish

- [x] 7.1 Run `mix precommit` and fix any pending issues
- [x] 7.2 Add/update LiveView tests for: custom field save, email queue edit save, bulk composer change, search Enter + `?search=` load, and copy-link markup
- [x] 7.3 If any affected page is showcased in `site/`, regenerate screenshots with `node scripts/screenshots.mjs` and update `site/features/`
