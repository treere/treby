## 1. Raise inline-link and right-group breakpoints

- [x] In `lib/treby_web/components/layouts.ex` (`app/1`): change the inline links group from `hidden sm:ml-6 sm:flex sm:space-x-8` to `hidden xl:ml-6 xl:flex xl:space-x-6` (spacing tightened so inline nav fits at 1280px), and the right group from `hidden sm:flex sm:items-center sm:space-x-4` to `hidden xl:flex xl:items-center xl:space-x-4`.

## 2. Keep notification bell always visible

- [x] Move `<.notification_bell>` out of the right group so it renders at every width (remove it from the `xl:flex` wrapper; keep it as a standalone element in the nav bar right area).

## 3. Integrate hamburger into the nav bar

- [x] Remove the standalone `fixed top-4 left-4 z-50` hamburger button rendered after `</nav>`. Add an inline `xl:hidden` hamburger button as the first child of the nav left group, reusing the existing `Phoenix.LiveView.JS.toggle_class` toggle targeting `#mobile-nav-overlay` and `#mobile-nav-drawer`.

## 4. Extend drawer + overlay to xl

- [x] Change the mobile drawer and backdrop overlay from `sm:hidden` to `xl:hidden` so they appear below 1280px.

## 5. Close drawer on link tap

- [x] Add the `JS.toggle_class` close handler as `phx-click` to every drawer nav link (`.mobile-nav-link`) and the drawer Settings link, so the drawer closes while `navigate` still routes.

## 6. Tests for responsive nav

- [x] Add `test/treby_web/components/layouts_app_test.exs` asserting: hamburger button has `xl:hidden`, inline links group has `xl:flex`, right group has `xl:flex`, drawer contains all 8 links, and drawer links carry the close-on-tap `phx-click`. Playwright confirmed no horizontal overflow at 800/1024/1280px and that the drawer opens on hamburger and closes on link tap.

## 7. Update specs

- [x] Update `openspec/specs/mobile-navigation/spec.md` and `openspec/specs/app-navigation/spec.md` with the new `xl` breakpoint (MODIFIED requirements + WHEN/THEN scenarios). Add the delta specs under `openspec/changes/responsive-nav-drawer/specs/`.

## 8. Screenshots + docs (nav)

- [x] Run `node scripts/screenshots.mjs` to refresh screenshots (light + dark, desktop + tablet + mobile). Confirmed no horizontal scroll at 800px / 1024px widths.

## 9. Make shared table component scrollable

- [x] In `lib/treby_web/components/core_components.ex`, change the `<.table>` card from `overflow-hidden` to `overflow-x-auto` so all component-based tables scroll within their card (single change covers every usage).

## 10. Card-wrapped raw tables scroll

- [x] Change `overflow-hidden` → `overflow-x-auto` on the table cards in `fields`, `scorecards`, `availability`, `email_templates`, `pipeline_stages`, `candidates_live/index`, `jobs_live/index`, and both `team` tables.

## 11. Wrap bare tables

- [x] Wrap the bare tables in `messages_queue_live/index.html.heex` and `settings_live/webhooks.ex` (subscriptions card + expanded logs block) in an `overflow-x-auto` container.

## 12. Tests for table responsiveness

- [x] Extend `test/treby_web/components/layouts_app_test.exs` with a test asserting the candidates table card uses `overflow-x-auto` and contains a `<table>`.

## 13. Screenshots + docs (tables)

- [x] Re-run `node scripts/screenshots.mjs` so regenerated screenshots reflect scrollable tables (light + dark).

## 14. Final verification

- [x] Run `mix precommit` and `openspec validate --strict`, fix any issues.
