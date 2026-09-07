## ADDED Requirements

### Requirement: Pagination component covers list navigation use cases
The design system SHALL provide a `Pagination` component with page numbers (windowed with first/last), Prev/Next buttons with disabled states, a "Showing X–Y of Z" result count, `id="pagination"`, keyboard/ARIA support (`aria-label`, `aria-current`), and full dark-mode styling with the `orange-600` active-page CTA token. It SHALL hide itself when there is a single page of results.

#### Scenario: Pager renders on multi-page lists
- **WHEN** a developer renders `<.pagination page={2} total_pages={10} total_count={243} />`
- **THEN** Prev/Next buttons, windowed page numbers around 2, and the result count are shown with `id="pagination"`

#### Scenario: Single page hides pager
- **WHEN** `total_pages` is 1
- **THEN** the component renders nothing
