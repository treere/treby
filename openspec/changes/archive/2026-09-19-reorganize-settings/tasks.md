## 1. Scaffolding

- [x] 1.1 Create settings navigation config module (groups, items, icons, paths, role, test ids) including Message Queue under Communication, consumed by the layout.
- [x] 1.2 Create `TrebyWeb.SettingsLayout` function component (`lib/treby_web/components/settings_layout.ex`) — sticky sidebar + main slot, active state via `aria-current`, responsive collapse below `lg`.

## 2. Top Navigation Rework

- [x] 2.1 Trim `Layouts.app` top nav to 5 primary text links (Jobs, Candidates, Interviews, Analytics, Assistant) — remove Import and Message Queue entries from desktop bar and mobile drawer.
- [x] 2.2 Replace Settings text link with gear icon (`hero-cog-6-tooth`, admin only, `aria-label="Settings"`, active style `bg-zinc-100` / `dark:bg-zinc-800`) next to notification bell; update mobile drawer accordingly.
- [x] 2.3 Collapse scattered header controls into unified user dropdown (avatar/name `▾`) containing identity row (name + role badge), Theme segmented control (System/Light/Dark via existing `phx:set-theme`), Language (EN/IT), and Logout; remove standalone `theme_toggle`/`locale_switcher` from header.

## 3. Import Relocation

- [x] 3.1 Add secondary `Import CSV` button (ghost variant, `hero-arrow-up-tray`) to `CandidatesLive.Index` header beside `Add Candidate`, visible in both populated and empty states; link to `~p"/app/import"` (tenant-aware).

## 4. Hub Rework

- [x] 4.1 Rewrite `SettingsLive.Index` to use `SettingsLayout` — render five groups with headings/icons/subtitles/badges (now including Message Queue under Communication) instead of flat grid; add empty/filtered and non-admin callout states.
- [x] 4.2 Handle role-aware filtering in the hub (admin sees all 15 items, member sees filtered subset; hide empty groups).

## 5. Child Pages Shell

- [x] 5.1 Wrap all child `SettingsLive.*` renders (`Pipeline`, `PipelineStages`, `Branding`, `Team`, `Webhooks`, `Fields`, `Scorecards`, `EmailTemplates`, `Notifications`, `Calendar`, `Availability`, `CompanyAvailability`, `Language`, `AuditLog`, `DataPrivacy`) plus `MessagesQueueLive.Index` with `SettingsLayout` and pass active key.
- [x] 5.2 Keep secondary "Back to Settings" link for a11y, ensure sidebar link `id`s are stable for tests (e.g., `settings-nav-team`, `settings-nav-message-queue`).

## 6. Routing & Access (minimal fix)

- [x] 6.1 Audit `router.ex` admin `live_session` gating vs hub filtering — ensure personal items (Language, Calendar, My Availability) are reachable by non-admins; adjust session split or guard if needed without adding new URLs.

## 7. UX Polish

- [x] 7.1 Add icons per group/item via `<.icon>`, admin badges, and one-line subtitles; verify SaaS minimal tokens in both themes.
- [x] 7.2 (Optional, deferrable) Evaluated filter input & failed-message badge — deferred for 15 items (ponytail: add when list grows or failures need surfacing) — decision documented, no code.

## 8. Tests

- [x] 8.1 Add/adjust LiveView tests for top nav (trimmed links, gear icon, user dropdown, no Import/Queue in nav), Candidates header Import button, hub grouping/active state/role filtering, and deep-link active highlighting (including Message Queue); ensure existing settings/nav tests still pass.
- [x] 8.2 Run `mix test` for affected paths.

## 9. Specs & Docs

- [x] 9.1 Update specs at `openspec/specs/app-navigation/spec.md`, `openspec/specs/csv-import/spec.md`, `openspec/specs/email-scheduler/spec.md`, `openspec/specs/company-availability/spec.md` (and create `openspec/specs/settings-navigation/spec.md`) with Purpose/Requirements and Scenario WHEN/THEN matching the delta specs.
- [x] 9.2 Synced `site/features/*.md` (csv-import, message-scheduler) for new paths; `site/.vitepress/config.ts` unchanged (no new feature page); screenshots require running app — deferred to manual QA before release (ponytail: run `node scripts/screenshots.mjs --axe` to verify light/dark contrast).

## 10. Final Verification

- [x] 10.1 Run `mix precommit` and `openspec validate --strict` and fix issues.
