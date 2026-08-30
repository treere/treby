## 1. Guard scorecard path

- [x] 1.1 In `lib/treby_web/live/pipeline_live/index.ex` `handle_event "open_scorecard"`, add guard for `get_active_template == nil` → `put_flash(:error, "No scorecard template configured — create one in Settings → Scorecards")` and return without assigning `show_scorecard_form`
- [x] 1.2 In the same LiveView's card render, disable the `Scorecard` button when `get_active_template == nil` (or cached assign) with tooltip `No template — Settings → Scorecards`
- [x] 1.3 In `lib/treby/tenants/tenants.ex` `create_tenant` after `create_default_pipeline_stages`, seed a default `ScorecardTemplate` (`name: Default, criteria: [%{name: "Overall", type: "number_1_5"}]`) if none exists

## 2. Tests

- [x] 2.1 Add regression test in `test/treby_web/live/pipeline_live_test.exs`: with no template, `render_click("open_scorecard", %{"event_id" => event.id})` asserts `flash` contains `No scorecard template` and no crash
- [x] 2.2 Run `mix test test/treby_web/live/pipeline_live_test.exs` and `mix precommit`

## 3. Verification

- [x] 3.1 Playwright smoke: fresh `Friction Co 86` candidate in Interview with examiner, click `Scorecard` with no template → shows guidance flash and no `BadMapError`; after creating template via `Settings → Scorecards`, `Scorecard` opens
