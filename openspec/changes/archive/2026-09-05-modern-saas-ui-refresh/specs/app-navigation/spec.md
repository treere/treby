## MODIFIED Requirements

### Requirement: Active link is visually highlighted
The navigation SHALL visually distinguish the link corresponding to the user's current page using the Modern SaaS Minimal active language: `bg-zinc-100 text-zinc-900 rounded-md font-medium` (with `dark:bg-zinc-800`) rather than a blue bottom border.

#### Scenario: Desktop active link highlighting
- **WHEN** a user is on the Candidates page (`/app/candidates`)
- **THEN** the Candidates nav link displays with `bg-zinc-100 text-zinc-900 rounded-md font-medium` (and `dark:bg-zinc-800 dark:text-zinc-100`)
- **AND** all other nav links display with `text-zinc-500 hover:text-zinc-900 hover:bg-zinc-50 rounded-md font-normal`

#### Scenario: Mobile active link highlighting
- **WHEN** a user is on the Analytics page (`/app/analytics`)
- **THEN** the Analytics link in the mobile drawer displays with `bg-zinc-100 text-zinc-900 rounded-md font-medium`
- **AND** all other mobile drawer links display with normal muted styling

## ADDED Requirements

### Requirement: App navigation uses SaaS minimal header
The app navigation header SHALL use the Modern SaaS Minimal header language: sticky translucent `bg-white/80 supports-[backdrop-filter]:bg-white/80 backdrop-blur border-b border-zinc-200` (light) / `bg-zinc-900/80 border-zinc-800` (dark), with nav links as `rounded-md` pills and hover `bg-zinc-50`.

#### Scenario: Desktop header is translucent and minimal
- **WHEN** a logged-in user views the desktop navigation bar
- **THEN** the header has `sticky top-0 bg-white/80 backdrop-blur border-b border-zinc-200` (light) and links are `px-3 py-1.5 rounded-md text-sm font-medium text-zinc-500 hover:text-zinc-900 hover:bg-zinc-50`

#### Scenario: Page background is SaaS minimal
- **WHEN** a user views any app page
- **THEN** the outer page wrapper uses `bg-zinc-50` (light) / `bg-zinc-900` (dark) — not `bg-base-200`
