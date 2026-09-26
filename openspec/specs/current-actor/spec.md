# Current Actor

## Purpose

Unify actor derivation so guards assign one `current_actor` per mount and contexts handle nil actors safely.

## Requirements

### Requirement: Guards derive actor once per mount

The system SHALL assign a single `current_actor` on every mount that passes the membership guards, derived from the already-loaded tenant and membership with no additional queries.

#### Scenario: Guarded mount exposes actor

- **WHEN** a LiveView mounts through the membership guards with a valid session and membership
- **THEN** `current_actor` is assigned and carries the same id, role, and permissions as building an actor from the assigned membership and tenant

#### Scenario: No extra query for actor derivation

- **WHEN** a guarded mount completes
- **THEN** membership resolution performs no more database reads than before this capability existed

### Requirement: Contexts keep accepting nil actor

The system SHALL keep accepting a possibly-nil actor in context functions, with id extraction yielding nil instead of raising.

#### Scenario: Nil actor through contexts

- **WHEN** a context function receives a nil actor
- **THEN** audit and foreign-key fields record nil and no error is raised

### Requirement: Nil-safe actor id extraction

The system SHALL provide a single nil-safe id extraction such that a nil actor yields nil and a present actor yields its id.

#### Scenario: Nil actor

- **WHEN** id extraction receives a nil actor
- **THEN** the result is nil and no error is raised

#### Scenario: Present actor

- **WHEN** id extraction receives an actor with an id
- **THEN** the result equals the actor id
