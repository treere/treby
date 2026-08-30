## Context

After `workspace-picker-switcher` lands, `users` is global (`lower(email)` unique) and `memberships(user_id,tenant_id,role)` is the access gate with URL-scoped workspaces `/:tenant_slug/app/*`. `InviteController.create` still does `build_assoc(tenant,:users)` which would recreate a duplicate identity. This change must re-use identity.

## Goals / Non-Goals

**Goals:**
- Re-fetch authoritative identity by `invite.email` and create a membership instead of a duplicate user.
- Idempotent accept (re-clicking an already-accepted invite just redirects).
- Correct handling when visitor is anon, same user, or a different logged-in user.
- Redirects land on `/:tenant_slug/app`.

**Non-Goals:**
- New tables or migrations (relies on prerequisite).
- Changing email templates beyond redirect targets.
- Subdomain or per-membership display names.

## Decisions

**1. Source of truth is `invite.email`, not `current_user`.**
`GET/POST /invite/:token` always does `user = Accounts.get_user_by_email(invite.email)` (global lower lookup). Rationale: invite is addressed to an email, not to whoever happens to be logged in. Alternative "associate with current_user" rejected — violates invite intent.

**2. Four states.**
- `user == nil` → render locked-email registration form → `POST` creates user + membership.
- `user != nil && anon` → render "Log in as X to join Y" → after login create membership.
- `user != nil && auth as same` → create membership idempotently, no password form.
- `user != nil && auth as different` → interstitial "You're logged in as B but invite is for A — [Log out and continue as A] / [Cancel]" → logout then login as invite email. Prevents cross-identity hijack.

**3. Idempotency via `UNIQUE(user_id,tenant_id)`.**
`Memberships.create` is upsert-safe; if membership exists, controller just redirects `302 /:slug/app`. Invite `accepted_at` is still set on first accept.

**4. Prerequisite ordering.**
This change is blocked by `workspace-picker-switcher` (needs `memberships` + global email). It adds no migration; it only changes controller/branching and redirect targets.

## Risks / Trade-offs

- **User clicks invite while logged in as wrong account.** → Mitigation: interstitial prevents silent membership for wrong identity; requires explicit logout.
- **Stale invite email case differences.** → Mitigation: all lookups use `lower(email)`.
- **Invite enumeration.** → Mitigation: keep existing token entropy (32 bytes) and 7-day expiry; no extra leak.

## Migration Plan

No migration. Deploy after `workspace-picker-switcher` is applied. Rollback: revert controller to old `build_assoc` path (would reintroduce duplicate rows, so forward-fix preferred).

## Open Questions

- Should `GET /invite/:token` for existing user skip the interstitial and auto-redirect to login with `?invite=token&email=...`?
- Do we email the inviter when invite is accepted by existing vs new identity?
