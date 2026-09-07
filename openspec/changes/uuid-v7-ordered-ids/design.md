## Context

Treby uses `@primary_key {:id, :binary_id, autogenerate: true}` in 35 schemas — random UUIDv4 ids with second-precision `inserted_at` timestamps. Equal-timestamp rows have no stable order, which the pagination change (`perf-pagination-trgm`) worked around with an explicit `id` tiebreak in `Queries.paginate/3` and staggered test timestamps. Ecto 3.14 (`Ecto.UUID`, verified in `deps/ecto/lib/ecto/uuid.ex`) supports natively generating UUIDv7 (unix_ms + monotonic random bits) via `autogenerate: [version: 7, precision: ...]`. The column type stays `uuid`, so the switch is declaration-only with no migration.

## Goals / Non-Goals

**Goals:**
- New rows get time-ordered ids so `ORDER BY id` approximates insertion order (tiebreak becomes a real guarantee).
- Zero migration, zero API/URL/UI changes, zero new dependencies.

**Non-Goals:**
- No backfill of existing v4 ids (PKs are FK-referenced everywhere; product is pre-launch).
- No microsecond timestamps or cursor pagination (deferred; v7 solves the observed problem).

## Decisions

1. **Declaration: `@primary_key {:id, Ecto.UUID, autogenerate: [version: 7, precision: :monotonic]}`** in all 35 schemas. Rationale: `Ecto.UUID` is a drop-in for `:binary_id` (same cast/dump/load), and `precision: :monotonic` guarantees strictly increasing ids per BEAM node even within the same millisecond — the strongest ordering available. Alternative (`precision: :millisecond`, OS clock): same-ms bursts can tie; rejected.
2. **`@foreign_key_type :binary_id` unchanged.** FKs only cast/dump; generation options apply to FK columns too in theory, but no code inserts via `put_assoc`-style id generation on FKs — leaving them untouched minimizes diff. Verified: no schema sets `autogenerate` on non-PK fields.
3. **Keep staggered test timestamps.** They remain valid deterministic fixtures; no test edits required. Add one new assertion per paginated resource that same-`inserted_at` rows order by descending id (now meaningful).
4. **Timestamp leakage accepted (documented).** v7 embeds unix_ms; job ids appear in public career URLs. Rejected alternative (opaque public slugs): out of scope, posting dates are public anyway.
5. **No changes to `Queries.paginate/3` ordering clauses.** `desc: :inserted_at, desc: :id` already exists; v7 gives the tiebreak teeth.

## Risks / Trade-offs

- [Risk] Old v4 rows interleave arbitrarily with new v7 rows under `ORDER BY id` → Mitigation: documented in `IMPROVEMENTS.md` follow-up; acceptable pre-launch (seeds/dev data).
- [Risk] Multi-node deployments: per-node monotonic counters share only the ms timestamp, so cross-node same-ms order is approximate → Mitigation: self-hosted single-node is the default; still strictly better than v4 random.
- [Risk] 35-file mechanical diff could miss a schema → Mitigation: `tasks.md` uses `grep -R "@primary_key {:id, :binary_id" lib/` before/after (expect 35→0), full suite as gate.

## Migration Plan

1. Apply the 35 one-line declaration changes (single commit, no migration).
2. Run `mix ecto.migrate` (no-op expected), `mix precommit`, `mix test` (551 passing, zero warnings).
3. Rollback: revert commit (new v7 rows remain valid UUIDs under the old declaration — generation only affects new inserts).

## Open Questions

- None blocking. Follow-up candidate (not this change): opaque public slugs for career URLs if timestamp-in-URL becomes a concern.
