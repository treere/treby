## Why

The app currently has theme infrastructure (daisyUI light/dark themes, a `data-theme` attribute, a localStorage-backed script, and an unused `theme_toggle` component) but it is not surfaced to users: every screen is locked to hardcoded light-mode colors (`bg-white`, `bg-gray-50`, `text-gray-900`, etc.), so there is no working dark mode. Users need a visible, accessible way to switch themes, and the whole UI must actually adapt.

## What Changes

- Wire the existing `<.theme_toggle />` component into the app nav, directly next to the locale switcher (desktop and mobile drawer), so users can pick **system / light / dark**.
- Default theme follows the OS preference (`prefers-color-scheme`) when the user hasn't chosen explicitly.
- Persist an explicit user choice (light or dark) in `localStorage` under the existing `phx:theme` key; "system" clears the stored preference.
- Convert the ~970 hardcoded light-mode color tokens across the app (LiveViews, auth/static controllers, `core_components.ex`, `layouts.ex`) to theme-aware tokens (daisyUI `base-*`/`base-content` or `dark:` variants) so every page renders correctly in dark mode.
- Apply theme before first paint to avoid a flash of the wrong theme (already partially handled in `root.html.heex`; extend it to also react to OS theme changes while in "system" mode).
- Ensure accessibility: the toggle buttons have descriptive `aria-label`s and sufficient contrast in both themes.
- Update the docs site: regenerate screenshots and document the dark mode feature on the relevant `site/features/` page.

## Capabilities

### New Capabilities
- `dark-mode`: Switching the app theme between system, light, and dark; persisting the user preference; and rendering all app pages in dark mode.

### Modified Capabilities
- `app-navigation`: the nav (desktop + mobile) now includes a theme toggle next to the language selector.
- `mobile-navigation`: the mobile drawer now includes the theme toggle alongside the locale switcher.

## Impact

- `lib/treby_web/components/layouts.ex` — render `<.theme_toggle />` in the nav; the `theme_toggle` component already exists.
- `lib/treby_web/components/layouts/root.html.heex` — theme bootstrap script (no-flash, system-mode live updates).
- `lib/treby_web/components/core_components.ex` and every LiveView/controller template that hardcodes light colors — swap to theme-aware tokens (large but mechanical).
- `assets/css/app.css` — daisyUI light/dark themes and `@custom-variant dark` already present; may add semantic token helpers.
- `site/` — screenshots and feature docs.
- No new dependencies; no DB/API changes. `mix precommit` must pass.
