## MODIFIED Requirements

### Requirement: Consistent error flash pattern
All form submission error handlers SHALL use the same flash message text for consistency. Flash rendering SHALL use the design-system `Feedback.Toast` (or `CoreComponents.flash` that delegates to it) with `kind` `:info`/`:error`/`:success`/`:warning`, and no screen SHALL duplicate flash/toast markup outside the design system.

#### Scenario: All changeset failures use the same message
- **WHEN** any form submission fails with changeset validation errors across the application
- **THEN** the flash error message is "Please review the errors below" in all cases

#### Scenario: Toast styling is centralized
- **WHEN** a flash is rendered (info/error/success/warning)
- **THEN** it uses the design-system bespoke toast scale (`bg-blue-50`/`bg-emerald-50`/`bg-amber-50`/`bg-red-50` with matching dark-mode `*-950`/`border-*-800` and `rounded-xl border shadow-lg`) via `Feedback.toast` / `CoreComponents.flash`, and is reachable via the shared `flash_group` component — no daisyUI `toast`/`alert`/`alert-info`/`alert-error` classes are used

#### Scenario: No ad-hoc toast markup outside DS
- **WHEN** CI scans `lib/treby_web` for `class="alert` or `toast` outside `lib/treby_web/components/design_system/feedback.ex` and `core_components.ex` flash delegation
- **THEN** no ad-hoc duplicates are found (storybook Toast story is the reference)

#### Scenario: Toasts appear fixed at top-right
- **WHEN** a flash toast is shown
- **THEN** it appears fixed at `top-4 right-4` with `z-50`, stacked vertically with gap, above the sticky nav, in both light and dark themes
- **AND** multiple toasts stack without overlapping page content

### Requirement: Storybook documents toast/flash variants
The storybook SHALL include a `Feedback.Toast` story showing each `kind` (`info`/`success`/`warning`/`error`), with and without `title`, so error-feedback styling is previewable in isolation.

#### Scenario: Toast story covers all kinds
- **WHEN** a developer opens the Toast/Feedback story
- **THEN** controls allow switching `kind` and toggling `title`, and the preview updates for each kind in both light and dark themes
