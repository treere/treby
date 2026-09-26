## 1. Migration and data model

- [x] 1.1 Generate migration for new preset roles and role_permissions table with unique tenant/role/action index and backfill member to recruiter
- [x] 1.2 Extend membership and invite role validation to admin/recruiter/interviewer and verify tenant isolation
- [x] 1.3 Add role-permission override context with audit logging and verify with mix test test/treby/memberships_test.exs

## 2. Permission core

- [x] 2.1 Implement action key list with grouped metadata plus preset defaults and effective resolution with can? check
- [x] 2.2 Map every registered AI tool to exactly one action key and add test asserting full coverage
- [x] 2.3 Rebuild agent context with effective permissions and verify hidden-tool filtering path

## 3. Agent enforcement

- [x] 3.1 Replace required_role with required action in registry filter, run guard, and confirm-time re-check with fail-closed defaults
- [x] 3.2 Update agent system prompt and profile toolsets for new presets and verify with mix test test/treby/ai/

## 4. Web guards and navigation

- [x] 4.1 Replace RequireRole exact-match hook with permission-based guard redirecting with flash on denial
- [x] 4.2 Convert SettingsNav role groups to permission visibility and hide empty groups
- [x] 4.3 Replace scattered role == admin template guards with can? checks hiding buttons, menus, and links

## 5. Admin configuration UI

- [x] 5.1 Build Roles and permissions matrix in Settings Team for recruiter/interviewer toggles with locked admin column
- [x] 5.2 Update invite form and role-change flow to preset roles and verify acceptance creates correct membership
- [x] 5.3 Wire matrix save to audit log plus state refresh and verify with mix test test/treby_web/live/settings_live_test.exs

## 6. Verification

- [x] 6.1 Add permission matrix tests for resolution, overrides, tenant isolation, fail-closed unknown actions, and advancer plus action combination
- [x] 6.2 Add route-guard and tool visibility/enforcement tests for denied direct navigation and hidden LLM tools
- [x] 6.3 Migrate legacy require_role tests to new presets and run mix test test/treby_web/live/require_role_test.exs

## 7. Specs and user docs

- [x] 7.1 Sync main specs at openspec/specs/action-permissions/spec.md, role-permission-config, role-based-access, team-management, ai-agent-authorization, settings-navigation with Purpose/Requirements and Scenario WHEN/THEN
- [x] 7.2 Update user manual pages in site/features/ plus sidebar in site/.vitepress/config.ts and site/features/index.md using menu paths and English only, then regenerate screenshots with node scripts/screenshots.mjs and node scripts/screenshots.mjs --axe

## 8. Final validation

- [x] 8.1 Run mix precommit and openspec validate --strict and fix issues
