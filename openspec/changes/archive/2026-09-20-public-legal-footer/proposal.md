## Why

`/terms` and `/privacy` exist and return 200, but no public page links to them: the landing footer only had a Careers link and the public career pages had no footer at all. The legal pages were unreachable from the UI.

## What Changes

- Add a shared `Layouts.public_footer` component with the product name, tagline, copyright, and links to `/careers`, `/terms`, `/privacy`.
- Use it on the landing page and on the public career pages (tenant index, global index, job detail, application form).

## Capabilities

### New Capabilities
- (none)

### Modified Capabilities
- `landing-page`: the footer requirement now includes links to the legal pages, not only Careers.
- `career-page`: public career pages render the shared footer with the legal links.

## Impact

- Spec: `openspec/specs/landing-page/spec.md`, `openspec/specs/career-page/spec.md`.
- Code: `lib/treby_web/components/layouts.ex` (new `public_footer/1`), `lib/treby_web/live/home_live.ex`, `lib/treby_web/live/careers_live/{index,global_index,show,apply}.ex`.
- Tests: `test/treby_web/live/home_live_test.exs`, `test/treby_web/integration/career_page_test.exs`.
