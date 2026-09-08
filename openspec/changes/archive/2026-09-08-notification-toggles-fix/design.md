## Context

`*-primary` color utilities (`bg-primary`, `text-primary`, `focus:ring-primary`,
…) are used across ~15 templates, but no source file defines the `primary`
color (no Tailwind v4 `@theme` block, no daisyUI). It exists only in stale
compiled CSS (`--color-primary: oklch(58% .233 277.117)`), so the next asset
rebuild silently drops all primary styling app-wide. The notification
toggles are the first visible victim: their ON state (`bg-primary`) cannot
render. The toggle handler itself (`toggle_preference` → tenant settings)
is sound and covered by pattern precedent; it needs an end-to-end proof.

## Goals / Non-Goals

**Goals:**
- `primary` color defined in CSS sources so all current usages build.
- Admin toggles proven working end-to-end (visible flip + persisted).
- Rebuilt assets verified (no styling regressions).

**Non-Goals:**
- Migrating `*-primary` usages to concrete tokens (orange/zinc) — separate
  cleanup; this change is behavior-preserving by design.
- Changing toggle behavior, copy, or the preference keys.

## Decisions

- **D1: Restore the exact stale value via `@theme`.** Add
  `@theme { --color-primary: oklch(58% .233 277.117); ... }` (plus
  `-content` companion already in the stale build) to `assets/css/app.css`.
  Alternative (migrate everything to orange-600) rejected: it would recolor
  links/rings/buttons across the app — a visual redesign disguised as a fix.
- **D2: Prove with two layers.** A LiveView test asserts toggle flips state
  and persists to tenant settings (fast, committed). A Playwright script
  drives the real page in Chromium: login → notifications → click toggle →
  assert track class flips → reload → assert persisted (user explicitly asked
  for Playwright verification; the script lives in `/tmp`, not the repo).
- **D3: Rebuild + screenshot diff.** Run the asset build and re-capture an
  affected page; the only intended visual delta is a visible toggle ON
  state.

## Risks / Trade-offs

- [Risk] Real browsers may already cache stale CSS → Mitigation: Playwright
  uses a fresh profile; fingerprinted asset names change on rebuild anyway.
- [Risk] Other pages depended on the *absence* of primary styles →
  Mitigation: restoring the previously-shipped value returns to the
  long-standing look; screenshot spot-check confirms.
