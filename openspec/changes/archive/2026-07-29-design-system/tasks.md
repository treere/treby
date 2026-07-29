## 1. Foundation

- [x] 1.1 Create `lib/treby_web/components/design_system/` directory structure
- [x] 1.2 Add design token CSS custom properties to `app.css` for color, spacing, typography, and shadow scales (in both `:root` and `[data-theme="dark"]`)
- [x] 1.3 Create `TrebyWeb.DesignSystem` module with class helpers (`primary_classes/0`, `variant_classes/1`, etc.)
- [x] 1.4 Wire up imports in `treby_web.ex` `html_helpers` block so all design system components are available in templates

## 2. Core Components

- [x] 2.1 Implement `<.Button>` component with all variants (primary, secondary, outline, ghost, danger), sizes (sm, md, lg), icon slot, loading state, disabled state, and link mode (navigate/patch/href)
- [x] 2.2 Implement `<.Badge>` component with variants (default, success, warning, danger, info) and optional dot indicator
- [x] 2.3 Implement `<.Card>` component with header, body, footer slots and variants (default, bordered, elevated, flat)
- [x] 2.4 Implement `<.Modal>` component with open/close state, title/body/footer slots, backdrop dismiss, and Escape key support
- [x] 2.5 Implement `<.Dropdown>` component with trigger slot, menu items, dividers, and disabled items
- [x] 2.6 Implement `<.Tabs>` component with controlled and uncontrolled modes
- [x] 2.7 Implement `<.Spinner>` and `<.Skeleton>` components for loading states
- [x] 2.8 Implement `<.Avatar>` component with image and initials fallback

## 3. Pattern Components

- [x] 3.1 Implement `<.ConfirmDialog>` pattern wrapping Modal with confirm/cancel buttons and configurable callback event
- [x] 3.2 Implement `<.PageHeader>` with breadcrumbs, title, subtitle, and actions slot
- [x] 3.3 Implement `<.EmptyState>` with icon, title, description, and action slot
- [x] 3.4 Implement `<.FilterBar>` with configurable fields, apply/reset, and change callback
- [x] 3.5 Implement `<.FormSection>` with title, description, and error summary
- [x] 3.6 Implement `<.LoadingOverlay>` for async operations

## 4. CoreComponents Refactor & Adoption

- [x] 4.1 Refactor `CoreComponents.button/1` to delegate to `DesignSystem.Button`
- [x] 4.2 Refactor `CoreComponents.confirm_modal/1` to delegate to `DesignSystem.Pattern`
- [x] 4.3 Add deprecation `@doc` notices to refactored `CoreComponents` functions
- [x] 4.4 Add `@moduledoc` and `@doc` with usage examples to all design system components

## 5. Tests

- [x] 5.1 Write tests for Buttons (all variants, sizes, disabled, loading, link mode)
- [x] 5.2 Write tests for Badge, Card, Modal, Dropdown, Tabs, Spinner, Avatar
- [x] 5.3 Write tests for ConfirmDialog, EmptyState, PageHeader, FilterBar, FormSection, LoadingOverlay
- [x] 5.4 Verify `mix test` passes and `mix format` is clean
