## Why

Career pages (`/:tenant_slug/careers` and `/careers`) are not discoverable from the public landing page (`/`). Candidates landing on the homepage have no navigation path to browse open positions, reducing application funnel entry points observed during Playwright exploration.

## What Changes

- Add a "Careers" / "Open positions" navigation entry on the landing page header (visible to anonymous visitors) linking to the global board `/careers`.
- Add a careers link in the landing page hero/CTA section and in the footer.
- Add a tenant-aware "View careers" link where relevant (post-apply Thank You already has "View other positions"; this extends discoverability before apply).
- Ensure active-state styling and responsive behavior (mobile drawer) for the new link.

## Capabilities

### New Capabilities
- _none_ — this change enhances existing navigation, no new capability.

### Modified Capabilities
- `landing-page`: add navigation requirement for public careers discovery.
- `public-job-board`: clarify entry point from landing page (no behavioral change to board itself, only discovery).
- `career-page`: clarify that thank-you / navigation back to careers is part of discoverability (minor wording update).

## Impact

- `lib/treby_web/live/home_live.ex` — header nav + footer + hero CTA.
- `lib/treby_web/components/layouts.ex` — if shared layout used, ensure locale/theme toggles remain.
- `site/` docs — update landing-page / career-page user manual sections, regenerate screenshots.
- No DB migration, no API breaking change, no new dependencies.
