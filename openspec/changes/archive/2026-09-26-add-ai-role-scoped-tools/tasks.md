## 1. Authorization core

- [x] 1.1 Add `ctx.actor = %{id: user.id, role: membership_role}` in `Treby.AI.Context.build/2`; keep `ctx.role`; add a test asserting actor role equals membership role (not `User.role`). Exit: `mix test test/treby/ai/context_test.exs`
- [x] 1.2 Add `Treby.AI.Tools.required_role/1` with `:any` fallback for tools that do not export `required_role/0`. Exit: unit test in `test/treby/ai/tools_test.exs`
- [x] 1.3 Add `Treby.AI.Tools.for_role/2` (or `Profiles.get/2`) returning the toolset filtered by role. Exit: test asserts admin tools present for `"admin"` and absent for `"member"`

## 2. Enforce in the agent loop

- [x] 2.1 In `Treby.AI.Agent`, filter the profile toolset by role before `llm_tools/1`. Exit: test asserts a member turn never sends an `:admin` tool to the model
- [x] 2.2 In `Agent.read_result/2`, re-check `required_role/0` against `ctx.role` before `run/2`; return `{:error, :unauthorized}` on mismatch. Exit: test with an admin tool + member ctx
- [x] 2.3 In `Agent.confirm_tool_run/2`, re-check role before executing a pending run. Exit: test that a member cannot confirm an admin pending run and no mutation occurs

## 3. Role-gate existing tools

- [x] 3.1 Add `required_role/0` to admin-only existing tools: `AddMember`, `RemoveMember`, `UpdateSettings`, `AddPipelineStage`, `ImportCsv`, `InviteMember`, `CreateEmailTemplate`, `DeleteJob`. Exit: `mix test test/treby/ai/tools/`
- [x] 3.2 Change every existing write tool to pass `ctx.actor` instead of `ctx[:user]` to contexts (`AddPipelineStage`, `RemoveMember`, `InviteMember`, `CreateEmailTemplate`, `CreateJob`, `UpdateJob`). Exit: tool tests still pass
- [x] 3.3 Add a self-check in tools whose context has no actor parameter (`AddMember`, `UpdateSettings`, `DeleteJob`, `CreateCandidate`, `UpdateCandidate`, `CreateApplication`, `MoveApplication`, `AddNote`, `ImportCsv`, `SendMessage`, `ScheduleMessage`). Exit: each returns `{:error, :unauthorized}` for a member

## 4. Full tool catalog (read)

- [x] 4.1 Jobs/candidates reads: `get_job`, `list_candidate_duplicates` (admin). Exit: tool tests against contexts
- [x] 4.2 Applications/pipeline reads: `list_applications`, `list_pipelines`, `list_pipeline_stages`, `list_stage_people`. Exit: tool tests
- [x] 4.3 Notes/interviews/scorecards reads: `list_notes`, `list_interviews`, `find_interview_substitutes` (admin), `list_scorecards`, `list_scorecard_templates`. Exit: tool tests
- [x] 4.4 Calendar/availability reads: `list_calendar_connections`, `get_free_busy`, `list_availability_rules`. Exit: tool tests
- [x] 4.5 Comms reads: `list_scheduled_messages`, `list_email_templates`. Exit: tool tests
- [x] 4.6 Analytics: `dashboard_summary`. Exit: tool test
- [x] 4.7 Team/workspace reads: `list_members`, `list_invites` (admin), `list_custom_fields`, `get_career_page`. Exit: tool tests
- [x] 4.8 Ops reads: `preview_csv_import`, `list_notifications`, `get_notification_preferences`, `list_activities`, `list_audit_events` (admin), `list_data_requests`, `list_webhooks` (admin). Exit: tool tests

## 5. Full tool catalog (write, destructive)

- [x] 5.1 Candidates/pipeline config: `delete_candidate` (admin), `merge_candidates` (admin), `set_application_reviewed`, `create_pipeline` (admin), `update_pipeline` (admin), `delete_pipeline` (admin), `update_pipeline_stage` (admin), `delete_pipeline_stage` (admin), `assign_stage_person` (admin), `unassign_stage_person` (admin). Exit: tool tests + destructive flag test
- [x] 5.2 Notes: `update_note`, `delete_note` (author/admin via actor). Exit: tool tests
- [x] 5.3 Interviews/scorecards: `schedule_interview`, `cancel_interview`, `complete_interview`, `submit_scorecard`, `create/update/delete_scorecard_template` (admin). Exit: tool tests
- [x] 5.4 Calendar/availability: `create_calendar_event`, `create/update/delete_availability_rule`. Exit: tool tests
- [x] 5.5 Comms: `cancel_scheduled_message`, `reschedule_scheduled_message`, `retry_scheduled_message`, `update_email_template` (admin), `delete_email_template` (admin). Exit: tool tests
- [x] 5.6 Team/workspace: `delete_invite` (admin), `update_member_role` (admin), `create/update/delete_custom_field` (admin), `update_career_page` (admin). Exit: tool tests
- [x] 5.7 Ops: `bulk_move_stage`, `bulk_review`, `bulk_send_message`, `bulk_delete_candidates` (admin), `set_notification_preference`, `create_data_request`, `cancel_data_request`, `create/update/delete_webhook` (admin), `test_webhook` (admin). Exit: tool tests
- [x] 5.8 Register every new tool in the right domain registry (`Recruiter`, `Analytics`, `Comms`, `Admin`) so profiles expose them. Exit: registry test asserts counts and role split

## 6. UI

- [x] 6.1 `TrebyWeb.AiChatWidget.handle_event("confirm_tool_run", ...)` builds the full role-scoped context (including `role`/`actor`) and passes it to `Agent.confirm_tool_run/2`. Exit: LiveView test that a member cannot confirm an admin run

## 7. Tests

- [x] 7.1 Context actor test (membership role, not user role)
- [x] 7.2 Role filter tests (exposure) for member and admin
- [x] 7.3 Enforcement tests (read, confirm) for member on admin tools
- [x] 7.4 Catalog smoke test: every registered tool has `name/0`, `description/0`, `schema/0`, `destructive?/0`, `required_role/0`, `run/2`
- [x] 7.5 Tool tests against business modules for the new domains (interviews, scorecards, calendar, bulk, webhooks)
- [x] 7.6 Run `mix test` and fix failures

## 8. Specs & docs

- [x] 8.1 Write delta specs under this change (already drafted: `ai-agent-authorization`, `ai-agent`, `ai-actions-layer`); keep them in sync with implementation
- [x] 8.2 Update `site/features/ai-assistant.md` to describe what the assistant can do per role, without code references
- [x] 8.3 Update `site/features/index.md` and sidebar in `site/.vitepress/config.ts` only if a new page is added
- [x] 8.4 No visual UI change (confirm card unchanged) — screenshots not regenerated

## 9. Final

- [x] 9.1 Run `mix precommit` and `openspec validate add-ai-role-scoped-tools --strict` and fix issues
