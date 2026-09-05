## MODIFIED Requirements

### Requirement: Landing page content
The system SHALL display a public landing page at the root URL (`/`) in the Modern SaaS Minimal language: page `bg-zinc-50` (light) / `bg-zinc-900` (dark), hero with `text-zinc-900` headline, muted `text-zinc-500` subcopy, primary CTA `bg-zinc-900 text-white hover:bg-zinc-800` (or `bg-orange-600` for brand emphasis) with `rounded-lg shadow-sm`, feature cards as `bg-white rounded-xl border border-zinc-200 shadow-sm`.

#### Scenario: Page loads successfully
- **WHEN** a visitor navigates to `/`
- **THEN** the landing page renders with the product name "Treby" in `text-zinc-900`, a muted tagline, and a primary CTA with `rounded-lg shadow-sm` in the SaaS minimal style

#### Scenario: Responsive design
- **WHEN** a visitor views the landing page on mobile (viewport < 640px)
- **THEN** the layout adapts to a single-column format with SaaS minimal card stacking and all content remains readable

### Requirement: Feature showcase
The system SHALL display key product features on the landing page as SaaS minimal cards (`bg-white rounded-xl border border-zinc-200 shadow-sm p-6` with `text-zinc-900` title and `text-zinc-500` description).

#### Scenario: Feature cards
- **WHEN** a visitor scrolls down the landing page
- **THEN** at least 3 feature cards are visible each with `bg-white rounded-xl border border-zinc-200 shadow-sm`
- **AND** each card has a `text-zinc-900` title and `text-zinc-500` brief description covering job management, candidate tracking, and interview scheduling
