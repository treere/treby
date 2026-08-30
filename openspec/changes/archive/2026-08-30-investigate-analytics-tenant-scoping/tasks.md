## 1. Fix queries

- [x] 1.1 Scope pipeline_counts_per_stage, source_breakdown, average_time_to_hire, stage_conversion_rates for tenant_id when pipeline_id is nil
- [x] 1.2 Update AnalyticsLive.load_analytics to pass tenant_id

## 2. Tests

- [x] 2.1 Add regression test for tenant isolation

## 3. Polish

- [x] 3.1 Run openspec validate and mix precommit
