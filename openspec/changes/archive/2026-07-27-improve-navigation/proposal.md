## Why

Key features (Pipeline, Import, Compare) are hidden from users — they exist but require knowing the URL. The nav also has no active-link highlighting, so users lose context of where they are. This directly impacts feature discoverability and navigation orientation (UX-004, UX-005).

## What Changes

- Add Pipeline, Import, and Compare links to the desktop and mobile nav
- Add active-link highlighting: the current page's nav link gets a distinct visual style (e.g., blue border, bold text)
- Add missing Logout and locale switcher to the mobile nav drawer
- Ensure the nav remains clean and not overcrowded on smaller screens

## Capabilities

### New Capabilities
- `app-navigation`: The main app navigation component — links, active state detection, mobile drawer completeness

### Modified Capabilities

## Impact

- **Primary file:** `lib/treby_web/components/layouts.ex` — the `app/1` component (desktop nav + mobile drawer)
- **Routes:** No router changes needed — `/app/pipeline/:job_id`, `/app/import`, `/app/compare` already exist
- **No new dependencies**
