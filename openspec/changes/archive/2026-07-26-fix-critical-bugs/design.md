## Context

The app has three critical bugs blocking core functionality:
1. Job creation and candidate creation both crash with `tenant_id` null violations
2. Mobile navigation is completely absent

The root cause for bugs 1 & 2 is the same pattern: `tenant_id` is added to the attrs map via `Map.put` but then passed through `Ecto.Changeset.cast/3`, which silently drops it because `:tenant_id` is not in the cast whitelist. The correct pattern is to set `tenant_id` directly on the struct before building the changeset.

For bug 3, the nav links are wrapped in `hidden sm:ml-6 sm:flex sm:space-x-8` with no mobile toggle.

## Goals / Non-Goals

**Goals:**
- Fix job creation so it succeeds with or without pipeline selection
- Fix candidate creation so `tenant_id` is properly associated
- Add mobile hamburger menu with slide-out drawer for navigation

**Non-Goals:**
- Refactoring changeset patterns across the entire app
- Adding password recovery, onboarding, or other UX items
- Changing the overall nav design or layout structure

## Decisions

### 1. Fix `tenant_id` by setting it on the struct, not via changeset

**Decision:** In `create_job` and `create_candidate`, build the struct with `tenant_id` pre-set, then pass only user-supplied attrs to the changeset.

**Why:** This is the idiomatic Ecto pattern for fields that must never be user-controlled. Adding `tenant_id` to `cast` would be a security risk (users could submit arbitrary tenant IDs). Setting it on the struct before `changeset/2` is both safe and conventional.

**Alternative considered:** Adding `tenant_id` to the cast list with a guard — rejected because it's a security anti-pattern.

### 2. Handle empty `pipeline_id` in job creation

**Decision:** In `handle_event("create_job")`, filter out empty string `pipeline_id` before passing to `create_job`. Also set `tenant_id` on the struct in `Jobs.create_job/1`.

**Why:** The select field's "Default pipeline" prompt submits `""`. The changeset should receive either a valid UUID or nil. The `tenant_id` must be set on the struct since it's not in the cast list.

### 3. Mobile nav: hamburger button + slide-out drawer with Alpine.js

**Decision:** Add a hamburger button visible only below `sm` breakpoint. Use a Phoenix LiveView ColocatedHook with Alpine.js-style toggle state for the mobile menu drawer.

**Why:** Alpine.js is already available in the Phoenix ecosystem. A colocated hook keeps the logic co-located with the template. The desktop nav remains unchanged.

**Alternative considered:** CSS-only `:target` or checkbox hack — rejected because it doesn't integrate well with LiveView's rendering model.

## Risks / Trade-offs

- **Risk:** Changing `create_job`/`create_candidate` function signatures could break other callers → **Mitigation:** Search for all call sites; the functions are only called from their respective LiveViews
- **Risk:** Mobile nav drawer may need z-index tuning to overlay page content → **Mitigation:** Use `fixed inset-0 z-50` pattern with backdrop
