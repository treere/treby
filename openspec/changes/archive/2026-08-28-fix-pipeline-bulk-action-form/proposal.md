## Why

The "Move to Stage" dropdown in the pipeline bulk action bar never opens. Its stage `<select>` and move button are rendered outside a `<form>` element, which produces the client-side error "form events require the input to be inside a form" and prevents the server from ever handling the `phx-change` event.

## What Changes

- The pipeline board bulk action bar wraps the stage `<select>` and confirm button inside a proper `<form>` (with `phx-change`), so the "Move to Stage" dropdown populates and works.
- The same broken pattern is fixed wherever it appears:
  - Interviews page filter select (`interviews_live/index.ex:207-221`).
  - Import page pipeline select (`import_live/index.ex`).

## Capabilities

### New Capabilities
- None.

### Modified Capabilities
- `bulk-operations`: "Bulk move to stage" works from the action bar without console errors.
- `pipeline`: "Bulk move candidates" scenario satisfied from the board action bar.

## Impact

- `lib/treby_web/live/pipeline_live/index.ex` (bulk action bar).
- `lib/treby_web/live/interviews_live/index.ex` (filter).
- `lib/treby_web/live/import_live/index.ex` (pipeline select).