## Why

Treby has a design system (`TrebyWeb.DesignSystem.*`, `assets/css/app.css` tokens, `CoreComponents`) but usage is inconsistent: many LiveViews bypass it with hardcoded Tailwind classes (`bg-blue-600`, `bg-gray-500`), raw `<span>` badges, and deprecated wrappers (`<.confirm_modal>` / `<.empty_state>` in `CoreComponents`). Components like `Tabs`, `Dropdown`, `Card`, `Avatar`, `Spinner`/`Skeleton`, `FilterBar`, `FormSection` are defined but almost unused. This creates visual drift (different button radii/shadows, mixed `gray-50` vs `base-100` theming), duplicated CSS, and no single source of truth. Adding an isolated preview via `phoenix_storybook` (dev-only) makes the system discoverable, reviewable, and enforces future usage.

## What Changes

- Audit and normalize the design system: consolidate tokens in `assets/css/app.css`, keep the Tailwind v4 import syntax (`@import "tailwindcss" source(none); @source ...`), update `TrebyWeb.DesignSystem` components where gaps exist (missing variants, a11y, dark-mode, loading/disabled states), and deprecate/remove ad-hoc styles.
- Migrate all app UI to the design system: replace hardcoded `bg-blue-600`/`bg-gray-500` button markup, raw badge spans, and custom headers/tables in `lib/treby_web/live/**/*`, `lib/treby_web/controllers/**/*`, and `lib/treby_web/components/layouts.ex` with `<.button>`, `<.badge>`, `<.card>`, `<.page_header>`, `<.confirm_dialog>`, `<.empty_state>`, `<.filter_bar>`, etc. Remove `CoreComponents` delegation shims once migrated.
- Integrate `phoenix_storybook` (https://github.com/phenixdigital/phoenix_storybook) as dev-only tooling: add `{:phoenix_storybook, "~> 0.9", only: :dev}` dependency, create `lib/treby_web/storybook.ex` and `storybook/**/*.story.exs` for every design-system component, mount the storybook router only when `Mix.env() == :dev` (or config flag), and ensure it is excluded from `prod` releases and CI builds.
- Add guardrails: lint/CI check (e.g. `mix precommit` or Credo custom check / `grep` guard) to prevent re-introducing hardcoded button/badge classes outside the design system.

## Capabilities

### New Capabilities
- `design-system`: consolidated token/component library (Button, Badge, Card, Modal, Dropdown, Tabs, Avatar, Feedback/Spinner/Skeleton/Toast, Pattern/PageHeader/EmptyState/FilterBar/FormSection/LoadingOverlay) with variants, sizes, a11y, and theme support; migration of all existing UI to it.
- `storybook-preview`: isolated component catalog powered by `phoenix_storybook`, dev-only, showing each design-system component with variants/controls and usage docs.

### Modified Capabilities
- `dark-mode`: tighten requirement so every component/token has explicit light/dark values (no hardcoded `gray-900` outside tokens).
- `error-feedback`: align flash/toast rendering with design-system `Feedback.Toast` (remove duplicated flash markup).
- `delete-confirmations`: require `Pattern.ConfirmDialog` (via `DesignSystem.Modal`) instead of legacy `CoreComponents.confirm_modal`.

## Impact

- Dependencies: add `phoenix_storybook ~> 0.9` (`only: :dev`), no runtime impact in `prod`.
- Code: `lib/treby_web/components/design_system/*`, `lib/treby_web/components/design_system.ex`, `lib/treby_web/components/core_components.ex` (shims), `lib/treby_web/components/layouts.ex`, `assets/css/app.css`, `lib/treby_web/router.ex` (dev-only scope), `lib/treby_web/storybook.ex` + `storybook/` stories, ~30 LiveViews/templates under `lib/treby_web/live` and `lib/treby_web/controllers`.
- Migrations: none (no DB changes).
- Build/deploy: storybook excluded from `Dockerfile` prod stage and `mix release`; `mix precommit` extended with design-system guard.
- Docs: `site/` unchanged (user manual excludes implementation detail per `AGENTS.md`); internal `README.md` notes storybook dev URL.
