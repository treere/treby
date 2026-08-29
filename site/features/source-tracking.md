# Source Tracking

Track where candidates come from and slice analytics by source.

## Sources

Admins manage sources in **Settings → Sources** (`lib/treby_web/live/settings_live/sources.ex`, `lib/treby/sources/source.ex`):

- Tenant-scoped, ordered by `position` (`Sources.list_sources/1`)
- Created via `Sources.create_source/1`, renamed via `update_source/2` (propagates the denormalized `source` string on existing applications)
- Typical values: "LinkedIn", "Referral", "Careers page", "Agency"

## Tagging

- Applications carry a `source` field (denormalized string, set at apply time or during CSV import)
- The apply form, manual add, and CSV import all expose a **source** selector
- Sources are configurable per tenant — no hardcoded enum

## Analytics

The analytics dashboard shows a **Source Breakdown** (`lib/treby/pipeline/pipeline.ex:1179` `source_breakdown/1`) — count per source, globally or per-pipeline when a pipeline is selected:

```
Source breakdown (all pipelines)
  Careers page  ████████  42
  LinkedIn      █████      27
  Referral      ███        14
  Unknown       █          3
```

Use it to answer "which channels actually hire?" without leaving Treby.
