## Context

Candidate portal is isolated by `CandidateAuth` plug (session `candidate_id` + expiry) and per-mount loads `tenant` from URL slug and `candidate` from DB. During exploration we saw:
- `Index.handle_event "select_application"` does `Pipeline.get_application!(id)` with no owner check, then loads conversations scoped by `tenant_id`. A malicious candidate guessing UUIDs could learn if an application exists and its job title/status.
- `Index.mount` and siblings do `tenant = Tenants.get_tenant_by_slug!(slug)` then `candidate = Repo.get!(Candidate, candidate_id)` and `applications = list_applications_for_candidate(tenant_id, candidate_id)` where `tenant_id` comes from session (`candidate_tenant_id`), not URL tenant. So URL slug can be any tenant while data stays scoped — no data leak but brand spoof and weak guarantee.
- `Apply` sets `is_duplicate` (`pipeline.ex:810`) but UI always shows `submitted: true` thank-you, hiding duplicate state from candidate.

Multi-tenant invariant: every query MUST be scoped by `tenant_id`; every access MUST verify ownership.

## Goals / Non-Goals

**Goals:**
- Close IDOR on application detail.
- Enforce slug == candidate tenant invariant (redirect or 404).
- Make duplicate state visible to candidate without leaking internal flag semantics.

**Non-Goals:**
- Rate-limiting OTP / brute-force — separate change.
- Changing candidate merge or pipeline move logic.
- Encrypting application IDs (UUIDs already unguessable; defense in depth via authz).

## Decisions

- **Ownership check helper `get_application_for_candidate!(tenant_id, candidate_id, id)`:** Add query `where tenant_id==^tenant_id and candidate_id==^candidate_id and id==^id`. Use `Repo.one!` with rescue to redirect to 404 or show flash. Alternative: check after fetch — rejected as TOCTOU-prone if later code preloads associations before check.
- **Tenant consistency:** In `CandidateAuth.call/2`, after loading `candidate`, also load `slug_tenant = Tenants.get_tenant_by_slug(slug)` (if slug present) and compare `candidate.tenant_id != slug_tenant.id` → `redirect to "/#{candidate_tenant.slug}/portal/login"` with flash `Wrong workspace`. In LiveView mounts, additionally guard: if `socket.assigns.current_tenant.id != candidate.tenant_id`, reassign `current_tenant` to real tenant or redirect. Keep `current_tenant` as candidate's real tenant for all downstream queries — URL slug becomes cosmetic but validated.
- **Duplicate feedback:** In `Apply.handle_event`, before `create_application`, check `Repo.exists?(where Application, candidate_id==^candidate.id and job_id==^job.id)`. If true, fetch existing `applied_at`, set `assign(socket, duplicate: true, existing_applied_at: ...)` and render distinct state: message "You already applied on {date}" + portal link + "View other positions". Still do not create second row OR keep `is_duplicate` row but tell user? Decision: **do not create duplicate row** when detected pre-insert (avoid is_duplicate spam); return early with duplicate UI. If team wants to keep duplicates for analytics, alternative is to create but show duplicate badge — deferred, document as option.
- **Auditing:** Grep all `CandidatePortal` and `Pipeline` portal queries to ensure `where tenant_id == ^tenant_id` present; add `mix credo` check if needed.

## Risks / Trade-offs

- [Risk] Legit candidate visits old bookmark with wrong slug after tenant rename → redirect loop → Mitigation: use candidate's current tenant slug, single redirect.
- [Risk] Changing `select_application` to tenant-scoped `get!` raises on not-found vs silent nil → UX is 404/flash, acceptable; log warning with `Logger.warning`.
- [Risk] Duplicate check race (double-click) → Mitigation: DB unique index `(candidate_id, job_id)` not present; keep `is_duplicate` fallback; duplicate check is best-effort UX, DB still handles concurrent inserts via existing flag.

## Migration Plan

- No DB migration. Code-only deploy. Rollback = revert 3 files.
- Verify with new tests: `test/treby_web/live/candidate_portal_live/security_test.exs` (IDOR, tenant mismatch, duplicate).

## Open Questions

- Should duplicate detection block creation or allow it with visible "duplicate" badge? Product choice — proposal opts for block to avoid confusion; can be toggled via feature flag.
- Should portal URLs be slug-free (`/portal` with tenant inferred from session) to eliminate mismatch class? Deferred — would break bookmarking but simplifies.
