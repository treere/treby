## Context

Three guard implementations protect team routes: `Plugs.RequireMembership` (controllers), `Hooks.RequireMembership` (LiveView), and `Hooks.RequirePermission` (action checks). All three resolve tenant-by-slug plus membership independently. The router repeats a 4-hook `on_mount` base in 11 `live_session` blocks. `Hooks.RequireRole` is deprecated with zero callers. The previous change (`unify-authorization-policy`) already centralized the check itself in `Policy.can?` and the builder in `Actor.from`; this change centralizes guard resolution and wiring.

## Goals / Non-Goals

**Goals:**
- One guard core (`Memberships.access_for/2`) used by plug and hooks.
- `RequirePermission` reuses assigns instead of re-reading membership.
- Router `on_mount` repetition removed; adding a gated session is one line.
- Dead `RequireRole` deleted.

**Non-Goals:**
- No UX change: redirects, flash messages, and 404 behavior stay identical.
- No merge of plug and hook into one module (different transports: `conn` vs `socket`).
- No change to `Policy`/`Actor` contracts.

## Decisions

- **Core in `Memberships`, not a new module.** Membership queries already live there; a context function is testable without `conn`/`socket`. A new `Access` module would be a one-consumer abstraction.
- **Thin adapters preserve exact responses.** Plug keeps 404-on-unknown-slug and redirect-on-no-membership; hooks keep halt+redirect+flash. Shared core only, distinct edges. Alternative (identical responses) rejected: controller 404 for unknown slug is intentional.
- **`RequirePermission` prefers assigns, falls back to `access_for/2`.** Router mounts `RequireMembership` first, so the hot path does zero queries; the fallback keeps the hook safe when mounted alone. Alternative (hard dependency on mount order) rejected: silent pass-through on misordering would fail open.
- **Delete `RequireRole`, no shim.** Zero callers, already `@deprecated`. Grep before delete to confirm.
- **Router dedup via module attribute + private helper, not a macro.** 11 static lists need no metaprogramming: `@base_mount [...]` plus `perm_session(name, action, block)`-style helper. Alternative (macro) rejected: harder to grep, one-use macro is over-engineering.
- **Keep the legacy `/app` no-slug fallback** in `Hooks.RequireMembership` (first membership's tenant). Removing it would break bookmarked URLs; out of scope.

## Risks / Trade-offs

- [Risk] Hook order swap (permission before membership) silently changes query count → Mitigation: fallback resolve keeps behavior correct; contract test mounts permission hook both with and without membership assigns.
- [Risk] Flash/redirect string drift between plug and hook during rewrite → Mitigation: spec pins each message and target; tests assert exact strings.
- [Risk] `access_for/2` N+1 (`available` list query per request) → Mitigation: same queries as today, no new ones; `available` already loaded by both current implementations.

## Migration Plan

Pure refactor, no DB migration, no config change. Deploy normally; rollback is `git revert` (single commit). Verify with `mix test` (new guard contract tests + existing router/live tests) and `mix precommit`.
