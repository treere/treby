## ADDED Requirements

### Requirement: Color tokens defined as CSS custom properties
The system SHALL define color tokens as CSS custom properties on `:root` and `[data-theme="dark"]` in `app.css`, covering primary, secondary, accent, neutral, success, warning, error, and info.

#### Scenario: Light mode colors
- **WHEN** the page has no `data-theme` attribute or `data-theme="light"`
- **THEN** the color custom properties resolve to the light theme values

#### Scenario: Dark mode colors
- **WHEN** the page has `data-theme="dark"`
- **THEN** the color custom properties resolve to the dark theme values

### Requirement: Spacing scale defined
The system SHALL define a consistent spacing scale (xs, sm, md, lg, xl, 2xl, 3xl) as CSS custom properties mapped to Tailwind's spacing convention.

#### Scenario: Spacing tokens available in components
- **WHEN** a component references a spacing token
- **THEN** the value matches the predefined scale

### Requirement: Typography scale defined
The system SHALL define type scale tokens for headings (h1-h6) and body text as CSS custom properties, covering font size, line height, and font weight.

#### Scenario: Heading tokens
- **WHEN** a heading component renders with a specific level
- **THEN** it uses the correct font size, weight, and line height from tokens

### Requirement: Elixir token module
The system SHALL provide a `TrebyWeb.DesignSystem` module with functions returning Tailwind class tuples for variant/color/style combinations used by components.

#### Scenario: Variant class resolution
- **WHEN** a component calls `variant_classes(:primary)`
- **THEN** it returns the correct Tailwind class list for the primary variant
