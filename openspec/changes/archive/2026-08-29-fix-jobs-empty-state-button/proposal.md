## Why

The "Create your first job" button on the jobs empty state (`/app/jobs`) is a dead link — it points to `href: "#"`, so clicking it does nothing. New users are stuck on an empty page with no obvious way forward.

## What Changes

- Replace the `action` map with the `:cta` slot in the jobs index empty state so the button triggers `phx-click="show_create_form"`, revealing the inline job creation form.
- Strengthen the empty-state test to assert the button click opens the create form (previously only text presence was checked, which cannot catch a dead link).

## Capabilities

### New Capabilities

### Modified Capabilities
- `onboarding`: clarify that the "Create your first job" button on the jobs page opens the inline job creation form.

## Impact

- `lib/treby_web/live/jobs_live/index.ex` — empty state action replaced with CTA slot.
- `test/treby_web/live/jobs_live_test.exs` — added interaction assertion.
- `openspec/specs/onboarding/spec.md` — requirement clarified.