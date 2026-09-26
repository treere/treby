## ADDED Requirements

### Requirement: Single policy check
The system SHALL expose one policy check `Policy.can?(actor_or_effective, action)` that returns true only when the action key is known and present in the effective permission set. It SHALL never raise and SHALL deny on nil actor, nil permissions, unknown role, or unknown action.

#### Scenario: Allowed action passes
- **WHEN** an actor carries an effective set containing the action
- **THEN** `Policy.can?` returns true

#### Scenario: Fail-closed on nil and unknown
- **WHEN** the actor is nil, permissions are nil, or the action key is unknown
- **THEN** `Policy.can?` returns false

#### Scenario: MapSet path matches actor path
- **WHEN** the same effective set is checked directly and via an actor map
- **THEN** both return the same result

### Requirement: Single actor builder
The system SHALL expose one actor builder normalizing LiveView sockets, assigns maps, agent ctx maps, and membership+tenant pairs into `%{id, role, permissions}`. Missing role SHALL yield an empty permission set. A membership path without resolvable tenant SHALL omit permissions so checks deny. A ctx role without tenant SHALL fall back to preset defaults (no overrides) to preserve role-only filtering. String and atom roles SHALL resolve identically.

#### Scenario: Socket and assigns agree
- **WHEN** the same session is built from a socket and from its assigns map
- **THEN** both actors carry the same id, role, and permissions

#### Scenario: Missing tenant denies
- **WHEN** no tenant can be resolved on the membership path
- **THEN** the actor carries no usable set and every policy check denies

#### Scenario: Role format independent
- **WHEN** role is given as string or atom
- **THEN** the effective set is identical
