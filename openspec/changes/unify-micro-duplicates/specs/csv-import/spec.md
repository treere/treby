## ADDED Requirements

### Requirement: Single CSV split entry point
The system SHALL split CSV text through the single central `parse_lines` path (NimbleCSV, shared with preview's `parse_csv`), with `ImportCsv.run/2` reusing it instead of private `String.split`. The positional row mapper stays (import semantics are positional, preview's are header-mapped — unifying them would change behavior). Malformed input reports preview-shaped errors without fail-open.

#### Scenario: Import uses central split path
- **WHEN** a CSV import runs
- **THEN** lines come from the central split entry shared with preview, no private `String.split` remains on the import path, and the positional mapper is preserved

#### Scenario: Row errors match preview shape
- **WHEN** a CSV contains malformed rows
- **THEN** import reports them with the same error shape preview reports and still rejects bad rows without fail-open
