## Why

The Live `/404` page rendered inside `Layouts.app`, so a logged-in user saw the authenticated app chrome (navigation/sidebar) around a not-found message, and its CTAs pointed at the legacy `/app/jobs` and `/app` routes. The static 404 for non-Live paths is already a standalone public page.

## What Changes

- Render `ErrorLive.NotFound` with the public header and footer instead of the authenticated app shell.
- Replace the CTAs with "Browse all positions" (`/careers`) and "Go to homepage" (`/`).

## Capabilities

### New Capabilities
- (none)

### Modified Capabilities
- `not-found-page`: the `/404` page is explicitly public (public header/footer, no app chrome) and links to the global job board and homepage.

## Impact

- Spec: `openspec/specs/not-found-page/spec.md`.
- Code: `lib/treby_web/live/error_live/not_found.ex`.
- Tests: `test/treby_web/live/not_found_test.exs`.
