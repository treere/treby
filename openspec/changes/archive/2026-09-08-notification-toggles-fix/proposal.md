## Why

Settings → Notifications shows three preference toggles, but users report
nothing looks changeable there. Investigation found the toggle ON-state
relies on a `primary` color that no source file defines (it exists only in
stale compiled CSS), so switch state is likely invisible or will vanish on
the next asset rebuild. The specified behavior (visible, working toggles)
needs restoring and end-to-end proof.

## What Changes

- Define the `primary` color in CSS sources (Tailwind v4 `@theme`) using the
  value currently relied upon, or migrate toggle/state styling to existing
  design tokens if the audit prefers them.
- Verify each of the three admin toggles flips state visibly and persists
  to the tenant settings (LiveView test + Playwright check on the real page).
- Rebuild assets and confirm no other `*-primary` styling regresses.
- No behavior or copy changes; no migrations.

## Capabilities

### New Capabilities
- None.

### Modified Capabilities
- `email-notifications`: the "Toggle notification type" scenario must hold
  visibly (switches reflect and persist state) — bugfix restoring specified
  behavior, no requirement text change expected unless the audit finds more.

## Impact

- `assets/css/app.css` (theme definition), possibly the notifications
  LiveView classes if migrated to tokens.
- Rebuilt CSS/JS in `priv/static` (build artifact, not committed... verify).
- Tests: new LiveView test for admin toggles; Playwright verification script
  run (not committed unless repo convention says otherwise).
