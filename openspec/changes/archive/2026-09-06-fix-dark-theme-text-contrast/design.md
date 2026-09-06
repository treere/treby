## Context

Treby ships a system/light/dark theme via `data-theme` + `prefers-color-scheme` with ~953 `dark:` usages. The design system mandates zinc neutrals (`zinc-50`/`white`/`zinc-200` light; `zinc-900`/`zinc-800`/`zinc-700` dark) and bans `bg-blue-600`/`bg-gray-*`/`btn btn-primary` outside `design_system/*`. The existing dark-mode spec requires "all text readable" but does not pin contrast ratios and `node scripts/screenshots.mjs --axe` is opt-in/not enforced in CI.

In practice several pairings fail WCAG AA in dark mode: muted copy using `text-zinc-400 dark:text-zinc-500` gets *darker* on dark surfaces; `TrebyWeb.DesignSystem` helpers `variant_classes("secondary"/"ghost"/"outline")` and `badge_classes/1` return only light values (e.g., `bg-white text-zinc-900`, `bg-zinc-100 text-zinc-700`, `bg-amber-50 text-amber-700`) so they render low-contrast on `zinc-800` cards; placeholders (`placeholder:text-zinc-400`) and some table/card muted text lack a distinct dark legible value; headings without any `dark:text-*` (e.g., `text-lg font-semibold` alone) inherit low contrast on dark cards; and `text-primary` links (e.g., "Forgot your password?" on `/login`) have no `dark:` override. Users report unreadable text on dark theme — exemplars `/careers` search input (raw `class="input"` without `dark:` placeholder/text), the "← Back to all positions" link + description on `/:tenant_slug/careers/:job_id` (e.g., `/acme/careers/8dec86b3-7584-47f0-b9f6-7af6625a55da`, also showing an English/Italian mix when locale is IT in dark mode because strings are hardcoded outside `gettext`), the "Forgot your password?" link on `/login`, and section titles on `/:tenant_slug/app` dashboard ("Le mie azioni" / "My Actions", "Upcoming Interviews", "Stale Candidates", etc.) that disappear in dark mode.

Stakeholders: end users (readability, navigation), developers (single source of truth in `DesignSystem`), CI (guardrail without flakiness).

## Goals / Non-Goals

**Goals:**
- Every text/background pairing in dark mode meets WCAG AA (4.5:1 normal, 3:1 large) on its actual surface (`zinc-800` card, `zinc-900` page, `zinc-700` borders).
- Centralize fixes in `DesignSystem` helpers and shared tokens so per-page patches are minimal and future regressions are preventable.
- Make the fix verifiable locally and in CI via `axe-core` `color-contrast` with zero serious/critical violations.

**Non-Goals:**
- Redesigning the palette or introducing new semantic color scales beyond correcting dark overrides.
- Changing light-theme appearance.
- Adding new dependencies or DB migrations.
- Full WCAG AAA or automated per-pixel contrast scanning beyond axe.

## Decisions

**D1 — Fix at the helper level + sweep for inline muted text + naked headings**
- *Choice:* Add `dark:` overrides inside `variant_classes/1` and `badge_classes/1` (e.g., `secondary` → `dark:bg-zinc-800 dark:text-zinc-100 dark:border-zinc-700`), then sweep `lib/treby_web` for the remaining inline patterns (`text-zinc-400 dark:text-zinc-500`, bare `text-zinc-500` without dark, `placeholder:text-zinc-400` without dark placeholder, `text-primary` links without `dark:text-*`, and headings with `text-lg font-semibold` but no `dark:text-zinc-100` inside `bg-white dark:bg-zinc-800` cards).
- *Alternative considered:* Fix each call site individually — rejected: leaves helper consumers broken and is error-prone.
- *Alternative considered:* CSS-variable abstraction for every text shade — rejected: over-engineering for a bounded contrast fix; Tailwind `dark:` is sufficient and already the project convention.

**D2 — Canonical muted-text mapping**
- *Choice:* Normal muted copy SHALL be `text-zinc-500 dark:text-zinc-400` (or `text-zinc-600 dark:text-zinc-400` for stronger contrast). The inverted `text-zinc-400 dark:text-zinc-500` is treated as a bug and auto-flagged. On dark cards (`dark:bg-zinc-800`) the floor is `dark:text-zinc-400`; `dark:text-zinc-500` is only allowed on `zinc-900` with large text.
- *Rationale:* `zinc-400` (#a1a1aa) on `zinc-800` (#27272a) is ~5.1:1; `zinc-500` on same is ~3.3:1 (fails for small text). Using `dark:text-zinc-400` restores legibility.
- *Placeholder:* Keep `placeholder:text-zinc-400` in light but enforce `dark:placeholder:text-zinc-500` or `dark:placeholder:text-zinc-400` with `dark:bg-zinc-800` so placeholder is not lighter than body muted text.

**D3 — Badge dark overrides keep light badges but adjust text/border**
- *Choice:* Preserve the current light badge fills (e.g., `bg-amber-50`) but add `dark:` text/border (e.g., `dark:bg-amber-950 dark:text-amber-200 dark:border-amber-800`) mirroring the `Feedback.toast` pattern already proven. `default` badge maps to `dark:bg-zinc-700 dark:text-zinc-200 dark:border-zinc-600`.
- *Alternative:* Invert to dark fills entirely — rejected: would be a visual redesign; the toast precedent is accepted and axe-clean.

**D4 — Verification via axe `color-contrast` (opt-in locally, gate in CI)**
- *Choice:* Require `node scripts/screenshots.mjs --axe` to report zero serious/critical `color-contrast` violations when capturing both themes. The script already supports `AxeBuilder` + `dark` capture; we add a focused `color-contrast` assertion and document the command in AGENTS guardrail line.
- *Alternative:* Unit-test every class string — rejected: brittle; axe checks rendered contrast including computed backgrounds.

**D5 — i18n: wrap hardcoded careers strings with gettext**
- *Choice:* Replace hardcoded `"Back to all positions"` / `"View other positions"` (and any remaining English literals on `CareersLive.Show` closed/not-found states) with `gettext("Back to all positions")` etc., run `mix gettext.extract --merge`, and add Italian `msgstr` ("Torna a tutte le posizioni", "Vedi altre posizioni", etc.). Theme switching stays orthogonal to locale — `Gettext.put_locale` is independent of `data-theme`.
- *Alternative:* Conditional rendering by theme — rejected; language mix is a missing `gettext` bug, not a theming bug. Fixing at the source removes the mix in all themes.

**D6 — Auth link and dashboard heading contrast**
- *Choice:* For `/login` "Forgot your password?" (and other `text-primary` auth links on `bg-zinc-50 dark:bg-zinc-800`), add `dark:text-orange-300` or `dark:text-zinc-300` hover override so contrast is ≥4.5:1 in dark mode. For `DashboardLive` at `/:tenant_slug/app`, add `text-zinc-900 dark:text-zinc-100` to all naked `text-lg font-semibold` headings ("My Actions"/"Le mie azioni", "Upcoming Interviews", "Stale Candidates", "Pipeline Overview", "Recent Activity") and fix inverted `text-zinc-400 dark:text-zinc-500` stats/action metadata to canonical `text-zinc-500 dark:text-zinc-400` with visible muted copy.
- *Alternative:* Rely on parent `text-zinc-900` inheritance — rejected: headings sit inside `bg-white dark:bg-zinc-800` cards with no explicit `dark:text`, so they render low-contrast without override.

**D7 — Public pages missing theme/language/homepage link**
- *Choice:* Reuse the existing `Layouts.auth_toolbar` pattern (theme toggle + locale switcher) plus a homepage brand link (`<.link navigate={~p"/"}>Treby</>`) for unauthenticated/tenant-public pages that currently have no header: `/reset-password` (add Treby logo top-left alongside existing `auth_toolbar` top-right), and each careers LiveView (`GlobalIndex` at `/careers`, `Index` at `/:tenant_slug/careers`, `Show` at `/:tenant_slug/careers/:job_id`, `Apply` at `/:tenant_slug/careers/:job_id/apply`). Implement as a shared `TrebyWeb.Layouts.public_header` component that renders a fixed/absolute top bar with `bg-white/80 dark:bg-zinc-900/80` + border, containing homepage link left and theme+locale right, so dark-mode toggle and language switch are reachable without being logged in and users can navigate home. Careers pages already call `set_locale_from_session`; keep that and pass `@locale`/`@current_tenant` as needed.
- *Alternative:* Duplicate raw HTML in each careers template — rejected: diverges from `auth_toolbar` and `app` nav patterns; shared component keeps the guardrail.
- *Alternative:* Only patch careers, ignore password — rejected: user explicitly flagged password pages as missing homepage/theme/language.

## Risks / Trade-offs

- [Risk] Sweep misses dynamic/class-list compositions (`[@flag && "text-zinc-400"]`) → Mitigation: grep for `text-zinc-` and manual review of ~437 `text-zinc-400` hits; add a CI grep that fails on `text-zinc-400 dark:text-zinc-500` and on bare `variant_classes` call sites without `dark:`.
- [Risk] Dark badge fills change visual weight → Mitigation: use the same `*-950`/`*-200` scale already used by `toast`; verify via screenshots in both themes before merge.
- [Risk] Placeholder too faint after fix on dark inputs → Mitigation: validate inputs in dark modal/card surfaces; floor at `dark:placeholder:text-zinc-500`.
- [Risk] Light theme regression → Mitigation: no light classes changed except adding `dark:` prefixes; screenshot diff (`node scripts/screenshots.mjs`) before/after.

## Migration Plan

1. Update `DesignSystem.variant_classes/1` and `badge_classes/1` with `dark:` overrides.
2. Sweep inline muted/placeholder text and naked headings in `core_components.ex`, `design_system/*`, `layouts.ex`, `live/**/*`, `controllers/**/*` — with priority on `CareersLive.GlobalIndex`/`Index` search input, `CareersLive.Show` back link + description + closed/not-found states, `SessionHTML` `/login` "Forgot your password?" link and its sibling `text-primary` auth links, and `DashboardLive` headings at `/:tenant_slug/app`.
3. Add public header (homepage link + theme + language) to missing public pages: introduce `Layouts.public_header` and use it in `CareersLive.GlobalIndex`/`Index`/`Show`/`Apply` and add homepage logo to `PasswordResetHTML` pages alongside existing `auth_toolbar`.
4. Wrap hardcoded careers strings with `gettext`, run `mix gettext.extract --merge`, fill `priv/gettext/it/LC_MESSAGES/default.po`, and verify `mix treby.check_translations` passes.
5. Run `mix precommit` (compile + format + tests) and `node scripts/screenshots.mjs --axe` locally in light + dark (IT locale on `/acme/careers/:id` and `/:tenant_slug/app` with `Le mie azioni` included, plus careers/password public pages); fix any remaining `color-contrast` violations.
6. Deploy — no migration, no config change. Rollback is reverting the class strings + header + gettext wrap; no data impact.
7. Update docs/screenshots if needed (no user-facing config change, so no `site/` page update required beyond guardrail note in `AGENTS.md`).

## Open Questions

- Should the CI gate run `screenshots.mjs --axe` on every PR or only on `design_system`/`assets/css` changes? (Proposal: gate on `lib/treby_web/**` + `assets/**` via workflow condition to limit cost.)
- Floor shade for disabled/secondary muted text on `zinc-900` page background — confirm `dark:text-zinc-400` vs `dark:text-zinc-300` for 4.5:1 on `zinc-900` (axe will adjudicate).
