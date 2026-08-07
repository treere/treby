## Context

Current state:

- `assets/css/app.css` already ships daisyUI `light` and `dark` themes (`@plugin "../vendor/daisyui-theme"`, two blocks), plus `@custom-variant dark (&:where([data-theme=dark], [data-theme=dark] *))` and a `[data-theme="dark"]` token override for shadows.
- `lib/treby_web/components/layouts/root.html.heex` has a no-flash bootstrap `<script>` that reads `localStorage["phx:theme"]` ("system" | "light" | "dark"), sets/removes the `data-theme` attribute on `<html>`, reacts to `phx:set-theme` events, and syncs across tabs via the `storage` event. It runs before the stylesheet applies, avoiding a flash.
- `lib/treby_web/components/layouts.ex` already defines a `theme_toggle/1` component (system/light/dark segmented control dispatching `phx:set-theme`), but it is **never rendered** anywhere.
- The actual UI is ~100% hardcoded light colors: ~970 tokens like `bg-white`, `bg-gray-50`, `text-gray-900`, `border-gray-200` across ~45 files (all LiveViews, auth/static controllers, `core_components.ex`, `layouts.ex`). These ignore `data-theme` entirely.

So the change is not "build dark mode from scratch" but "surface the existing mechanism and make the UI actually honor it."

## Goals / Non-Goals

**Goals:**

- Expose a theme toggle in the nav, adjacent to the locale switcher, on desktop and in the mobile drawer.
- Default to the OS preference when the user hasn't chosen; persist explicit light/dark choices in `localStorage`.
- Make every app page render correctly in both themes with no white-on-white / dark-on-dark regressions.
- Apply the theme before first paint (no flash) and react to OS theme changes while in "system" mode.
- Accessible control with proper labels and contrast in both themes.
- Regenerate the docs site screenshots and update the feature docs.

**Non-Goals:**

- Per-user server-side theme persistence (the requirement is explicitly client-side `localStorage`).
- Theming the docs site (`site/`) itself — only its screenshots/docs content changes.
- Changing the existing daisyUI palette values; we reuse the shipped light/dark themes.
- Theme settings page — the toggle lives in the nav, not in Settings.

## Decisions

**1. Reuse the existing `data-theme` + `localStorage["phx:theme"]` mechanism; don't introduce a LiveView-driven theme.**
The bootstrap script and `theme_toggle` component already implement the requested behavior (system default + localStorage persistence). Themes are a per-browser visual concern; pushing them through LiveView/session would add server round-trips and a reflow after mount. The existing event-driven approach is instant and offline-friendly. Only additions: handle OS-level theme changes while in "system" mode and (optionally) guard the storage/set-theme listeners with try/catch when storage is unavailable.

**2. Toggle placement: render `<.theme_toggle />` immediately before `<.locale_switcher />` in both the desktop nav and the mobile drawer.**
Matches the user's request ("affianco al selettore della lingua"). Both switchers are small icon controls; `theme_toggle` uses daisyUI `base-*` tokens so it already adapts to the active theme. No layout math changes needed.

**3. Convert hardcoded color tokens to semantic tokens, preferring daisyUI `base-*`/`base-content`; use `dark:` variants only where a deliberately different dark treatment is needed.**
- Backgrounds: `bg-white` → `bg-base-100`, `bg-gray-50` (page/app chrome) → `bg-base-200`, cards/hover `bg-gray-100` → `bg-base-200`/`bg-base-300`.
- Text: `text-gray-900` → `text-base-content`, `text-gray-700`/`600` → `text-base-content/80` or `/70`, `text-gray-500`/`400` → `text-base-content/50` or `/40`.
- Borders: `border-gray-200`/`300` → `border-base-300`.
- Accents (blue) already read acceptably on the dark theme; keep them as-is unless a `dark:` variant is clearly better.
- The existing `design_system/` components (dropdown, modal, feedback, pattern, card) already use `base-*` tokens and require no changes.
Rationale: daisyUI tokens automatically invert per theme (single source of truth), avoid doubling every class with `dark:`, and match the pattern the `design_system/` components already follow. `dark:` stays reserved for edge cases (e.g. shadow-heavy or overlay elements).

**4. Establish a small token map as the single reference for the conversion.**
Rather than ad-hoc edits, define a mapping table (used in tasks.md) and apply it uniformly so reviewers can audit that no `bg-white`/`text-gray-*`/`border-gray-*` remains.

**5. Docs site: regenerate screenshots with `node scripts/screenshots.mjs` and add a dark mode feature page/update.**
Per AGENTS.md, after changing a feature, screenshots must be regenerated and the relevant `site/features/` page updated.

## Risks / Trade-offs

- **Flash of wrong theme** → already mitigated by the inline pre-paint script; keep it before the stylesheet `<link>` and ensure it also handles `prefers-color-scheme` changes via `matchMedia` listener while in system mode.
- **Stale/private localStorage** → guard `localStorage` access in a try/catch; the script already no-ops gracefully if the attribute is present.
- **Conversion regressions** (contrast, invisible elements, over-scoped `base-200` backgrounds) → mechanical swap is reviewed page-by-page in a browser; `mix precommit` runs tests; screenshots captured in both themes.
- **`theme_toggle` uses daisyUI classes (`card`, `border-1`) that may not be compiled** → confirm all used classes are present in the compiled CSS after the swap; adjust classes to Tailwind-compatible ones if any are dropped.
- **Large diff** (~45 files) → change is mechanical and testable; tasks split by area (layouts/core, auth/static, per-LiveView groups) so it can be verified incrementally.

## Migration Plan

1. Wire toggle into nav + mobile drawer (small, immediately testable).
2. Convert tokens group by group (layouts & core → auth/static → feature LiveViews), verifying each in both themes.
3. Regenerate screenshots and update docs.
4. Run `mix precommit`, fix any issues.
No database or external-system migration; rollback is a revert of the CSS/template changes.

## Open Questions

- None blocking. Minor: whether to convert blue accents to theme tokens too (default: keep as-is).
