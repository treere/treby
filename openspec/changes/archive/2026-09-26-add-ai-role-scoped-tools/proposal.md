## Why

The AI assistant is supposed to let the hiring team work through chat instead of clicking
through the UI. Today it falls short in two ways:

1. **It does not act as the connected user.** Every tool is scoped only by `tenant_id`.
   The app already has an authorization convention (`context functions accept an optional
   actor and return {:error, :unauthorized}`), but most AI tools never pass the user, so the
   agent can perform admin-only actions regardless of the caller's role. The tools that do
   pass `ctx[:user]` compare `User.role`, while the UI authorizes on `Membership.role` — two
   sources of truth that can disagree.
2. **Tool coverage is a slice, not the system.** ~30 tools cover jobs, candidates,
   applications, notes, a few analytics, comms and workspace admin. Interviews, scorecards,
   calendar, availability, custom fields, notifications, activities, bulk operations,
   data-privacy requests and webhooks have no tool at all.

We want the agent to be a **proxy of the connected person**: it can read and do everything
that person's role allows in the workspace, and nothing more. Candidate-portal users are out
of scope (no assistant there).

## What Changes

- **Single role source of truth.** Authorization for the agent, and for the contexts it
  calls, uses the **membership role** (`Membership.role`) of the active workspace. Build an
  explicit `ctx.actor = %{id, role}` and pass it to every tool/context call, so the existing
  `actor.role != "admin"` checks become correct and consistent with the UI.
- **Per-tool capability declaration.** Each tool module declares `required_role/0` returning
  `:any` (default) or `:admin`. A shared helper resolves it with an `:any` fallback.
- **Role-scoped tool exposure (defense in depth).** The agent SHALL filter the profile
  toolset by `ctx.role` before handing tools to the LLM, AND re-check `required_role/0` in
  `run/2` and in `confirm_tool_run/2`. A member never sees or executes an admin tool.
- **Full tool catalog.** Add tools across every staff-facing context, split into read
  (run immediately) and write (destructive, require confirmation). Write tools call existing
  context functions with `ctx.actor` so per-resource rules (e.g. pipeline stage advancer)
  still apply.
- **Keep profiles + router.** With the full catalog the flat tool list would be ~100 items;
  the existing domain profiles + LLM router keep each turn's visible toolset small. Profiles
  remain a selection aid; role is the hard gate.
- **Fix the confirmation context.** `confirm_tool_run` currently receives
  `%{tenant_id, user}` with no role; it SHALL receive the full role-scoped context so the
  re-check and the actor pass-through work at confirmation time.
- **Non-goal:** no assistant in the candidate portal.

## Capabilities

### New Capabilities
- `ai-agent-authorization`: membership-role source of truth, `ctx.actor`, per-tool
  `required_role/0`, role-scoped tool exposure, and enforcement at run/confirm time.

### Modified Capabilities
- `ai-agent`: replace "Extended tool coverage" with comprehensive, role-scoped coverage of
  every staff context; tools are filtered by role before the loop.
- `ai-actions-layer`: tools now declare `required_role/0` and pass `ctx.actor` (not the raw
  user struct) to contexts.

## Impact

- Dependencies: none new.
- Modules under `lib/treby/`:
  - Modified: `Treby.AI.Context` (add `actor`), `Treby.AI.Agent` (role filter + confirm
    re-check), `Treby.AI.Profiles` (role-aware toolset), `Treby.AI.Tools` (role helper),
    `Treby.AI.Tools.Recruiter|Analytics|Comms|Admin|Shared` (registry entries), every
    existing tool module (add `required_role/0`, pass `ctx.actor`).
  - New: tool modules for the ~70 missing actions (jobs read, candidate delete/merge,
    applications list/review, pipeline config, notes list/update/delete, interviews,
    scorecards, calendar/availability, scheduled messages, email template CRUD, dashboard,
    team invites/roles, custom fields, career page, bulk operations, notifications,
    activities, audit, data-privacy requests, webhooks), plus a shared `required_role`
    helper.
  - UI: `TrebyWeb.AiChatWidget.confirm_tool_run` passes the full context.
- Migrations: none (no schema change).
- Tenant isolation: unchanged — `tenant_id` always from `ctx`, never from the conversation.
- Security: closes the current privilege-escalation gap where a `member` could invoke admin
  tools (add/remove member, update settings, delete job) via the assistant.
