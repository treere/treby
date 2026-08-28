## Context

Candidates may legitimately exist without any application (pool candidates created via "+ Add Candidate", or the `create_or_find` upsert path in `candidates.ex:91-113`, which never creates an application). The candidate profile LiveView assumed at least one application:

- `submit_request_info` (show.ex:1175): `application_id: List.first(socket.assigns.applications).id`
- `submit_rejection` (show.ex:1239): same pattern before building the conversation

With an empty list, `List.first/1` returns `nil` and `.id` raises `BadMapError`, terminating the LiveView process (reproduced in-browser: the client reconnects and loses state).

`send_new_message` (show.ex:1103-1111) is already nil-safe (`if(application, do: application.id)`).

## Goals / Non-Goals

**Goals:**
- No profile action crashes for a candidate with no applications.
- Clear user-facing error when an action requires an application that doesn't exist.

**Non-Goals:**
- Not changing the portal conversation data model.

## Decisions

- Introduce a small guard for the two crash sites: before creating the conversation, verify `applications` is non-empty; if empty, return `{:noreply, put_flash(socket, :error, "...")}` with a specific message (e.g., "This candidate has no applications yet").
- For rejection without an application, also skip the stage-move/email logic (nothing to transition) while still surfacing the error.
- Keep `send_new_message` as-is (already guarded) and add a regression assertion locking its behavior.

## Risks / Trade-offs

- [Flash-only errors may be missed on small screens] → Mitigation: flash is rendered app-wide; consistent with existing error patterns in `error-feedback`.