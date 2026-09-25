## Why

Assistant replies that contain Markdown tables render as an unreadable wall of
pipes: the shared renderer parses CommonMark only (tables are off) and the
sanitizer explicitly strips table tags. The same gap affects every Markdown
surface in the app (job descriptions, company branding, chat). Separately, the
floating assistant panel is a fixed 24rem x 32rem box that cannot be moved or
resized, so it covers page content on smaller screens.

## What Changes

- Enable GFM table parsing in the shared Markdown renderer (`MDEx`) and allow
  the table tag set in the sanitizer allowlist (`table`, `thead`, `tbody`,
  `tr`, `th`, `td`). This applies to every Markdown surface at once.
- Ensure the rendered table styling works in the chat bubble (`.md-content`),
  in both light and dark themes, with horizontal overflow for wide tables.
- Add a tests case for table rendering (structure, sanitization, dark theme
  scope is CSS-only).
- Make the floating assistant panel movable (drag by header) and resizable
  (bottom-right grip). Geometry (position + size) is persisted client-side in
  `localStorage` and restored on mount, clamped to the viewport.
- Keep the panel usable on mobile: drag/resize disabled or clamped so the panel
  never leaves the visible viewport.

## Capabilities

### New Capabilities
- `markdown-rendering`: shared Markdown-to-HTML contract for all user/AI-authored
  content, including GFM tables and the sanitizer allowlist.

### Modified Capabilities
- `ai-chat-widget`: assistant replies render tables; the floating panel can be
  moved and resized with persisted geometry.

## Impact

- `lib/treby_web/markdown.ex`: pass `extension: [table: true]` to `MDEx.to_html!/2`.
- `lib/treby_web/markdown_scrubber.ex`: allow `table`, `thead`, `tbody`, `tr`,
  `th`, `td` (no attributes; no images/scripts, unchanged).
- `assets/css/app.css`: verify `.md-content` table rules cover the chat bubble in
  light and dark (already present; adjust overflow if needed).
- `lib/treby_web/components/ai_chat_widget.ex`: add drag handle + resize grip
  hooks to the floating panel.
- `assets/js/hooks/ai_chat.js`: add geometry (drag/resize/persist/clamp) hook.
- `test/treby_web/markdown_test.exs`: table rendering + sanitizer test.
- `test/treby_web/live/ai_chat_widget_test.exs`: widget still renders/streams.
- Docs: `site/features/ai-assistant.md`, regenerate screenshots.
- No new dependencies, no DB migrations.
