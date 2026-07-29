## Context

The app uses Tailwind CSS v4 with custom daisyUI themes (light/dark) and has a `TrebyWeb.CoreComponents` module (755 lines) that grew organically from Phoenix scaffolding plus app-specific components. Components use daisyUI class names (`btn`, `btn-primary`, `card`, `table`, `modal`) and raw Tailwind utilities interchangeably — no consistent component API, no design tokens beyond daisyUI's built-in variables, and no documentation for developers building new UI.

## Goals / Non-Goals

**Goals:**
- Define design tokens (colors, spacing, typography, shadows, border radius) as CSS custom properties and Elixir module constants
- Build a set of generic, reusable components with consistent API patterns (attribute-based, slot-based where appropriate)
- Build higher-level pattern components for frequently used composite UIs (confirm dialogs, empty states, loading, page headers)
- Make all components theme-aware (light/dark) by using CSS custom properties rather than hardcoded Tailwind colors
- Provide usage documentation via `@moduledoc` and `@doc` tags that Phoenix generates docs from

**Non-Goals:**
- No new npm/JS dependencies
- No breaking changes to existing templates (migration is incremental and opt-in)
- No redesign of the existing layout or navigation structure
- No DaisyUI removal — components may use daisyUI classes internally where appropriate, but the public API is decoupled

## Decisions

### 1. Module structure: multiple files, one per component group

**Decision**: Create a `lib/treby_web/components/design_system/` directory with one file per logical group:

```
design_system/
├──.ex  (module constant helpers for tokens)
├──button.ex
├──card.ex
├──modal.ex
├──form.ex          (inputs, selects, textareas — higher-level than core <  .input >)
├──badge.ex
├──layout.ex        (page header, section, divider, container)
├──feedback.ex      (toast, alert, inline error, loading spinner/skeleton)
├──data.ex          (table, pagination, empty state)
└──pattern.ex       (confirm dialog, filter bar, form section, loading overlay)
```

All modules use `use Phoenix.Component` and follow Phoenix's function component conventions. They are imported in `html_helpers` block of `treby_web.ex` so they're available in all templates automatically.

### 2. Design tokens: CSS custom properties + Elixir module

**Decision**: Define tokens in two places:
- **CSS custom properties** in `app.css` under `:root` and `[data-theme="dark"]`, covering color palette, border radius, font families, and shadow scales
- **Elixir module** (`TrebyWeb.DesignSystem.Token` or similar) for token constants used in component logic (e.g., mapping variant names to Tailwind class tuples)

**Rationale**: CSS custom properties are needed for theme switching at runtime. An Elixir module avoids string duplication when components need to build dynamic class lists based on variant/color props.

### 3. Component API convention

**Decision**: Follow the Phoenix Component convention strictly:
- `attr` declarations for all assigns
- `slot` for inner_block and named slots
- `:rest` global attributes for HTML pass-through on wrapper elements
- Components accept `class` for additional Tailwind classes
- No surprises — each component's assigned attributes mirror the HTML element it produces

**Rationale**: Consistency with Phoenix's built-in components (`.link`, `.form`) and with the existing `core_components.ex` style. This makes the API predictable for developers.

### 4. Theming approach

**Decision**: Use the existing `data-theme` attribute mechanism. Components reference CSS custom properties (e.g., `var(--color-primary)`) or Tailwind's `var()`-based classes for dynamic theming. The daisyUI plugin and the existing custom themes in `app.css` remain the source of truth for color tokens. New component-specific tokens are added to the existing `:root` / `[data-theme="dark"]` blocks.

### 5. Migration strategy

**Decision**: No codemod. Developers adopt new components on a per-template basis. The `core_components.ex` module stays in place and is gradually refactored to delegate to design system components. Old components are deprecated with `@doc` annotations but not removed until all callers are migrated.

### 6. Testing strategy

**Decision**: Each component gets a dedicated test file in `test/treby_web/components/design_system/` using `Phoenix.LiveViewTest`. Tests verify:
- Component renders with default attrs
- Variant/color prop produces correct CSS classes
- Slots render when provided
- Global `:rest` attrs are passed through
- Theme class is applied correctly

## Risks / Trade-offs

- [Proliferation risk] Multiple small component files vs one large module → Trade-off for better discoverability and CI cache. Mitigated by importing all in `html_helpers`.
- [Duplication risk] DaisyUI classes and new design system classes may overlap → Mitigated by making new components wrap daisyUI classes under the hood or replace them entirely.
- [Scope creep] Building too many components at once → Mitigated by the task plan that prioritizes the most-used components first.
- [Migration friction] Developers may keep using old patterns → Mitigated by clear deprecation docs and making new components visibly better (props API, accessibility, dark mode support).
