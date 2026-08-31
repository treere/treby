# Storybook Preview

## Purpose

Provide an isolated, dev-only component catalog powered by `phoenix_storybook` that showcases every design-system component with variants, controls, and theming, making the system discoverable and reviewable without affecting production.

## Requirements

### Requirement: Storybook is available in development only
The system SHALL integrate `phoenix_storybook` (https://github.com/phenixdigital/phoenix_storybook) and expose it only when `Mix.env() == :dev` (or an explicit `:enable_storybook` config), with the dependency restricted to `only: :dev` so it is not compiled or routed in `prod`/`test` releases.

#### Scenario: Storybook reachable in dev
- **WHEN** the app runs with `MIX_ENV=dev` and a developer navigates to `/dev/storybook`
- **THEN** the storybook UI loads and lists component entries

#### Scenario: Storybook not reachable in prod
- **WHEN** the app runs with `MIX_ENV=prod` (or `mix release`)
- **THEN** `/dev/storybook` and `/storybook` return 404 and `phoenix_storybook` is not compiled into the release

#### Scenario: Storybook not reachable in test
- **WHEN** `MIX_ENV=test` and the test suite runs
- **THEN** the storybook route is not mounted and no test depends on it

### Requirement: Storybook shows every design-system component
The storybook SHALL define a story for each design-system component — `Button`, `Badge`, `Card`, `Modal`, `Dropdown`, `Tabs`, `Avatar`, `Feedback` (`Spinner`/`Skeleton`/`Toast`), and `Pattern` (`ConfirmDialog`, `PageHeader`, `EmptyState`, `FilterBar`, `FormSection`, `LoadingOverlay`) — with controls for variants, sizes, and boolean props, and with usage notes.

#### Scenario: Button story covers variants and states
- **WHEN** a developer opens the Button story
- **THEN** controls allow switching `variant` (`primary`/`secondary`/`danger`/`ghost`/`outline`), `size` (`sm`/`md`/`lg`), `loading`, `disabled`, and the preview updates live

#### Scenario: All components have stories
- **WHEN** the storybook index is viewed
- **THEN** entries exist for Badge, Card, Modal, Dropdown, Tabs, Avatar, Spinner, Skeleton, Toast, ConfirmDialog, PageHeader, EmptyState, FilterBar, FormSection, and LoadingOverlay

### Requirement: Storybook reuses app styling and theming
The storybook SHALL render components with the app's `assets/css/app.css` (Tailwind v4 + daisyUI theme vars + `--ds-*` tokens) and respect `data-theme` (light/dark/system), so previews match production rendering.

#### Scenario: Dark mode preview
- **WHEN** the storybook theme is switched to dark (or `data-theme="dark"`)
- **THEN** component previews use dark token values (e.g., dark shadows, `base-100` dark)

### Requirement: Storybook configuration and routing
The system SHALL provide `lib/treby_web/storybook.ex` (implementing `PhoenixStorybook.Storybook` with `content_path: "storybook"`) and `storybook/**/*.story.exs` entries, and mount the router via `import PhoenixStorybook.Router` + `live_storybook("/dev/storybook", ...)` guarded by `if Application.compile_env(:treby, :dev_routes)` in `lib/treby_web/router.ex`.

#### Scenario: Router guard is present
- **WHEN** `lib/treby_web/router.ex` is inspected
- **THEN** the storybook scope is wrapped in a dev-only guard (`dev_routes`) and uses `live_storybook("/dev/storybook", ...)`

#### Scenario: Build passes in all envs
- **WHEN** `mix compile` runs in `dev`, `test`, and `prod`
- **THEN** compilation succeeds in each env

### Requirement: Storybook is documented and discoverable
The repository SHALL document the storybook dev URL (e.g., `http://localhost:4000/dev/storybook`) in `README.md` and note that it is dev-only.

#### Scenario: Developer finds storybook quickly
- **WHEN** a new developer reads `README.md`
- **THEN** they find the storybook URL (`/dev/storybook`), the `MIX_ENV=dev` requirement, and that it is not available in prod
