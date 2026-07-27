## Why

Delete actions across the app (candidates, bulk operations, settings entities, notes) execute immediately on click with no confirmation. Accidental clicks permanently destroy data with no recovery path. This is especially dangerous for bulk delete operations where a single misclick can wipe many records.

## What Changes

- Add a reusable `<.confirm_modal>` component to core_components.ex
- Wrap all existing delete event handlers with a confirmation step: clicking "Delete" opens a modal; the actual deletion only fires on explicit confirmation
- Affected delete actions: single candidate delete, bulk candidate delete (candidates index + pipeline), custom field delete, scorecard template delete, source delete, pipeline delete, availability rule delete, email template delete, team member removal, invite revocation, note delete
- Pipeline stage delete already has a custom confirmation flow (reassignment dialog) — leave as-is

## Capabilities

### New Capabilities
- `delete-confirmations`: Reusable confirmation modal component and wiring for all delete actions

### Modified Capabilities

## Impact

- `lib/treby_web/components/core_components.ex` — new `<.confirm_modal>` component
- `lib/treby_web/live/candidates_live/index.ex` — single + bulk delete confirmation
- `lib/treby_web/live/candidates_live/show.ex` — note delete confirmation
- `lib/treby_web/live/pipeline_live/index.ex` — bulk delete confirmation
- `lib/treby_web/live/settings_live/fields.ex` — field delete confirmation
- `lib/treby_web/live/settings_live/scorecards.ex` — template delete confirmation
- `lib/treby_web/live/settings_live/sources.ex` — source delete confirmation
- `lib/treby_web/live/settings_live/pipeline.ex` — pipeline delete confirmation
- `lib/treby_web/live/settings_live/availability.ex` — rule delete confirmation
- `lib/treby_web/live/settings_live/email_templates.ex` — template delete confirmation
- `lib/treby_web/live/settings_live/team.ex` — user removal + invite revocation confirmation
