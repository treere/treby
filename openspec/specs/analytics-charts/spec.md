# Analytics Charts

## Purpose

Provide server-side SVG charting for analytics pages using Contex, with responsive theming and stable empty-state placeholders.

## Requirements

### Requirement: Server-side SVG charting with Contex
The system SHALL render analytics charts as server-side SVG via Contex 0.5.0 without any npm or LiveView JS hook dependencies.

#### Scenario: Contex dependency present
- **WHEN** the application is built
- **THEN** `{:contex, "~> 0.5.0"}` is in `mix.exs` and `mix.lock` and `Contex.Plot.to_svg/1` is available

#### Scenario: Charts helper module
- **WHEN** analytics LiveViews need to render a chart
- **THEN** they delegate to `TrebyWeb.Charts` which builds `Contex.Dataset` and `Contex.Plot` and returns safe SVG via `Plot.to_svg/1`

#### Scenario: Themed styling
- **WHEN** a chart is rendered in light or dark theme
- **THEN** Contex SVG classes (`.exc-tick`, `.exc-grid`, `.exc-domain`, `.exc-legend`) are styled via `assets/css/app.css` overrides using design-system tokens (`zinc` palette, `orange-600`) and respect `data-theme=dark`

#### Scenario: Responsive wrapper
- **WHEN** a chart is displayed at viewport widths 375px, 768px, and 1280px
- **THEN** the SVG scales to the card width (`width: 100%; height: auto` via wrapper) without horizontal overflow

### Requirement: Empty state occupies space
The system SHALL keep chart cards at a stable height and show a centered placeholder when there is no data, instead of collapsing the card.

#### Scenario: Empty card keeps height
- **WHEN** a chart has no data (e.g., all daily counts are `0` or source breakdown is empty)
- **THEN** the card remains at least `min-h-[320px]` (`flex flex-col` with `flex-1` chart area) and shows a centered dashed placeholder with icon, title, and descriptive text

#### Scenario: Empty placeholder content
- **WHEN** the placeholder is shown
- **THEN** it displays an icon (`hero-chart-bar`), a title (e.g., "No views in this period" or "No source data yet"), and a short explanation (e.g., sharing the public link to start tracking), not an empty chart or zero-height element

#### Scenario: Non-empty renders chart
- **WHEN** data has at least one non-zero value
- **THEN** the chart SVG is rendered in the same card area with the same outer dimensions as the empty placeholder would occupy
