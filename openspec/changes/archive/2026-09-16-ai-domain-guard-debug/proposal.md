## Why

The AI assistant currently answers any prompt, including requests that are off-topic, adversarial, or that could leak data. We want a two-stage safety net around the existing agent loop: an inbound guard that refuses off-topic and malicious questions before they run, and an outbound controller that reviews the assistant's final reply — blocking inappropriate content, normalizing formatting, and flagging any data-exfiltration or security concern. We also want lightweight debug logging around the pipeline so operators can see what happened on each turn.

## What Changes

- Extend the intent router so classification can return an `:out_of_domain` outcome in addition to the current domains (`recruiter`, `analytics`, `comms`, `admin`).
- Add a guard stage (at the start, before/within classification) that detects malicious or adversarial inputs (prompt injection, attempts to exfiltrate other tenants' data, ignore system instructions, or perform actions outside the user's role). Off-topic and malicious requests are refused and never reach the agent loop or the tool set; malicious refusals are logged.
- When the router decides a message is off-topic or malicious, the chat short-circuits and returns a single polite refusal message instead of running the agent loop and the tool set.
- Add an outbound control stage (at the end, after the agent produces its final answer) that evaluates the reply: it blocks responses that are still inappropriate, fixes/normalizes markdown formatting, and flags any suspected data-exfiltration or security issue (e.g. another tenant's data, secrets, or out-of-scope PII) — blocking or sanitizing such replies before they are persisted and broadcast.
- Add a debug-logging layer around the agent loop (classification result, selected profile, tool calls, iterations, token counts) emitted at `Logger.debug` level, gated behind the existing `:treby, :ai` config so it is silent in production by default.

## Capabilities

### New Capabilities
- `ai-response-control`: The outbound controller that runs after the agent's final answer — blocks inappropriate replies, normalizes formatting, and performs a best-effort security/exfiltration check before the message is persisted and broadcast.

### Modified Capabilities
- `ai-agent`: The intent router requirement changes — classification now yields an `:out_of_domain` outcome and flags malicious/adversarial inputs, and the chat must refuse both off-topic and malicious requests before (or instead of) running the agent loop. Sticky-domain behavior is unchanged for in-domain turns. The agent loop also gains debug logging and the outbound control stage.

## Impact

- Modules under `lib/treby/ai/`: `router.ex` (returns out-of-domain + malicious flag), `session.ex` (refuse path + outbound control call), `agent.ex` (debug logging, invoke outbound controller), and a new `control.ex` (outbound evaluator, likely reusing `Treby.AI.LLM`).
- `openspec/specs/ai-agent/spec.md`: delta for the router/out-of-domain/malicious requirement plus the new debug-logging and outbound-control requirements.
- Config: new optional `:treby, :ai` keys (`debug_logging` flag) — no migration required.
- No DB schema changes, no new PubSub topics, no breaking API changes.
