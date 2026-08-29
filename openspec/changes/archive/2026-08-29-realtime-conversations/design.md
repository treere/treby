## Context

The app already runs `{Phoenix.PubSub, name: Treby.PubSub}` (`lib/treby/application.ex`) and has an established realtime pattern in the pipeline feature: the context broadcasts on mutation (`Pipeline.move_application/3` → `Phoenix.PubSub.broadcast(Treby.PubSub, "pipeline:#{job_id}", {:pipeline_updated, job_id})`), the LiveView subscribes in `mount`, and `handle_info` re-fetches and reassigns.

Conversations currently have no PubSub: `Treby.CandidatePortal.send_message/1` and the private `create_message/1` only persist rows. All message creation in the app funnels through one of those two functions (manual sends, stage templates, scheduled/bulk messages, interviews, rejection/info requests, system messages), which makes them the single ideal broadcast point.

## Goals / Non-Goals

**Goals:**
- New messages appear in open conversation views without a reload (candidate portal thread, admin candidate profile).
- Portal inbox (Messages list) and portal dashboard conversation list refresh when conversations change.
- Reuse the existing pipeline PubSub pattern and the existing `Treby.PubSub` process.

**Non-Goals:**
- No websocket/transport changes — relies on LiveView's existing socket.
- No message read/typing indicators, no presence, no pagination of messages.
- No changes to how messages are persisted.

## Decisions

- **Broadcast from the context, not the LiveView.** The context is the single funnel for all message creation; broadcasting there guarantees every path (templates, scheduled, bulk, system) becomes realtime without each caller opting in.
  - Alternative considered: broadcasting from each LiveView handler after a successful `send_message`. Rejected: easy to miss non-LiveView writers (scheduled worker, bulk ops, interviews), producing inconsistent realtime behavior.
- **Topics.** Two topics per event:
  - `"conversation:#{conversation_id}"` — subscribed by the thread views (`MessageThread`, `CandidatesLive.Show`) to refresh the message list for one conversation.
  - `"candidate_conversations:#{candidate_id}"` — subscribed by the inbox/dashboard lists (`Messages`, `Index`) to refresh the whole conversation list for a candidate.
  - Event payload: `{:conversation_updated, conversation_id}` on both topics. Single event shape keeps `handle_info` trivial and avoids leaking entity details into the broadcast.
  - Alternative considered: a single `"candidate_conversations:#{candidate_id}"` topic for everything. Rejected: thread views would need to filter by conversation id on every update, and a recruiter-side admin view only cares about specific conversations.
- **Broadcast points** (all inside `Treby.CandidatePortal`):
  - After a successful message insert in `send_message/1`.
  - After a successful message insert in `create_message/1` (covers system/status/rejection/info-request messages and the welcome message in `create_conversation/2`).
  - After `close_conversation/1` succeeds.
  - Conversation creation itself (`create_conversation/2`) broadcasts to the candidate topic so a brand-new conversation appears in the inbox immediately.
  - Implementation detail: a single private helper `broadcast_conversation_updated(message_or_conversation)` loads the conversation (to resolve `candidate_id`) and broadcasts to both topics. Because `send_message/1` and `create_message/1` are independent insert points, the helper is called once per insert path — no double-broadcasting risk since they don't call each other.
- **Subscribers re-fetch from the DB on `handle_info`.** Follow the pipeline pattern exactly: `handle_info({:conversation_updated, _id}, socket)` re-runs the same query the view used in `mount` and reassigns. Simple, correct, and avoids maintaining an in-memory message cache.

## Risks / Trade-offs

- **Broadcast after DB write is eventually consistent** — a subscriber could briefly miss an update if the process crashes between insert and broadcast → Mitigation: this mirrors the existing pipeline pattern and the window is milliseconds; acceptable for chat.
- **Subscribe count grows with conversations** in `CandidatesLive.Show` (one topic per conversation) → Mitigation: candidates rarely have many conversations; topics are cheap; if it ever grows, a per-candidate topic + filtering is the fallback.
- **LiveView reconnect / missed messages** — a subscriber that reconnects re-runs `mount` and re-fetches, so no messages are lost. No change needed.
- **Broadcast emits to the sender's own view too** — the view that sent the message reloads itself (it already does). Harmless duplicate refresh.