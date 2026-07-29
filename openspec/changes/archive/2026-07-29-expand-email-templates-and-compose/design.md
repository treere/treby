## Context

The email template system currently restricts `stage_type` to `~w(rejected hired)` in the `EmailTemplate` changeset, even though the pipeline has five stage types: `new`, `screen` (no type), `interview`, `offer`, `hired`. The settings UI dropdown mirrors this restriction. Meanwhile, `notify_stage_change` already looks up templates by `stage.stage_type` — it would naturally find templates for other types if they existed.

The `{recruiter_name}` variable is hardcoded to `""` in `notifications.ex:68` despite the `_actor` parameter being accepted. The actor is available in the pipeline LiveView (where `move_candidate` is handled) but is never passed through to `notify_stage_change`.

The email threading backend supports `create_inbound_email` (webhook) and `send_reply` (reply to existing thread), but there's no function to create a new outbound thread from scratch. The candidate show page has a reply form but no compose-new form.

## Goals / Non-Goals

**Goals:**
- Allow email templates for all five pipeline stage types
- Fix `{recruiter_name}` to show the actual recruiter's name
- Enable composing new email threads from the candidate show page
- Maintain backward compatibility with existing `rejected`/`hired` templates

**Non-Goals:**
- Changing the one-template-per-stage-type-per-tenant constraint
- Adding a standalone inbox page (threads remain per-candidate)
- Email threading headers (`In-Reply-To`, `References`) — future work
- Unread/read tracking — future work
- Production mailer configuration — outside scope

## Decisions

### 1. Expand stage_type validation in changeset only

**Decision:** Change `validate_inclusion(:stage_type, ~w(rejected hired))` to `~w(new interview offer hired rejected)` in `EmailTemplate.changeset/2`.

**Why:** No migration needed. The database column is a plain `string` with no CHECK constraint. The restriction is purely application-level. Existing templates continue to work.

**Alternative considered:** Adding a database-level CHECK constraint — rejected because it adds migration complexity for no practical benefit; the app controls all writes.

### 2. Pass actor through Pipeline.move_application → notify_stage_change

**Decision:** Add an `actor` parameter to `Pipeline.move_application/3` and thread it through to `Notifications.notify_stage_change/2`. The pipeline LiveView already has `socket.assigns.current_user`.

**Why:** The actor is the person who moved the candidate — their name is the most relevant "recruiter_name". This is the natural call site.

**Alternative considered:** Looking up the actor from the activity log — rejected because it adds a query and the actor is already available at the call site.

### 3. Add compose-new-thread via new context function

**Decision:** Add `EmailThreads.create_outbound_email/1` that creates a new thread (find-or-create by candidate+tenant+subject) and inserts an outbound message, similar to `create_inbound_email` but for outbound.

**Why:** Mirrors the existing inbound pattern. The candidate show page already loads email threads and has the candidate's email — just needs a compose form and the new context function.

**Alternative considered:** Reusing `send_reply` with a fake thread — rejected because `send_reply` requires an existing thread_id and loads the thread to get the candidate email.

### 4. Compose form inline on candidate show page

**Decision:** Add a "Compose Email" button next to the "Email History" heading that opens an inline form (subject + body fields) similar to the existing reply form.

**Why:** Consistent with the existing reply UX. No new page needed. The candidate context is already loaded.

## Risks / Trade-offs

- **[Risk] Templates for "new" stage may fire on initial application creation** → The `notify_stage_change` is only called from `Pipeline.move_application`, not from application creation. Moving a candidate to "new" stage manually would trigger it, which is the intended behavior.
- **[Risk] Compose email uses tenant's noreply address** → The `from` address in `send_reply` uses the user's email. For compose, we should use the same pattern. If the user's email isn't configured for sending, delivery may fail — but that's existing behavior for replies too.
- **[Trade-off] One template per stage type stays** → Multiple templates per stage (e.g., different for different jobs) would require schema changes. Out of scope.
