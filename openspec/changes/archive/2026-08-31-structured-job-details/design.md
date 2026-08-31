## Context

Current `jobs` table (`Treby.Jobs.Job`) stores only `title`, `description`, `salary_range`, `status`, `visible`, `custom_fields`. Team members entering jobs have no dedicated inputs for location/contract type; candidates on `CareersLive.Index/Show/GlobalIndex` see only title+salary. During exploration, salary was the only structured cue — location/remote signal was buried in free text. Competitors and user expectations assume pills like "Remote · Full-time · Milan" at list level and a meta row on detail.

Constraints: multi-tenant, existing jobs must stay valid, no heavy refactor of `custom_fields`.

## Goals / Non-Goals

**Goals:**
- Add optional structured fields without forcing backfill.
- Surface fields on both list and detail public pages with i18n.
- Keep internal job form backward-compatible.

**Non-Goals:**
- Full faceted search/filter engine — v1 is display only; search extension is opportunistic.
- Geocoding / map — out of scope.
- Breaking changes to `custom_fields` or pipeline.

## Decisions

- **Nullable string columns (`location`, `employment_type`, `workplace_type`):** Simplest migration, no enum type. Validation via `validate_inclusion` on changeset. Null = not shown. Alternative PG enum rejected (harder to migrate, less flexible).
- **Enums:** `employment_type ∈ {full_time, part_time, contract, internship}` and `workplace_type ∈ {on_site, hybrid, remote}`. Store snake_case, display via gettext mapping `Full-time`, `Part-time`, etc. Covers 90% cases; extensible via custom_fields for edge cases.
- **Published date = `inserted_at`:** No new column; use existing timestamp for `Posted on …`. Alternative `published_at` deferred — adds complexity for draft/visible flow.
- **UI:** Badges (`badge badge-sm`) for types on list cards; meta row with hero icons (`map-pin`, `briefcase`, `computer-desktop`) on detail. Keeps Tailwind 4, no new dep.
- **Internal form (`JobsLive`):** Add text input for `location`, selects for the two enums with prompt "—". Reuse `<.input>` component. Prefill from existing values.
- **Search:** If included, extend `search_visible_jobs` to `ilike(location)` as well; keep single query param `query`. No separate filters yet — avoids URL param explosion.

## Risks / Trade-offs

- [Risk] Old jobs show empty meta → looks sparse → Mitigation: conditional rendering (`:if={job.location}`) so absence is invisible.
- [Risk] Translation drift for enum labels → Mitigation: centralize mapping function `humanize_employment_type/1` in `Treby.Jobs` with gettext.
- [Risk] Migration on large table lock → Mitigation: nullable columns, no backfill, `ALTER TABLE ADD COLUMN` is fast on PG 14.

## Migration Plan

1. `mix ecto.gen.migration add_structured_fields_to_jobs` — add 3 nullable columns.
2. Deploy, run `mix ecto.migrate` (zero-downtime, no data rewrite).
3. Rollback: `mix ecto.rollback` drops columns; UI guards handle nil, so safe.

## Open Questions

- Should `location` support multiple values (e.g., "Milan, Rome")? For v1, free-text single string is sufficient; multi-location via description still possible.
- Should global board filter by `workplace_type=remote`? Deferred to separate filter change.
