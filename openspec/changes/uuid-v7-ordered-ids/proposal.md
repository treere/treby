## Why

All 35 schemas use random UUIDv4 primary keys, so `ORDER BY id` is meaningless and same-second `inserted_at` ties (second-precision timestamps) resolve arbitrarily — the pagination work had to stagger test timestamps to get deterministic pages. UUIDv7 (time-ordered, natively supported by Ecto 3.14) makes `id` order approximate insertion order, turning the `desc: id` tiebreak already added to listings into a real guarantee.

## What Changes

- Switch all 35 `@primary_key {:id, :binary_id, autogenerate: true}` declarations to `@primary_key {:id, Ecto.UUID, autogenerate: [version: 7, precision: :monotonic]}`; `@foreign_key_type :binary_id` stays (cast/dump unchanged, no generation on FKs).
- No migration (column type stays `uuid`); no API/route/UI changes; new rows get time-ordered ids, pre-existing v4 rows keep working and interleave arbitrarily under `ORDER BY id` (documented, acceptable pre-launch).
- Keep the explicitly staggered test timestamps (harmless, still deterministic).

## Capabilities

### New Capabilities
- _None_ — ordering semantics improve, no user-facing feature changes.

### Modified Capabilities
- `candidate-management`: Candidate listing tiebreak (`name`, `id`) SHALL reflect insertion order for rows created after the switch.
- `job-management`: Job listing (`inserted_at`, `id`) SHALL resolve same-second ties in insertion order for rows created after the switch.
- `applications`: Per-job application listing SHALL resolve same-second ties in insertion order for rows created after the switch.

## Impact

- **Modules:** 35 schema files under `lib/treby/**` (one-line primary-key declaration each); no context, LiveView, or query changes.
- **APIs:** None (id format stays canonical UUID string).
- **Dependencies:** None (Ecto 3.14 already provides v7 generation).
- **Migrations:** None.
- **Config:** None.
- **Risks:** v7 embeds unix_ms — visible in public career URLs (`/:slug/careers/:job_id`); accepted as low-risk (posting dates are public anyway; candidate ids live in authenticated URLs). Old v4 rows sort arbitrarily vs new v7 rows — documented, no backfill (PKs are referenced by FKs everywhere).
