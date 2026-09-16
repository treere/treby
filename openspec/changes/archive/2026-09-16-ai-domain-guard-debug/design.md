## Context

Today `lib/treby/ai/` runs a single streaming agent (`Treby.AI.Agent`) selected per turn by `Treby.AI.Router.classify/3` into one of four domains (`recruiter`, `analytics`, `comms`, `admin`). The loop streams the reply, runs read tools immediately, and parks destructive tools as pending confirmation. There is no gate on what the user may ask and no review of what the model returns.

We want a two-stage safety net (inbound guard + outbound controller) plus debug logging, without changing the existing four-domain tool loop or the human-confirmation model.

## Goals / Non-Goals

**Goals:**
- Refuse off-topic and malicious/adversarial prompts before the agent loop runs.
- Review the final assistant reply: block inappropriate content, normalize markdown formatting, and best-effort flag data-exfiltration / security concerns.
- Emit `Logger.debug` trace lines per turn, gated by config.

**Non-Goals:**
- Not replacing or retraining the underlying LLM provider.
- Not adding a new interactive "debug log reader" domain — debug output is server logging, not a tool the agent calls.
- Not changing destructive-tool confirmation or tenant-scoped queries (those remain the real security boundary).

## Decisions

### 1. Guard lives inside the Router (single classification call)
`Router.classify/3` returns one of six outcomes: `:recruiter | :analytics | :comms | :admin | :out_of_domain | :malicious`. The router prompt lists all six classes; `parse_classification/2` maps the model word to an atom (unknown words fall back to the sticky `last_domain`, never to `:out_of_domain`/`:malicious` by default).

- **Why**: the user allowed the classifier to own this, and it avoids a second LLM round-trip. A separate pre-classification guard would double latency/cost for zero extra safety.
- **Alternative considered**: a dedicated guard LLM call before classification — rejected for cost/latency.
- **Fail-closed note**: on classification *error* (LLM unavailable) the router keeps the prior `last_domain` (availability over blocking). Only an explicit model signal triggers refusal. Documented as a trade-off; the outbound controller is the backstop.

### 2. Refusal short-circuits in `Session.chat/2`
If `Router.classify` returns `:out_of_domain` or `:malicious`, `Session.chat` persists one polite refusal assistant message (and, for `:malicious`, a `Logger.warning`) and returns `{:ok, :refused}` without calling `Agent.chat`. No tool, no streaming.

### 3. Outbound controller as a new `Treby.AI.Control` module
After the agent produces a `:final_answer`, `Agent` calls `Control.evaluate(text, ctx)` once (non-streaming, via `Treby.AI.LLM` like the router). The controller is asked to return a small JSON:
```json
{ "verdict": "pass|block|sanitize", "reply": "<fixed text>", "reason": "..." }
```
- `pass` → persist as-is.
- `block` → replace with a canned "I can't share that" refusal and log.
- `sanitize` → persist the model-provided `reply` (e.g. PII/other-tenant data stripped), log the reason.

The controller prompt instructs it to **only** fix formatting and strip exfiltration/security issues — never change the factual meaning of an in-scope answer. This is best-effort (the user acknowledged "non può fare miracoli"); the real boundary is tenant-scoped DB queries + human confirmation on writes.

- **Why a new module, not inline in `Agent`**: keeps the evaluation prompt, parsing, and verdict handling isolated and unit-testable (JSON parsing is testable without an LLM, mirroring `Router.parse_classification`).
- **Fail-closed note**: if `Control.evaluate` errors or returns unparseable output, `Agent` persists the original reply (availability) and logs — the guard + tenant scoping remain the primary protection.

### 4. Debug logging, config-gated
A `debug_log/2` helper in `Agent` emits structured `Logger.debug` lines (domain, profile, iteration count, tool calls, token count, control verdict) only when `Application.get_env(:treby, :ai)[:debug_logging]` is truthy. Silent in production by default.

## Risks / Trade-offs

- **LLM guard bypass / jailbreak** → Mitigation: defense in depth — inbound guard, outbound controller, tenant-scoped queries, and human confirmation on destructive tools. No single layer is trusted.
- **Extra latency & cost** → Mitigation: guard reuses the existing classify call; controller runs once at the end with a small/fast model; both are non-streaming and cheap relative to the main agent loop.
- **Controller altering meaning** → Mitigation: prompt restricts it to formatting + stripping; `block`/`sanitize` paths are logged for audit.
- **Availability vs fail-closed** → Mitigation: errors in guard/controller fall back to allow-and-log rather than blanket block, accepting that the real security boundary is tenant scoping + confirmation.
- **False refusals** → Mitigation: `:out_of_domain`/`:malicious` only on explicit model signal; ambiguous inputs keep the sticky domain.

## Migration Plan

- Additive, no DB migration. New optional config keys under `:treby, :ai` (`debug_logging`).
- Deploy: enable `debug_logging` in staging to observe. Rollback: disable config flag / revert module; no data changes.

## Open Questions

- Should the controller run on every final answer or only when the model touched tools/data? (Proposal: every final answer for consistency.)
- Canned refusal wording for `:out_of_domain` vs `:malicious` vs control `block` — to be finalized in implementation, keep user-facing text in English.
