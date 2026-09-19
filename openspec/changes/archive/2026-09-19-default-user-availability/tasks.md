## 1. Migrations

- [x] 1.1 Create migration: add `timezone` string column to `tenants` (default `"UTC"`, not null)
- [x] 1.2 Create migration: add `timezone` string column to `users` (default `"UTC"`, not null)
- [x] 1.3 Create migration: `availability_rules` — drop unique index on `(tenant_id, user_id, day_of_week)`; add `scope` string column (default `"user"`); make `user_id` nullable; drop `timezone`, `buffer_before`, `buffer_after` columns

## 2. Schema & Context

- [x] 2.1 Update `Treby.Availability.AvailabilityRule` changeset: add `scope` cast/validate inclusion `"company"`/`"user"`; make `user_id` optional when `scope == "company"`; remove `timezone`/buffer fields
- [x] 2.2 Add availability context helpers: `list_company_rules/1`, `list_user_rules/1`, `resolve_rules_for_user/1` (user rules, else company template, else `[]`)
- [x] 2.3 `Tenants.create_tenant/1`: accept `timezone` attr (default `"UTC"`); after insert, seed 10 company rules (Mon–Fri × {09:00–13:00, 14:00–18:00}, `scope = "company"`, `tenant_id`) in `tenant.timezone`
- [x] 2.4 `Accounts.create_user/1`: set `user.timezone` default = tenant timezone; after insert, seed user rules as a copy of the company template (`scope = "user"`, `user_id`, `tenant_id`) in user timezone
- [x] 2.5 Rewrite `Treby.Availability.compute_slots/4`: group rules into a per-day list of windows, union windows, interpret times in owner timezone, fallback to company template, drop buffer logic
- [x] 2.6 Rewrite `Treby.Availability.compute_overlapping_slots/4`: resolve each examiner's window set, intersect window sets across examiners (replace `latest_start`/`earliest_end` single-window logic)

## 3. Registration

- [x] 3.1 `TrebyWeb.RegistrationController.create_account/3`: pass the browser timezone into `Tenants.create_tenant(%{name: ..., timezone: ...})`
- [x] 3.2 Registration form (HEEx + ColocatedHook or `assets/js` hook): capture `Intl.DateTimeFormat().resolvedOptions().timeZone` into a hidden input and submit it

## 4. LiveView / UI

- [x] 4.1 `SettingsLive.Availability`: remove per-rule timezone; add a user timezone selector; allow adding multiple rules per day (two rows for the default split)
- [x] 4.2 Create `SettingsLive.CompanyAvailability` (admin-only): edit company template rules (multiple windows/day) and company timezone
- [x] 4.3 Add route `/app/settings/company-availability` (both app scopes) and a nav link in `SettingsLive.Index`, gated to admins

## 5. Tests

- [x] 5.1 Context tests: company template seeded on `create_tenant`; user rules copied on `create_user`; resolution fallback; multiple windows unioned in `compute_slots`; `compute_overlapping_slots` with multi-window examiners; UTC fallback for missing timezone
- [x] 5.2 LiveView tests: user availability page edits own rules/timezone; company availability page editable by admin and hidden/forbidden for non-admins; registration seeds company timezone from browser value

## 6. Specs & Docs

- [x] 6.1 Update `openspec/specs/availability-rules/spec.md` (multiple windows, timezone levels, no buffer, company fallback, snapshot at creation)
- [x] 6.2 Add `openspec/specs/company-availability/spec.md` (new capability)
- [x] 6.3 Add `site/features/company-availability.md`, register it in `site/.vitepress/config.ts` sidebar and `site/features/index.md` (new feature)
- [x] 6.4 Regenerate screenshots with `node scripts/screenshots.mjs`
- [x] 6.5 Run `openspec validate --strict` and `mix precommit`, fix issues
