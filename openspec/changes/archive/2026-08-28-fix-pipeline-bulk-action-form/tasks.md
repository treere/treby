## 1. Fix pipeline bulk action bar form

- [x] 1.1 Wrap the pipeline board bulk action bar controls (stage `<select phx-change>` + move button) in a `<.form>` with `phx-change` / `phx-submit` wiring (`pipeline_live/index.ex`)
- [x] 1.2 Confirm the "Move to Stage" dropdown populates and no "form events require the input to be inside a form" error appears

## 2. Fix same pattern elsewhere

- [x] 2.1 Wrap the interviews filter instructor `<select phx-change>` in a form (`interviews_live/index.ex:207-221`)
- [x] 2.2 Wrap the import page pipeline `<select>` in a form (`import_live/index.ex`)

## 3. Verify

- [x] 3.1 Add a test: bulk move from the action bar moves selected applications to the chosen stage
- [x] 3.2 Run `mix precommit` and fix any pending issues