## Context

`CareersLive.Apply.mount` currently ignores session; it always renders empty `to_form(%{}, as: :application)`. Yet the session map for public LiveViews is still populated (LiveView passes `session` with `candidate_id` if portal login happened in same browser). During Playwright, anonymous and portal-authenticated flows are separate: candidate must retype data for job #2 despite having just created a candidate row. Team noted friction for seekers applying to 3-5 roles.

`CareersLive.Index/Show/GlobalIndex` are public (`pipe_through :browser` only) so they currently have no tenant-scoped candidate check — adding one must not leak cross-tenant applied state and must not require auth.

## Goals / Non-Goals

**Goals:**
- Zero-retype for second+ application in same tenant when portal session exists.
- Visual confirmation of already-applied positions to prevent duplicate effort.
- Keep anonymous path 100% unchanged.

**Non-Goals:**
- Cross-tenant prefill (candidate in tenant A seeing prefill on tenant B careers) — explicitly blocked.
- Bulk-apply ("apply to all") — separate feature.
- Persisting draft applications.

## Decisions

- **Prefill source: session `candidate_id` + `candidate_tenant_id`:** On `Apply.mount`, if `session["candidate_id"]` present and `session["candidate_tenant_id"] == tenant.id`, load candidate and assign `prefill: %{name, email, phone}`; template sets `value={@prefill.name}` via `to_form(%{"name"=>..., "email"=>...})`. Do NOT use `current_candidate` assign from `CandidateAuth` (that plug is not on public pipeline), so manual session read is correct. Alternative: move careers under `candidate_auth` — rejected as it would force login to view jobs.
- **Applied-set lookup:** On `Index/Show/GlobalIndex.mount`, if session has candidate for this tenant, call `Pipeline.list_applications_for_candidate(tenant.id, candidate_id) |> MapSet.new(& &1.job_id)`. Pass as `@applied_job_ids`. Template: `if MapSet.member?(@applied_job_ids, job.id)` → render `Applied ✓` badge (green) and on detail swap CTA. Size is small (candidate rarely has >20 applications), so no pagination needed.
- **CTA swap on detail:** When applied, show secondary button `View status` → `/:tenant_slug/portal` (or portal login if session expired) instead of `Apply Now`. Keeps single primary action, reduces duplicate clicks. Alternative disabled button — rejected as less helpful (candidate wants to check status).
- **Global board (`/careers`):** Only show badge if candidate's tenant matches `job.tenant_id` for that card; otherwise ignore (candidate from tenant A shouldn't see badge on tenant B job even if by coincidence UUID collides — but job ids are UUIDs, safe; still filter by tenant).
- **No JS:** Pure server assigns; no hook needed.

## Risks / Trade-offs

- [Risk] Session fixation — prefill shows email that candidate might not want prefilled on shared device → Mitigation: prefill is read-only hint but still editable; candidate can clear. No auto-submit.
- [Risk] Cache — public career pages are not cached CDN-side; per-session badge means no shared cache; acceptable for low traffic. If cached later, use `Vary: Cookie`.
- [Risk] Tenant mismatch — candidate from tenant A visiting `/other/careers` would not get prefill (tenant check fails) — correct, no leak.

## Migration Plan

- No migration. Deploy LiveView template changes. Rollback = revert 4 files.
- Playwright verification: login via OTP, visit careers, assert badge/prefill.

## Open Questions

- Should prefill also include `linkedin_url` / custom fields? For v1, only name/email/phone; custom fields remain per-job.
- Should we show count `Applied to 2 positions — 1 remaining`? Could add but not required for v1.
