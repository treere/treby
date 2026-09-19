## Context

`lib/treby_web/live/settings_live/data_privacy.ex` already distinguishes `scope=user` (own data) vs `scope=tenant` (company data) and checks `current_membership.role != "admin"` for tenant scope. `lib/treby_web/router.ex` originally placed the whole LiveView under `live_session :admin` (RequireRole admin), blocking members from user-scope actions, which contradicts `openspec/specs/data-privacy-export` and `data-privacy-erasure` where user scope is for any member. `lib/treby_web/settings_nav.ex` already had a workaround to show Data & Privacy for members as "Manage my data" but the route still 403.

Stakeholders: members who need to export/delete own data, admins who need tenant-wide export/erasure, compliance (GDPR).

## Goals / Non-Goals

**Goals:**
- Clarify in specs why tenant scope is admin-only (contains company-wide PII, audit, all candidates) while user scope is for any member.
- Keep implementation as is after the router fix (already moved to `:data_privacy` live_session, nav role :member) — no code change beyond spec.

**Non-Goals:**
- Changing the 7-day grace or S3 signing.
- Adding new UI for tenant scope to members.

## Decisions

**Decision 1: Keep tenant scope admin-only, user scope for all.**
- *Choice*: No code change beyond the already landed router fix (`:data_privacy` live_session) and `settings_nav` role :member. Specs will state the rationale: tenant export/erasure touches all tenant data, must be audited and requires slug confirmation.
- *Rationale*: GDPR requires user can access own data, but company data is PII of all candidates and must be restricted. Existing `data_privacy.ex:16` already enforces `Only admins can ...`.
- *Alternative*: Make tenant scope visible but disabled for members — rejected, hidden is clearer and already implemented via `:if={@current_membership.role == "admin"}` on tenant forms.

## Risks / Trade-offs

- [Risk] Members may still try to craft `scope=tenant` via JS bypass → Mitigation: server checks `role != "admin"` and returns flash, already tested.

## Migration Plan

- No migration. Deploy is already done (`fix/bug-fixes:c20aa0a`). Spec sync only.

## Open Questions

- None.
