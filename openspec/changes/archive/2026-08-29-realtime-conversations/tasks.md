## 1. Context broadcast layer

- [x] 1.1 Add `subscribe_to_conversation(conversation_id)` and `subscribe_to_candidate_conversations(candidate_id)` public helpers in `Treby.CandidatePortal` using `Phoenix.PubSub.subscribe/3`
- [x] 1.2 Add a private `broadcast_conversation_updated(message_or_conversation)` helper that resolves the conversation (and its `candidate_id`) and broadcasts `{:conversation_updated, conversation_id}` to `"conversation:#{id}"` and `"candidate_conversations:#{candidate_id}"`

## 2. Hook broadcasts into all mutation paths

- [x] 2.1 Call the broadcast helper after a successful insert in `send_message/1`
- [x] 2.2 Call the broadcast helper after a successful insert in `create_message/1` (covers system/status/rejection/info-request messages and the welcome message)
- [x] 2.3 Broadcast to the candidate topic after a successful `create_conversation/2` so new conversations appear in inboxes immediately
- [x] 2.4 Broadcast after a successful `close_conversation/1`

## 3. Subscribe LiveViews (candidate portal)

- [x] 3.1 `CandidatePortalLive.MessageThread` — subscribe to `conversation:<id>` in `mount`; add `handle_info({:conversation_updated, _id}, socket)` that reloads the conversation and reassigns
- [x] 3.2 `CandidatePortalLive.Messages` (inbox) — subscribe to `candidate_conversations:<candidate_id>` in `mount`; add `handle_info` that reloads and reassigns the conversation list
- [x] 3.3 `CandidatePortalLive.Index` (portal dashboard) — subscribe to `candidate_conversations:<candidate_id>` in `mount`; add `handle_info` that reloads and reassigns the conversation list

## 4. Subscribe LiveView (admin panel)

- [x] 4.1 `CandidatesLive.Show` — subscribe to `conversation:<id>` for each of the candidate's conversations in `mount`; add `handle_info({:conversation_updated, _id}, socket)` that reloads and reassigns `conversations`

## 5. Verification

- [x] 5.1 Add a test for the candidate portal thread: mount the thread, send a recruiter message via the context, assert the new message is rendered without a page reload
- [x] 5.2 Add a test for the admin candidate view: mount the show view, send a candidate message via the context, assert the new message appears in the rendered conversation
- [x] 5.3 Run `mix test test/treby_web/live/candidate_portal_live/message_thread_test.exs` (or equivalent) and the candidates show test file; fix any failures