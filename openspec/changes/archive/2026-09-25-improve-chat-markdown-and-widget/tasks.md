## 1. Markdown renderer

- [x] 1.1 In `lib/treby_web/markdown.ex`, pass `extension: [table: true]` to `MDEx.to_html!/2` so GFM tables parse
- [x] 1.2 In `lib/treby_web/markdown_scrubber.ex`, allow `table`, `thead`, `tbody`, `tr`, `th`, `td` with no attributes
- [x] 1.3 Update the `TrebyWeb.Markdown` moduledoc to mention tables/GFM; verify `mix test test/treby_web/markdown_test.exs` after adding tests in group 4

## 2. Table styling

- [x] 2.1 Verify `.md-content` table rules in `assets/css/app.css` render correctly inside the chat bubble in light and dark themes; adjust overflow/margins if the bubble clips the table
- [x] 2.2 Smoke-check both themes with `data-theme="light"` and `data-theme="dark"` (tables, borders, header background)

## 3. Floating widget geometry

- [x] 3.1 In `assets/js/hooks/ai_chat.js`, add an `AiChatGeometry` hook: read/apply `localStorage["treby-ai-chat-geometry"]`, drag on `[data-ai-chat-drag]`, resize on `[data-ai-chat-resize]`, clamp to viewport, re-clamp on `window.resize`
- [x] 3.2 Register `AiChatGeometry` in `assets/js/app.js`
- [x] 3.3 In `lib/treby_web/components/ai_chat_widget.ex`, add `phx-hook="AiChatGeometry"` plus `data-ai-chat-drag` header region and `data-ai-chat-resize` grip to the floating panel only (`@variant == :floating`); add unique DOM IDs
- [x] 3.4 Ensure the dedicated page variant (`@variant == :page`) renders no drag/resize affordances
- [x] 3.5 Confirm geometry survives LiveView re-renders (streaming/message reload) and open/close toggle

## 4. Tests

- [x] 4.1 In `test/treby_web/markdown_test.exs`, add a test asserting a GFM table renders `<table>`/`<thead>`/`<th>`/`<tbody>`/`<td>` with no attributes
- [x] 4.2 Add a test asserting table markup is kept while `<script>` and `javascript:` URLs are still stripped
- [x] 4.3 In `test/treby_web/live/ai_chat_widget_test.exs`, add/extend a test asserting an assistant message containing a table renders a `<table>` in the panel
- [x] 4.4 Run `mix test test/treby_web/markdown_test.exs test/treby_web/live/ai_chat_widget_test.exs`

## 5. Specs and docs

- [x] 5.1 Create `openspec/specs/markdown-rendering/spec.md` (Purpose + the two requirements from the change spec)
- [x] 5.2 Add the two new requirements to `openspec/specs/ai-chat-widget/spec.md`
- [x] 5.3 Update `site/features/ai-assistant.md` (tables in replies, movable/resizable panel, in English, UI-only wording)
- [x] 5.4 Run `node scripts/screenshots.mjs` and refresh affected screenshots

## 6. Final verification

- [x] 6.1 Run `mix precommit` and fix any issues
- [x] 6.2 Run `openspec validate --strict` and fix any issues
