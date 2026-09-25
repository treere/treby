## Context

All Markdown in Treby funnels through `TrebyWeb.Markdown.to_safe_html/1`
(`lib/treby_web/markdown.ex`): it calls `MDEx.to_html!/1` then scrubs the result
through `TrebyWeb.MarkdownScrubber` and wraps it in `Phoenix.HTML.raw/1`. Callers
are the `<.markdown>` core component (company about, job descriptions, previews)
and the assistant widget (`lib/treby_web/components/ai_chat_widget.ex`, both the
persisted message and the streaming buffer).

Two independent reasons tables do not render today, verified against the
installed MDEx 0.14:

1. `MDEx.to_html!/1` defaults to CommonMark. A table is emitted as a literal
   `<p>| A | B |\n|---|---|...` paragraph unless `extension: [table: true]` is
   passed.
2. `TrebyWeb.MarkdownScrubber` does not allow `table`/`thead`/`tbody`/`tr`/`th`/`td`,
   so even a correctly parsed table is stripped.

The floating widget is rendered by `TrebyWeb.AiChatWidget` inside
`Layouts.app`. The root `<div>` carries `phx-hook="AiChatToggle"`
(`assets/js/hooks/ai_chat.js`), which restores the open state from
`localStorage` and toggles the `hidden` class on `[data-ai-chat-panel]`. The
panel is positioned with Tailwind `fixed bottom-4 right-4 w-[24rem] h-[32rem]`
and has no drag or resize behavior. LiveView enforces one `phx-hook` per
element, so geometry cannot be added to the root element that already hosts
`AiChatToggle`.

## Goals / Non-Goals

**Goals:**
- Render GFM tables in every Markdown surface, sanitized (no attributes, no
  scripts/images), readable and horizontally scrollable when wide.
- Let the user move and resize the floating assistant panel; persist geometry
  across navigation, refresh, and LiveView re-renders; keep it inside the
  viewport.
- Keep behavior identical on the dedicated assistant page and for the
  open/close persistence already in place.

**Non-Goals:**
- Additional GFM extensions (task lists, footnotes, autolinks) — only tables are
  requested; add later if needed.
- Editing/authoring Markdown, live preview, or a Markdown toolbar.
- Server-side storage of widget geometry or per-tenant preferences (client-side
  only, same as the open state).
- Touch-specific gesture polish beyond clamping/pointer events.

## Decisions

### 1. Enable tables at the renderer, allowlist them at the scrubber
`Markdown.to_safe_html/1` becomes `MDEx.to_html!(text, extension: [table: true])`.
The scrubber gains exactly the six table tags with no attributes (cells carry
text only). Rationale: one change fixes chat, job descriptions, and branding
simultaneously, matching the request that it apply to all app Markdown.
Alternatives: a chat-only renderer — rejected (duplicates the pipeline and
leaves other surfaces inconsistent); enabling GFM wholesale — rejected (wider
attack surface than requested).

### 2. Tables scroll, not wrap
`.md-content table` already uses `display: block; overflow-x: auto`. Keep it, so
wide tables scroll inside the bubble instead of breaking the layout. Columns use
the existing light/dark th/td/border rules; no new CSS tokens.

### 3. Geometry lives in a dedicated hook on the panel, not the root
Add `phx-hook="AiChatGeometry"` to the `[data-ai-chat-panel]` element (which has
no hook today), leaving `AiChatToggle` on the root. The hook:
- reads/writes `localStorage["treby-ai-chat-geometry"]` (`{x, y, w, h}`);
- applies geometry as inline `style` (left/top/width/height) plus disabling the
  default `right`/`bottom` anchoring, so LiveView re-renders that patch `class`
  do not remove it (style is not part of the server template);
- drags on a `data-ai-chat-drag` header region (pointer events, capture);
- resizes on a `data-ai-chat-resize` bottom-right grip (pointer events);
- clamps to `[0, innerWidth]`/`[0, innerHeight]` with a minimum size, and
  re-clamps on `window.resize`.

Rationale: separate element avoids the one-hook-per-element constraint and keeps
`AiChatToggle` unchanged. Alternative: merge everything into `AiChatToggle` —
rejected (couples unrelated concerns, larger diff, no benefit).

### 4. Client-side persistence only
Geometry persists in `localStorage`, consistent with the open-state decision in
the archived `ai-chat-global-widget` design. No messages or user data are stored
client-side. Per-user server persistence is out of scope.

### 5. Mobile handling
Below a small breakpoint the panel keeps its current responsive defaults; the
hook still allows dragging but always clamps to the viewport, so the panel can
never be dragged off-screen. Minimum width/height prevent an unusable sliver.

## Risks / Trade-offs

- [Inline style vs. LiveView patching] → The server never renders `style` on the
  panel, so LiveView patches do not include it; geometry survives re-renders.
  If a future template adds `style`, reconcile by moving geometry into the
  server assign.
- [localStorage geometry stale after viewport change] → `window.resize` re-clamps;
  a corrupt/missing value falls back to the default anchored size.
- [Tables with many columns overflow the 24rem bubble] → `overflow-x: auto` keeps
  content readable inside the bubble.
- [Sanitizer over-restriction] → Allowlist adds tags only, no attributes; links
  keep the existing http/https restriction. Tables cannot carry inline styles,
  scripts, or event handlers.
- [Drag conflicts with text selection / click on header buttons] → Drag starts
  only from non-interactive parts of the header and uses pointer capture.

## Migration Plan

No migration, no new dependency. Deploy is a code-only release. Rollback:
revert the extension/allowlist lines and the hook; no data changes to undo.

## Open Questions

- Should tables also be enabled for the job-description live preview
  (which uses the same component)? Yes — same renderer path, no extra work.
- Minimum bubble size: default 20rem x 16rem; revisit if users request smaller.
