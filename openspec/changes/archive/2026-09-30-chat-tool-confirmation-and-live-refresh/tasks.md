## 1. Confirmation summary backend

- [x] 1.1 Add optional `summary/1` callback + `Tools.describe/2` with generic fallback (humanized labels, truncated values, max ~8 rows)
- [x] 1.2 Add curated `summary/1` for all 62 destructive tools (every tool with `destructive?: true`); assert coverage with a test enumerating destructive tools
- [x] 1.3 Add `Tools.entity_of/2` mapping confirmed results to `%{type, id}` with nil fallback

## 2. Confirmation card UI

- [x] 2.1 Replace raw-JSON `<pre>` in chat widget with summary card (title, field rows, collapsed Details with raw JSON, Confirm/Cancel unchanged)
- [x] 2.2 Verify light + dark themes, wrapping/truncation, and unique DOM IDs for card elements
- [x] 2.3 Add widget tests: summary rows render, Details contains raw args, every destructive tool renders its curated summary (no fallback)

## 3. Live page refresh

- [x] 3.1 Broadcast `{:ai_entity_changed, user_id, entity}` after confirmed tool execution (post-commit, same per-user topic)
- [x] 3.2 Forward entity messages through the chat hook to the host LiveView
- [x] 3.3 Add refresh handlers for jobs list/detail, candidates list, pipeline, notes (re-query + stream update); flash-with-link fallback for other pages
- [x] 3.4 Add tests: confirming a job creation while on jobs list shows it without reload; other users/tenants unaffected

## 4. Specs + docs + verification

- [x] 4.1 Update main specs at `openspec/specs/chat-tool-confirmation`, `ai-live-page-refresh`, `ai-chat-widget`, `job-management` (Purpose/Requirements + WHEN/THEN scenarios)
- [x] 4.2 Update user manual (`site/features/` assistant page + sidebar/index if needed) and regenerate screenshots (`node scripts/screenshots.mjs`, `--axe` for contrast)
- [x] 4.3 Run `mix precommit` and `openspec validate --strict` and fix issues
