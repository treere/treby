## 1. Repository callbacks

- [x] 1.1 Add `prepare_query/3` (scope when schema has `tenant_id` field, raise when tenant missing without opt-out), `default_options/1`, `put/get_tenant_id` to `Treby.Repo`
- [x] 1.2 Re-verify the 9 field-less schemas by grep and cover pass-through with a test on a global schema query

## 2. Entry points

- [x] 2.1 Set process tenant in web pipeline: plug for controllers, `RequireMembership.on_mount` for LiveViews
- [x] 2.2 Set process tenant from job args in all 5 Oban workers; pass `skip_tenant_id: true` in health-check async tasks
- [x] 2.3 Explicit `skip_tenant_id: true` with comment on pre-auth token queries (`password_reset_token`, `registration_otp`) and any global admin paths the suite exposes

## 3. Test fallout

- [x] 3.1 Establish tenant in `DataCase`/`ConnCase` setup and seeds; run full suite and fix every raise by establishing tenant (preferred) or explicit skip
- [x] 3.2 Add regression tests: cross-tenant rows invisible, unscoped query raises, explicit option wins

## 4. Verify

- [x] 4.1 Run `mix precommit` and `openspec validate --changes`, fix all issues

No `site/` update: internal change, no user-visible behavior.
