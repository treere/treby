## Why

The app currently uses ad-hoc Tailwind/daisyUI classes scattered across templates and `core_components.ex`. There's no consistent design language — button variants, spacing, typography, and component patterns are applied inconsistently. As the app grows, this makes UI maintenance harder and slows development of new features. A design system will provide a single source of truth for UI components, ensuring visual consistency and faster iteration.

## What Changes

- Introduce a `TrebyWeb.DesignSystem` module with branded, reusable function components (buttons, cards, badges, modals, dropdowns, etc.)
- Add higher-level "pattern" components for frequently used UI patterns (confirmation dialogs, empty states, loading skeletons, page headers with breadcrumbs, filter bars)
- Define design tokens (colors, spacing, typography, shadows) aligned with the existing custom daisyUI themes (light/dark)
- Refactor `core_components.ex` to delegate to design system components where applicable — consolidating overlapping implementations
- Document component usage for developers
- Update existing templates gradually to use new components (non-breaking, incremental adoption)

## Capabilities

### New Capabilities
- `design-system-foundation`: Design tokens, CSS custom properties, typography scale, spacing scale, and theme-aware utility classes
- `design-system-components`: Basic UI components (Button, Card, Badge, Modal, Dropdown, Tabs, Spinner/Skeleton, Toast/Notification, Pagination, Avatar)
- `design-system-patterns`: Higher-level composite components (ConfirmDialog, EmptyState, PageHeader, FilterBar, DataTable with sorting, FormSection, LoadingOverlay)
- `design-system-adoption`: Documentation, migration guide, and codemod/refactor of existing templates to use the new system

### Modified Capabilities
<!-- No existing specs are modified — this is a pure addition -->

## Impact

- `lib/treby_web/components/`: New `design_system/` directory with organized component files
- `lib/treby_web/components/core_components.ex`: Refactored to delegate to design system
- `assets/css/app.css`: May gain additional CSS custom properties or component-specific styles
- No new JS dependencies; uses existing Tailwind v4 + daisyUI setup
- All existing templates continue working — migration is opt-in per template
