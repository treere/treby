## ADDED Requirements

### Requirement: Tables scroll horizontally within their card
The system SHALL render data tables inside a horizontal scroll container (`overflow-x-auto`) so that on narrow viewports the table scrolls within its card rather than being clipped or pushing the page wide.

#### Scenario: Narrow viewport table scroll
- **WHEN** a user views a data table on a viewport narrower than the table's natural width
- **THEN** the table scrolls horizontally within its card
- **AND** the page itself does not gain a horizontal scrollbar from the table

#### Scenario: Wide viewport table display
- **WHEN** a user views a data table on a viewport wide enough for the table
- **THEN** the table displays at full width with no horizontal scrollbar
