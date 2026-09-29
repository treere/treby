## Why

Chat tool confirmations currently show a raw JSON dump (`Jason.encode!(run.args, pretty: true)`), which is hard to scan and intimidating for non-technical users. Separately, entities created or modified from the chat (e.g. a job created while viewing the jobs page) only appear after a manual page reload, breaking the feeling that the assistant acts on the current page.

## What Changes

- Replace the raw JSON confirmation block with a human-readable summary card per tool: action title, key fields as label/value rows, and a collapsed "Details" section with the full JSON for transparency.
- Add a per-tool humanizer (`summary/1` on tool modules with a generic fallback) so new tools get a readable confirmation without custom UI work.
- After a confirmed tool run executes, notify the host LiveView so the current page refreshes its data (streams/assigns) without a full reload; fall back to a flash + link when the page cannot live-refresh.
- Cover at minimum jobs list/detail, candidates list, applications/pipeline, and notes; other pages get the generic refresh path.
- Keep existing safety behavior unchanged: confirmation still required for destructive tools, rejections still do nothing, audit logging unchanged.

## Capabilities

### New Capabilities

- `chat-tool-confirmation`: human-readable confirmation cards for pending tool runs (title, field rows, collapsible raw details, per-tool summary with fallback).
- `ai-live-page-refresh`: host-page live refresh after a confirmed chat tool mutation (page-aware reload signal, stream/assign refresh, fallback flash when unsupported).

### Modified Capabilities

- `ai-chat-widget`: confirmation rendering requirement changes from raw JSON `<pre>` to summary card + details disclosure.
- `job-management`: job list/detail pages refresh live when a job is created/updated via chat instead of requiring manual reload.

## Impact

- UI: `AiChatWidget` confirmation block, new summary helper, design-system card patterns (light/dark), i18n strings.
- LiveViews: host hook (`Hooks.AiChat`) gains a page-refresh notification (`:ai_entity_changed`); affected index/detail LiveViews (jobs, candidates, pipeline, notes) add `handle_info` refresh clauses.
- Domain: optional `summary/1` callback on tool modules; generic fallback formatter in `Tools`; no schema or migration changes (PubSub payload only).
- Docs: user-manual update for the assistant page (`site/features/`) + regenerated screenshots.
