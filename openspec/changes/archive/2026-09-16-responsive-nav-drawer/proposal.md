## Why

The app top navigation renders 8 inline links (Jobs, Candidates, Assistant, Import, Interviews, Analytics, Message Queue, Settings) plus a right-side group (notifications, theme, locale, user name, logout). Measured with Playwright across viewport widths: the nav content needs ~1280px, but the inner container is capped at `max-w-7xl` (1280px) with `px-8` padding, leaving ~1216px usable. Result: a horizontal page scroll appears from **640px up to ~1280px** — covering tablets and common 1280/1366 laptops. The mobile hamburger drawer only appears below 640px (`sm:hidden`), so across the entire 640–1280 band the inline links overflow with no usable fallback. We need a responsive nav that fits every width and supports mobile/tablet.

## What Changes

- Raise the responsive breakpoint so the inline nav links and the right-side group are shown only at `xl` (≥1280px). Below `xl` the navigation collapses into the existing left-edge slide-out drawer.
- Move the hamburger button from a `fixed top-4 left-4` element outside `<nav>` into the nav bar's left group (inline, `xl:hidden`), so it is part of the bar on tablet/mobile instead of floating over content.
- Keep the notification bell always visible in the nav bar (pull it out of the right group so it is not hidden below `xl`).
- Keep the workspace switcher inline in the bar (small footprint).
- Add close-on-navigate: tapping a link inside the drawer also closes the drawer (in addition to the existing close button and backdrop).
- Update drawer/overlay breakpoints (`sm:hidden` → `xl:hidden`).
- Make data tables horizontally scrollable on small screens. Tables currently sit in cards with `overflow-hidden` (content is clipped) or have no scroll container (content pushes the page wide). Wrap tables so they scroll within the card via `overflow-x-auto`: change the shared `<.table>` component card (`core_components.ex`) and the raw table cards from `overflow-hidden` to `overflow-x-auto`, and wrap the bare tables (team, message queue, webhooks) in a scroll container.

## Capabilities

### New Capabilities

- `responsive-tables`: data tables scroll horizontally within their card on small viewports instead of being clipped or forcing page-wide horizontal scroll.

### Modified Capabilities

- `mobile-navigation`: the drawer now activates below `xl` (1280px) instead of below `sm` (640px); the hamburger is integrated into the nav bar; the drawer closes on link tap.
- `app-navigation`: inline nav links and the right-side group now display only at/above `xl` (1280px); below that the drawer is the navigation surface.

## Impact

- Code: edits only in `lib/treby_web/components/layouts.ex` (`app/1` template) — class changes (`sm:` → `xl:`) and moving the hamburger element. No new modules and no new JS file (reuses the existing `Phoenix.LiveView.JS.toggle_class`).
- No migrations, no new dependencies, no schema changes.
- Auth/multi-tenancy: unchanged — nav items stay gated by admin role for Settings.
- Docs: navigation change, not a new feature; regenerate screenshots with `node scripts/screenshots.mjs` and keep `site/` English-only. No new `site/features/*.md` page required.
