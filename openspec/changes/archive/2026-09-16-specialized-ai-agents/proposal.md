## Why

The current AI assistant is a single hand-written agent (`Treby.AI.Agent`) wired to only six job-CRUD tools. Most recruiting work still forces the user to click through the UI. We want the chat to perform end-to-end workflows so the user interacts with the UI as little as possible, while keeping explicit human confirmation on destructive actions.

## What Changes

- Introduce specialized agent **profiles** (recruiter, analytics, comms, admin). The existing single ReAct tool loop in `Treby.AI.Agent` is reused; a router selects the right `(system_prompt, toolset)` per turn.
- Add an LLM **router** that classifies intent into a domain, sticky per session with periodic re-classification, and lets an agent signal a domain exit (handoff).
- Extend the **tool set** beyond job CRUD to the whole system (candidates, applications, pipeline stages, interviews, scorecards, notes, analytics, comms, admin). Each tool calls existing business modules directly.
- Strengthen **page interaction**: the agent already receives an `assigns_snapshot` of the current LiveView; expose it in the prompt (read), and keep `propose_form_fill` to write form values to the page (already via `host_pid`).
- Keep **human confirmation** on destructive tools (`persist_pending` / `confirm_tool_run`), unchanged.

## Capabilities

### New Capabilities
- `ai-agent`: multi-agent profile engine, LLM router, extended tool registry, and page read/write interaction.

### Modified Capabilities
- (none required; `ai-chat-widget` already relays `ai_apply_form` and `ai_stream`)

## Impact

- Dependencies: none new (ReqLLM is already present).
- Modules under `lib/treby/`:
  - New: `Treby.AI.Session` (per-user GenServer holding conversation + current domain), `Treby.AI.Router` (LLM classify), `Treby.AI.Profiles` (domain -> `{prompt, toolset}`), `Treby.AI.Tools.Recruiter`, `Treby.AI.Tools.Analytics`, `Treby.AI.Tools.Comms`, `Treby.AI.Tools.Admin`.
  - Modified: `Treby.AI.Agent` (accept toolset + profile prompt; handoff signal), `Treby.AI.Context` (expose page state in prompt), `Treby.AI.Tools` (dispatch across domain registries).
- Migrations: none.
- Tenant isolation: `ctx` already carries `tenant_id`; tools operate only on the current workspace and never accept a tenant id from the conversation.
