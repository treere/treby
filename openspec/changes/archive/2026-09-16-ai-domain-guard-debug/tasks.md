## 1. Inbound guard (Router + Session)

- [x] 1.1 Extend `Treby.AI.Router` to classify into six outcomes (`recruiter`, `analytics`, `comms`, `admin`, `:out_of_domain`, `:malicious`): update `system_prompt/0`, `@domains`, `parse_classification/2`/`parse/2`, and make `classify/3` return the atom (or a tagged tuple carrying the verdict).
- [x] 1.2 Update `Treby.AI.Session.chat/2` to short-circuit on `:out_of_domain`/`:malicious`: persist one polite refusal assistant message, return `{:ok, :refused}`, and log a `Logger.warning` for `:malicious` (no `Agent.chat`, no tools).
- [x] 1.3 Add a unit-testable refusal path in `Treby.AI.Session` (mock router) covering off-topic, malicious, in-domain, and ambiguous/error fallback to sticky domain.

## 2. Outbound controller

- [x] 2.1 Create `Treby.AI.Control` module with `evaluate/2` that calls `Treby.AI.LLM.generate/2` (non-streaming) and parses a JSON verdict `{verdict, reply, reason}` (`pass|block|sanitize`); keep parsing testable without an LLM.
- [x] 2.2 Wire `Control.evaluate/2` into `Treby.AI.Agent` after a `:final_answer`: handle `pass` (persist as-is/normalized), `block` (canned refusal + log), `sanitize` (use model `reply` + log), and fail-closed pass-through on error/unparseable output with a log.
- [x] 2.3 Write `Treby.AI.Control` tests covering pass/block/sanitize verdicts and the error/fallback path (using a stubbed LLM or fixed JSON fixtures).

## 3. Agent debug logging

- [x] 3.1 Add a config-gated `debug_log/2` helper in `Treby.AI.Agent` (reads `Application.get_env(:treby, :ai)[:debug_logging]`) emitting structured `Logger.debug` lines for domain, profile, iterations, tool calls, token count, and control verdict.
- [x] 3.2 Call `debug_log/2` at the key pipeline points in `Agent.chat`/`run_loop`/`handle_response` (entry, classification result from Session, loop exit, control verdict).

## 4. Tests

- [x] 4.1 Add/extend `agent_test.exs` covering: off-topic refusal persists no tool run, malicious refusal logs and persists no tool run, in-domain still runs the loop, and final answer passes through `Control`.
- [x] 4.2 Add `router_test.exs` scenarios for the six-class parse (including unrecognized word / error falling back to sticky domain, never to `:out_of_domain`/`:malicious`).

## 5. Specs sync + docs

- [x] 5.1 Sync main specs: update `openspec/specs/ai-agent/spec.md` with the inbound-guard and debug-logging requirements; add `openspec/specs/ai-response-control/spec.md` from the change delta.
- [x] 5.2 Add a short `site/features/ai-safety.md` user-facing page (English) describing that the assistant only answers workspace questions and reviews its own replies; register it in `site/.vitepress/config.ts` and `site/features/index.md`. Regenerate screenshots with `node scripts/screenshots.mjs` if UI copy changes.

## 6. Validation

- [x] 6.1 Run `mix precommit` and `openspec validate --strict` and fix any issues.
