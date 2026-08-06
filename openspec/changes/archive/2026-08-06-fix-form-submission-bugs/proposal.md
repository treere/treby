## Why

A UI audit with the live app found that form submission is broken app-wide: the Design System button renders `type="button"` even when templates pass `type="submit"`, so ~20 forms (create/edit job, add/edit candidate, custom fields, branding, team invites, etc.) can never submit. The audit also found five additional standalone bugs: the public job link is copied without its hostname, editing a scheduled email crashes on time parsing, the bulk email composer fields never reach the server, pressing Enter in the candidate search triggers a native page reload that loses the search, and the "select" custom field type never reveals its options textarea.

## What Changes

- **Design System submit buttons** (`core_components.ex` + `design_system/button.ex`): `.button type="submit"` will render as `type="submit"` so the enclosing form submits. This is the cross-cutting fix that unblocks the ~20 currently-broken forms.
- **Custom Fields** (`settings_live/fields.ex`): the "Select (options)" type immediately reveals the options textarea, and the Save button actually submits so fields can be created/edited.
- **Email Queue** (`email_queue_live/index.ex`): saving edits to a scheduled email accepts `HH:MM` times from `<input type="time">` instead of crashing on `Time.from_iso8601!`.
- **Bulk email composer** (`candidates_live/index.ex`): the subject/body/date/time inputs are placed inside a real `<form>` so their `phx-change` events reach the server instead of raising "form events require the input to be inside a form".
- **Candidate search** (`candidates_live/index.ex`): pressing Enter in the search box performs the search in place (no native page reload) and the URL query params are honored on page load.
- **Copy Public Link** (`jobs_live/show.ex`): the copied link is a full absolute URL including the hostname, not just a bare path.

## Capabilities

### New Capabilities
- `form-submission`: Form submit buttons rendered by the Design System behave correctly (render as `type="submit"` and submit their enclosing form), guaranteeing `phx-submit` forms across the app actually fire.

### Modified Capabilities
- `custom-fields`: creating a custom field actually saves, and the "select" type reveals its options editor.
- `email-scheduler`: editing a scheduled email accepts `HH:MM` time input and saves without crashing.
- `bulk-operations`: the bulk email composer fields send events to the server (inputs live in a form).
- `candidate-search`: Enter-triggered search works without a page reload and URL search params are honored.
- `public-job-board`: Copy Public Link copies the full absolute public URL, including the hostname.

## Impact

- `lib/treby_web/components/core_components.ex`: wrapper `button/1` rest attr include list drops `type`.
- `lib/treby_web/components/design_system/button.ex`: hardcoded `type="button"` overrides caller's `type`.
- `lib/treby_web/live/settings_live/fields.ex`: select type has no `phx-change`; save depends on fixed submit button.
- `lib/treby_web/live/email_queue_live/index.ex`: `Time.from_iso8601!("23:49")` raises; needs seconds or `Time.new/2`.
- `lib/treby_web/live/candidates_live/index.ex`: bulk composer inputs outside a `<form>`; search form lacks `phx-submit` and mount ignores params.
- `lib/treby_web/live/jobs_live/show.ex`: `~p` path used as `data-url` for the clipboard hook.
- No database or dependency changes. All fixes are server-rendered template/controller logic plus one JS-adjacent attribute change.
