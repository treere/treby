## 1. Routing and scaffolding

- [x] 1.1 Add `live "/jobs/new", JobsLive.New` before `live "/jobs/:id"` in `lib/treby_web/router.ex` for both `/:tenant_slug/app` and `/app` scopes; verify `~p"/app/jobs/new"` does not match `id="new"` by running `mix test` router helper check
- [x] 1.2 Create `lib/treby_web/live/jobs_live/new.ex` LiveView skeleton with mount that resolves `current_user`/`current_tenant` (same as `JobsLive.Index`), assigns pipelines, custom fields, default status `open` and visible `true`, and initializes `form` via `to_form(Jobs.change_job(%Job{status: "open", visible: true, pipeline_id: default}))` plus `@preview_job` derived struct

## 2. Creation page UI

- [x] 2.1 Build split-layout template in `JobsLive.New` render: left column form (fields + publication controls), right column live preview card; wrap with `<Layouts.app flash={@flash} current_scope={@current_user} locale={@locale}>`, use `TrebyWeb.DesignSystem` tokens (`zinc-50/white`, `rounded-xl`, `shadow-sm`, `orange-600` CTA), add unique DOM IDs (`job-create-form`, `job-preview-card`)
- [x] 2.2 Implement form fields: title, description textarea with Markdown hint, salary_range, location, employment_type select, workplace_type select, pipeline select (tenant-scoped, default preselected), custom job fields section, status select (`open`/`closed`), visibility select/toggle (`Public`/`Private` bound to `visible`), with visibility disabled + helper text when `status == "closed"`, all via `<.input>`, `phx-change="validate"` and `phx-submit="save"`
- [x] 2.3 Implement live preview derivation: `handle_event("validate", %{"job" => params})` builds changeset and assigns `@preview_job` via `Ecto.Changeset.apply_changes` (fallback to changeset errors for invalid input); preview markup reuses `.markdown`, `Job.employment_type_label/1`, `Job.workplace_type_label/1`, salary/location badges, posted-date fallback, and mirrors empty-field hiding from `CareersLive.Show`
- [x] 2.4 Ensure theme correctness: explicit `dark:` classes on preview card (`dark:bg-zinc-800`, `dark:text-zinc-100`, `dark:text-zinc-400`), and add fallback `[data-theme="dark"]` + `@media (prefers-color-scheme: dark)` in `assets/css/app.css` if raw CSS is added; verify with `node scripts/screenshots.mjs --axe` no `color-contrast` violations
- [x] 2.5 Implement save/cancel handling: `handle_event("save", %{"job" => params, "custom_fields" => cf})` validates required custom fields, merges `tenant_id` from session (ignore client-supplied), coerces `visible` to `false` when `status == "closed"`, calls `Jobs.create_job/1`, on success `push_navigate` to `~p"/app/jobs/#{job.id}"` with `put_flash(:info, "Job created successfully")`, on error re-assign form with changeset and flash error; Cancel is `<.link navigate={~p"/app/jobs"}>` button

## 3. Listing cleanup

- [x] 3.1 Update `lib/treby_web/live/jobs_live/index.ex`: replace "New Job" button action from `phx-click="show_create_form"` to `<.link navigate={~p"/app/jobs/new"}>`, remove inline creation template block (`:if={@show_form}`), remove assigns `show_form`/`form` for creation, and remove events `show_create_form`/`hide_create_form`/`create_job`; keep filter/pagination and `toggle_status`/`toggle_visibility` table actions
- [x] 3.2 Verify no dead references: grep for `show_create_form`, `hide_create_form`, `show_form` in jobs live tests and templates; ensure `JobsLive.Show` edit flow unchanged

## 4. Tests

- [x] 4.1 Update `test/treby_web/live/jobs_live_test.exs` (or create `test/treby_web/live/jobs_live/new_test.exs`): assert listing has no `#job-form`, "New Job" navigates to `/app/jobs/new`, creation page renders form and preview, `validate` updates preview without DB write, create with `status=open`+`visible=true` appears on public boards, `open`+`private` hidden from listing but reachable via direct link, `closed`+`visible=true` fails validation, visibility control disabled when closed, tenant isolation for pipelines/fields
- [x] 4.2 Add LiveView integration assertions for light/dark rendering (if feasible) and for redirect-after-create to job detail; run `mix test test/treby_web/live/jobs_live*` and ensure green

## 5. Specs and docs

- [x] 5.1 Sync specs at archive time: create `openspec/specs/job-creation-preview/spec.md` (Purpose + Requirements from `specs/job-creation-preview/spec.md` delta) and apply delta to `openspec/specs/job-management/spec.md` (updated "Create job posting" requirement) with `## MODIFIED` content
- [x] 5.2 Update user manual: edit `site/features/*.md` jobs page (English-only, UI paths like `Jobs → New Job`, explain split form/preview, Status Open/Closed and Visibility Public/Private, Markdown hint), update `site/features/index.md` and `site/.vitepress/config.ts` sidebar if new entry, run `cd site && npm run build`, regenerate screenshots via `node scripts/screenshots.mjs` and `node scripts/screenshots.mjs --axe`

## 6. Final verification

- [x] 6.1 Run `mix precommit` and `openspec validate --strict` and fix all issues (format, credo, tests, contrast)
