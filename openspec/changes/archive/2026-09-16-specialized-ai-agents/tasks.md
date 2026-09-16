## 1. Agent session & router

- [x] 1.1 Add `Treby.AI.Session` GenServer (registry per user, state, rebuild conversation from Conversations)
- [x] 1.2 Add `Treby.AI.Router.classify/2` (LLM classify, sticky, fallback to last_domain)
- [x] 1.3 Add `Treby.AI.Profiles` with recruiter/analytics/comms/admin `{prompt, toolset}`

## 2. Tool loop integration

- [x] 2.1 Extend `Treby.AI.Agent.chat/2` to accept a profile (toolset + prompt) instead of `Tools.all()`
- [x] 2.2 Add `handoff` tool and `Session` re-route on domain exit
- [x] 2.3 Refactor `Treby.AI.Tools` dispatch to resolve across domain registries

## 3. Extended tool registry (Recruiter first)

- [x] 3.1 Create `Treby.AI.Tools.Recruiter` (create_candidate, list/search/get candidate, create_application, move_application, add_note, update_candidate) calling existing business modules
- [x] 3.2 Verify `destructive?` flags and confirm flow for new tools
- [x] 3.3 Create `Treby.AI.Tools.Analytics` (pipeline_stats, job_views_report, candidate_compare, funnel_report)
- [x] 3.4 Create `Treby.AI.Tools.Comms` (send_message, schedule_message, create_email_template, invite_member)
- [x] 3.5 Create `Treby.AI.Tools.Admin` (add/remove_member, add_pipeline_stage, import_csv, update_settings)

## 4. Page read/write

- [x] 4.1 Enrich `Treby.AI.Context.assigns_snapshot` to serialize key Ecto structs (job, candidate, application) JSON-safe
- [x] 4.2 Include page state section in `system_prompt` (read)
- [x] 4.3 Keep `propose_form_fill` write path; verify `{:ai_apply_form}` relay in widget

## 5. Tests

- [x] 5.1 Session + router classify tests (sticky, fallback)
- [x] 5.2 Profile toolset selection test
- [x] 5.3 Handoff re-route test
- [x] 5.4 Recruiter tool tests against business modules (destructive confirm)
- [x] 5.5 Page context in prompt test

## 6. Specs & docs

- [x] 6.1 Write `openspec/specs/ai-agent/spec.md` (Purpose/Requirements/Scenarios)
- [x] 6.2 Update `site/features/ai-assistant.md` and sidebar/index if needed
- [x] 6.3 Regenerate screenshots

## 7. Final

- [x] 7.1 Run `mix precommit` and `openspec validate --strict` and fix issues
