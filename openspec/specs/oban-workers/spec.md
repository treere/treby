# Oban Workers

## Purpose

Provide a single shared base for background workers covering argument access with string/atom key fallback and shared backoff computation over per-worker delay tables.

## Requirements

### Requirement: Single shared worker arg fallback and backoff
The system SHALL provide one shared worker base exposing `arg/2` string/atom fallback and a shared `backoff/1` over per-worker tables (values legitimately differ per worker), and the four workers (data privacy export, data privacy erasure, webhook delivery, scheduled-message send) SHALL use it with byte-identical backoff values and unchanged retry behavior.

#### Scenario: Arg fallback covers both key types
- **WHEN** a worker receives args with either string or atom keys
- **THEN** `arg/2` resolves the same value as the pre-refactor `args["id"] || args[:id]` pattern

#### Scenario: Backoff values unchanged
- **WHEN** any of the four workers computes backoff for a given attempt
- **THEN** the returned delay equals the pre-refactor per-worker value for that attempt and retry/fail-closed behavior is unchanged
