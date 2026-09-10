## Context

Today job creation is embedded in the listing LiveView (`TrebyWeb.JobsLive.Index`). Clicking "New Job" toggles an inline form (`@show_form`) that shares the listing's assigns and reuses `handle_event("create_job")`. The form captures title, description (Markdown hint), salary, location, employment/workplace types, pipeline, and custom fields, but offers no sense of the candidate-facing result. Publication state (`status` open/closed, `visible` public/private) is managed only after creation through table toggles (`toggle_status`, `toggle_visibility`), which is undiscoverable at creation time and splits a single editorial decision across two screens.

Public rendering lives separately in `TrebyWeb.CareersLive.Show` / `GlobalIndex` (card + detail): title, company block, location, employment/workplace badges, salary, Markdown description via `.markdown`, posted date, and apply CTA. The design goal is to bring that rendering forward as a live preview while promoting status/visibility to first-class creation controls, without introducing new persistence or external services.

Constraints: multi-tenant isolation (`tenant_id` on every job), existing validation `validate_visible_requires_open` (cannot be visible when closed), tenant-scoped pipelines and custom fields, LiveView conventions (`<Layouts.app>`, `to_form/2`, `phx-update="stream"`), Tailwind/DesignSystem tokens and mandatory light+dark theme coverage, and user-manual docs under `site/`.

Stakeholders: recruiters/admins creating jobs; candidates seeing public pages unchanged.

## Goals / Non-Goals

**Goals:**
- Provide a dedicated creation page at `/app/jobs/new` (and `/:tenant_slug/app/jobs/new`) that replaces the inline listing form.
- Show a live, faithful preview of the public job card/detail side-by-side with the form, updating on validated changes without persisting.
- Make job activity and discoverability editable at creation: `status` (Open/Closed) and `visible` (Public/Private) with correct defaults, validation, and disabled states.
- Keep all existing fields and behaviors (pipeline default, custom fields, Markdown, structured metadata).
- Preserve tenant isolation and reuse existing `Treby.Jobs.create_job/1` and changeset validation.

**Non-Goals:**
- No preview for edit (edit stays on `JobsLive.Show` as-is); no WYSIWYG Markdown toolbar.
- No new job lifecycle states beyond `open`/`closed` and `visible` boolean.
- No schema migration, no new DB columns, no external preview service or iframe isolation.
- No change to public career page routing, SEO, or view-tracking behavior.
- No automation (auto-publish, scheduling) — explicit user choice only.

## Decisions

### Decision 1: Dedicated `TrebyWeb.JobsLive.New` LiveView, remove inline creation from `JobsLive.Index`

Separate page owns its changeset, preview derivation, and navigation. Listing's "New Job" becomes `<.link navigate>` to `/app/jobs/new`; inline assigns `show_form`, `form` for creation, and `handle_event("create_job")` are removed from `Index` (edit-related events stay on `Show`). This isolates concerns and avoids conditional rendering that complicates the listing.

*Alternative considered:* keep inline form and add modal preview — rejected because it keeps listing and creation coupled, limits layout (no split view), and competes with pagination/filter state.

### Decision 2: Route `/jobs/new` before `/jobs/:id` in both scopes

Phoenix matches `/:id` greedily; placing `live "/jobs/new", JobsLive.New` before `live "/jobs/:id", JobsLive.Show` in both the slug-scoped `/:tenant_slug/app` block and the legacy `/app` block prevents `id="new"` mismatches. Both scopes remain to preserve backward compatibility with existing links/tests.

*Alternative considered:* use query param `?new=true` — rejected as URL is less shareable and pollutes listing params.

### Decision 3: Live preview derived from validated changeset, not persisted

`handle_event("validate", %{"job" => params})` builds a changeset via `Jobs.change_job(%Job{}, params)` (or `apply_changes` for preview struct) and assigns derived `@preview_job` and `@preview_changeset`. The right pane reuses the same markup as `CareersLive.Show` (`.markdown`, `employment_type_label`, `workplace_type_label`, salary, date fallback to today) so preview fidelity is high without writing to DB or duplicating render logic. On `save`, real persistence via `Jobs.create_job` runs; validation errors are shown on the form while preview reflects last valid input.

*Alternative considered:* persist draft job with `status=draft` — rejected: introduces new state, migration, and public filtering complexity for little gain.

### Decision 4: Publication controls exposed as explicit selects/toggles on the creation form

Default `status="open"` and `visible=true`. UI offers two fields: `Status` select `["open", "closed"]` (or segmented Open/Closed) and `Visibility` toggle `Public/Private` bound to `visible`. When `status == "closed"`, visibility input is disabled with helper text "Private jobs cannot be visible when closed" and forced to `false` server-side; `validate_visible_requires_open` remains the source of truth and surfaces the error on `visible`.

*Alternative considered:* single "Publish" checkbox — rejected because status and visibility are orthogonal axes already in the domain (closed jobs are hidden regardless; private open jobs are hidden from listings but reachable via direct link).

### Decision 5: Reuse existing public rendering components for preview

Preview card imports `.markdown` sanitization, `.badge`, and icons exactly as `CareersLive.Show` does, wrapped in a `bg-white dark:bg-zinc-800` card with `data-theme`-aware text colors (explicit `dark:` classes, fallback `@media (prefers-color-scheme: dark)` pattern per `assets/css/app.css`). Empty fields are hidden (e.g., no location row if blank) to mirror real conditional rendering; pipeline and custom fields are shown only in form, not preview, since public page does not expose them.

*Alternative considered:* iframe of real public route — rejected due to auth/session coupling and extra request.

### Decision 6: Multi-tenant isolation and authorization unchanged

`New` mounts the same way `Index` does: resolves `current_user`/`current_tenant` from `socket.assigns` or session + `RequireMembership` hook; pipelines/custom fields are listed scoped to `tenant.id`; creation attrs always include `tenant_id`. Candidate recovery/plug not involved. Existing `on_mount` hooks (`SetLocale`, `RequireMembership`, optional `RequireRole`) are reused; no new role is introduced (any team member who could create via inline can create via page; if admin-only is desired later, `RequireRole` can be added without changing this design).

### Decision 7: Error handling and caching strategy

No caching. Validation errors are inline via `to_form(changeset)` as elsewhere. On save failure, flash `error` and keep preview as-is. Persistence failure is rare; form stays populated. Public preview never blocks save. View tracking and public boards are unaffected.

## Risks / Trade-offs

- **Route ordering regression** (`/jobs/new` vs `/jobs/:id`) → Mitigation: declare `/jobs/new` before `/:id` in router and add a test asserting `~p"/app/jobs/new"` does not route to `Show`. Cover both scopes.
- **Preview drift from real public page** if public markup evolves → Mitigation: extract or duplicate minimal shared partial under `TrebyWeb.JobsLive.Preview` or reuse helpers (`employment_type_label`, `.markdown`) and add a visual regression note in design review; docs update reminds to regenerate screenshots.
- **Listing tests break after removing inline form** → Mitigation: update `JobsLive.Index` tests to assert navigation instead of `has_element?("#job-form")` on `/app/jobs`; add dedicated `JobsLive.New` tests for validate/save/visibility-disabled-when-closed.
- **Theme contrast regressions in preview card** → Mitigation: follow DesignSystem tokens (`zinc-50/white/zinc-200` light, `zinc-900/800/700` dark, `rounded-xl/shadow-sm`, `orange-600` CTA), add explicit `dark:text-*` and `prefers-color-scheme` fallback, run `node scripts/screenshots.mjs --axe`.
- **Form state loss on browser back** if user cancels after typing → Mitigation: client-side `beforeunload` is out of scope; server keeps changeset only for LiveView lifetime which is standard.

## Migration Plan

- **Code**: Add `lib/treby_web/live/jobs_live/new.ex`, update `lib/treby_web/router.ex`, trim `lib/treby_web/live/jobs_live/index.ex` (remove creation form template and events). No migration.
- **Deploy**: Additive then subtractive — new route can ship with listing still supporting old events behind flag, then remove inline form second commit. No DB change, no feature flag required.
- **Rollback**: Delete the `New` LiveView and route, restore `Index` inline form from git; public pages unaffected.
- **Docs**: Update `site/features/*.md` job page (English-only, UI menu paths) and sidebar, run `cd site && npm run build`, regenerate screenshots.

## Open Questions

- Should the creation page also allow immediate "View public link" after save via a post-create modal, or is redirect to detail with "Copy Public Link" sufficient? (Propose redirect to detail.)
- Should preview use the global header (`Layouts.public_header`) or just the card? (Propose card only to keep split view compact; header is static.)
- Do we need an admin-only gate for publishing (`visible=true`) in tenants with approval flow? Deferred — keep same permission as today.
