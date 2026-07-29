## ADDED Requirements

### Requirement: Component documentation
The system SHALL document all design system components with `@moduledoc` and `@doc` annotations, including usage examples and attribute descriptions.

#### Scenario: Documentation renders
- **WHEN** a developer runs `mix docs`
- **THEN** all design system components appear in the generated documentation with examples

### Requirement: CoreComponents delegation
The system SHALL refactor `TrebyWeb.CoreComponents` to delegate to design system components where implementations overlap, with deprecation notices on old functions.

#### Scenario: Button delegation
- **WHEN** a template calls `CoreComponents.button/1`
- **THEN** it delegates to the design system's Button component

### Requirement: Incremental migration
The system SHALL allow templates to adopt design system components one at a time without breaking existing functionality.

#### Scenario: Mixed usage
- **WHEN** some templates use new components and others use old ones
- **THEN** both render correctly in the same page
