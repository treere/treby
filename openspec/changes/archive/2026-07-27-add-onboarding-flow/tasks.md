## 1. Database Migration

- [x] 1.1 Generate migration to add `onboarding_checklist_dismissed` boolean column (default: false, null: false) to users table
- [x] 1.2 Run migration and verify

## 2. Query Helpers

- [x] 2.1 Add `Treby.Jobs.tenant_has_jobs?/1` — returns boolean if tenant has at least one job
- [x] 2.2 Add `Treby.Candidates.tenant_has_candidates?/1` — returns boolean if tenant has at least one candidate
- [x] 2.3 Add `Treby.Teams.has_members_besides?/2` — returns boolean if tenant has members other than the given user
- [x] 2.4 Add `Treby.Branding.has_branding?/1` — returns boolean if tenant has configured career page branding

## 3. Onboarding Checklist Component

- [x] 3.1 Create `TrebyWeb.OnboardingChecklist` function component in `core_components.ex` with attrs: `steps`, `current_user`
- [x] 3.2 Implement checklist rendering: step list with checkmarks/strikethrough for completed, progress bar, dismiss button, "Don't show again" link
- [x] 3.3 Wire dismiss (X) button to toggle `@show_onboarding` assign via JS toggle
- [x] 3.4 Wire "Don't show again" to a `handle_event("dismiss-onboarding", ...)` that updates the user's `onboarding_checklist_dismissed` field

## 4. Shared Empty State Component

- [x] 4.1 Create `<.empty_state>` function component in `core_components.ex` with attrs: `icon`, `title`, `description`, `action` (optional map with `href` and `label`)
- [x] 4.2 Style with centered layout, hero icon, muted text, and prominent CTA button

## 5. Dashboard Integration

- [x] 5.1 Update `DashboardLive.mount/3` to compute onboarding steps using the query helpers and assign `@onboarding_steps`, `@show_onboarding`
- [x] 5.2 Update dashboard template to render `<.onboarding_checklist>` between welcome header and stat cards (conditionally on `@show_onboarding`)
- [x] 5.3 Replace dashboard empty states (upcoming interviews, stale candidates, pipeline overview) with `<.empty_state>` component
- [x] 5.4 Add welcome message and CTA for new users when no data exists on dashboard

## 6. Page Empty States

- [x] 6.1 Replace Jobs index inline empty state with `<.empty_state>` — icon, title, description, "Create your first job" button
- [x] 6.2 Replace Candidates index inline empty state with `<.empty_state>` — icon, title, description, "Add a candidate" and "Import from CSV" buttons
- [x] 6.3 Add empty state to Pipeline index for when no applications exist — icon, title, description, "Create a job" button

## 7. Tests

- [x] 7.1 Test `tenant_has_jobs?/1`, `tenant_has_candidates?/1`, `has_members_besides?/2`, `has_branding?/1` query helpers
- [x] 7.2 Test onboarding checklist renders for new user with all steps incomplete
- [x] 7.3 Test onboarding checklist shows correct progress when some steps are complete
- [x] 7.4 Test onboarding checklist hides when all steps are complete
- [x] 7.5 Test dismiss button hides checklist for current session
- [x] 7.6 Test "Don't show again" persists dismissal and hides checklist on reload
- [x] 7.7 Test empty states render on Jobs, Candidates, Pipeline pages when lists are empty
- [x] 7.8 Test empty state CTA links navigate to correct pages

## 8. Final Verification

- [x] 8.1 Run `mix precommit` and fix any issues
