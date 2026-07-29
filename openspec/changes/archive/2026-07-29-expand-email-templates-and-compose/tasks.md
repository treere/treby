## 1. Expand Email Template Stage Types

- [x] 1.1 Update `EmailTemplate.changeset/2` to accept all five stage types: `~w(new interview offer hired rejected)`
- [x] 1.2 Update `SettingsLive.EmailTemplates` dropdown to list all five stage types with human-readable labels
- [x] 1.3 Add tests for creating templates with each stage type

## 2. Fix {recruiter_name} Variable

- [x] 2.1 Add `actor` parameter to `Notifications.notify_stage_change/2` (currently `_actor`)
- [x] 2.2 Thread actor through `Pipeline.move_application/3` — add optional `actor` to opts, pass to `notify_stage_change`
- [x] 2.3 Update `PipelineLive.Index` to pass `current_user` as actor when calling `move_application`
- [x] 2.4 Update `BulkOperations` bulk move to accept and pass actor
- [x] 2.5 Set `recruiter_name` to `actor.name || ""` in `notify_stage_change` assigns
- [x] 2.6 Add tests verifying `{recruiter_name}` is populated correctly

## 3. Compose New Email Thread

- [x] 3.1 Add `EmailThreads.create_outbound_email/1` function — find-or-create thread by candidate+tenant+subject, insert outbound message, update thread timestamp
- [x] 3.2 Add compose form assigns to `CandidatesLive.Show` mount: `composing_email: false`, `compose_form: to_form(%{}, as: :compose)`
- [x] 3.3 Add "Compose Email" button in the Email History section of `CandidatesLive.Show` template
- [x] 3.4 Add inline compose form with subject and body fields (hidden by default, toggled by compose button)
- [x] 3.5 Add `handle_event("compose_email", ...)` to show the form
- [x] 3.6 Add `handle_event("cancel_compose", ...)` to hide the form
- [x] 3.7 Add `handle_event("send_compose", ...)` to validate, call `create_outbound_email`, refresh threads, show flash
- [x] 3.8 Add tests for compose flow: show form, cancel, send with validation, send successfully

## 4. Verify & Polish

- [x] 4.1 Run `mix precommit` and fix any lint/type issues
- [x] 4.2 Verify existing email template tests still pass
- [x] 4.3 Verify pipeline drag-and-drop email confirmation still works with expanded stage types
