## Context

Today workspace authorization is a binary `Membership.role` string (`admin` / `member`). The same binary gate is duplicated in four places: router `live_session` + `RequireRole` exact-match hook, scattered `role == "admin"` template guards, `SettingsNav.groups_for_role/1`, and AI `Tools.required_role/authorize/for_role` (`:any` vs `:admin`, ~39 admin-only tools). Every sensitive action shares one gate, so delegation without full admin is impossible, and FE/agent logic can drift.

Stakeholders: workspace admins (configure who can do what), recruiters/interviewers (scoped daily work), hiring managers (read + decide). Constraint: multi-tenancy is absolute — every permission resolution is scoped by `tenant_id`; candidate portal sessions never get assistant tools.

## Goals / Non-Goals

**Goals:**
- Single permission truth used by both UI and AI agent: action keys, preset defaults, per-workspace overrides, one `can?` contract.
- Preset roles `admin` (all, locked), `recruiter` (hiring operations), `interviewer` (scoped view + scorecards + availability).
- Admins can toggle allowed actions per non-admin role from Settings → Team; UI hides routes, menu entries, and buttons where the action is denied; agent hides tools from the model and enforces at run/confirm time.
- Fail-closed behavior: unknown actions and missing permission sets deny.
- Audited permission changes and safe migration of existing `member` memberships to `recruiter`.

**Non-Goals:**
- Fully custom admin-named roles (no `roles` table with arbitrary names in this change).
- Per-user exceptions outside the role (no per-membership overrides).
- Per-resource scoping beyond the existing pipeline advancer/examiner layer (no per-job ownership rules).
- Candidate-portal permissions (portal stays separate, no assistant).

## Decisions

### 1. Action keys, not per-tool permissions (~16 grouped keys, many tools → one action)

Each AI tool declares one required action; many tools share an action. UI routes/buttons check the same action. Keeps the admin matrix readable.

Groups (v1): `candidates_view/create/update/delete/merge`, `jobs_manage`, `applications_move/review`, `interviews_manage/view`, `scorecards_submit/manage_templates`, `pipeline_manage/assign_people`, `team_manage`, `settings_manage`, `fields_manage`, `webhooks_manage`, `audit_view`, `privacy_manage` (tenant exports/erasure, admin-only by default) + `privacy_view` (list/create data-privacy requests, granted to recruiters), `import_csv`, `comms_send`.

Alternative (per-tool permission, ~100 keys) rejected: matrix unreadable, admin fatigue, no benefit — tools in the same group always share the same trust level.

### 2. One pure resolution module, no web/AI deps

A single authorization module owns: action key list + metadata, preset defaults per role, `effective_permissions(role, overrides)`, `can?(effective, action)`. Both `TrebyWeb` (hooks, nav, templates) and `Treby.AI` (registry filter, run guard, context builder) call it. No duplicate role logic afterward; `RequireRole` exact-match and `required_role/0` are retired in favor of action checks.

Alternative (separate FE/agent policies) rejected: guaranteed drift, the exact bug this change fixes.

### 3. Overrides as rows, not JSON blob

New tenant-scoped store `role_permissions{tenant_id, role, action, allowed}` holding only cells the admin changed; resolution = preset default + override. Table over JSON column: queryable, auditable per-cell, trivial unique index `(tenant_id, role, action)`, no read-modify-write on a blob.

Alternative (JSON map on tenant) rejected: concurrent edits clobber, audit coarse.

### 4. Presets with locked admin

`admin` = all actions, not editable, not toggleable. `recruiter` default = current `member` capabilities plus explicitly chosen operational deletes TBD in specs (default keeps deletes admin-only to preserve current safety). `interviewer` default = view jobs/candidates/pipelines, list interviews, submit scorecards, manage own availability, nothing destructive. Invite/change-role flows offer exactly these three (+ admin).

Alternative (4th `viewer` preset now) deferred: `interviewer` with everything denied except view already covers read-only; add later if demand emerges.

### 5. Hide, then enforce (both surfaces)

- UI: permission-based `on_mount` guard redirects + flash on direct navigation; `SettingsNav` filters by permission; action buttons/menus render only when `can?`. No visible affordance for denied actions.
- Agent: profile toolset filtered by effective permissions before hitting the model (tools hidden from LLM); `run` re-authorizes; pending-confirm execution re-authorizes with the confirmer's current permissions (no escalation via stale runs). System prompt keeps showing role name for context but never as an authorization signal.

### 6. Caching: load per-request, invalidate by reload

Effective permissions are computed on mount/request from membership + overrides (single indexed query, small set). No long-lived cache. After an admin saves the matrix, affected LiveViews reload state via normal navigation/PubSub refresh; agent `Context.build` always rebuilds from current assigns. Stale-ctx window limited to in-flight requests.

Alternative (ETS/cached perms with TTL) rejected: invalidation complexity for zero measurable gain at this scale.

### 7. Error handling: fail-closed

Unknown action key → deny. Nil/unknown role → deny. Missing overrides row → preset default. Tool without declared action → treated as most restrictive of its group (deny unless explicitly mapped; migration maps all existing tools). UI guard failures redirect with permission flash; tool failures return `{:error, :unauthorized}` without revealing which permission is missing beyond the action name.

## Risks / Trade-offs

- [Matrix illegibility] → Mitigation: ~16 grouped actions with plain-language labels, grouped UI sections, locked admin column hidden.
- [Stale permissions mid-session] → Mitigation: rebuild per request/mount; confirm-time re-check; permission-change audit event documents who changed what.
- [Incomplete tool→action mapping] → Mitigation: migration task maps every existing tool; test asserts all registered tools declare an action.
- [Template guard leftovers] → Mitigation: task greps and replaces all `role == "admin"` guards; route-guard tests + tool visibility tests cover both surfaces.
- [Preset default disputes (e.g. should recruiter delete?)] → Mitigation: specs pin v1 defaults conservatively (deletes stay admin-only); admin toggles allow loosening per workspace.
- [Pipeline advancer layer interaction] → Mitigation: advancement requires BOTH stage-advancer assignment AND relevant action permission; documented in specs, covered by combined test.

## Migration Plan

1. `mix ecto.gen.migration` adds role preset values + `role_permissions` table with unique `(tenant_id, role, action)` and FK to tenants.
2. Data migration: `memberships.role = 'member'` → `'recruiter'`; `invites.role = 'member'` → `'recruiter'`; extend check constraints/validations to `admin/recruiter/interviewer`.
3. Backfill: no override rows (defaults apply); existing behavior preserved by choosing recruiter defaults = old member capabilities.
4. Deploy: migrate → release; no dual-write needed (single deploy, small table, no downtime).
5. Rollback: reverse migration restores `member` values; override table dropped (loss of toggles acceptable pre-GA, documented).

## Open Questions

- Should `recruiter` gain `candidates_delete/merge/bulk_delete` by default in v1, or stay admin-only until an admin opts in? (Proposal: stay admin-only.)
- Is `interviewer` allowed `comms_send` (messages to candidates) or strictly scorecards + availability? (Proposal: no send in v1.)
- Do permission changes force-logout/reload other sessions immediately, or is next-navigation refresh sufficient for v1? (Proposal: next-navigation + confirm-time re-check.)
