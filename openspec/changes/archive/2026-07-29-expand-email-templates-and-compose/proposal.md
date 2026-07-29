## Why

Email templates are artificially restricted to only "rejected" and "hired" stage types, even though the pipeline has five stage types (`new`, `interview`, `offer`, `hired`, `rejected`). This means recruiters cannot automate emails for the most common transitions — notifying candidates they've been moved to interview, or that an offer is coming. Additionally, the `{recruiter_name}` template variable is always rendered as an empty string because `notify_stage_change` never receives the actor. Finally, the email threading system only supports replying to existing threads — there's no way to start a new conversation with a candidate from the UI.

## What Changes

- Expand `stage_type` validation from `~w(rejected hired)` to `~w(new interview offer hired rejected)` so templates can be created for all pipeline stage types
- Update the settings email template form dropdown to list all five stage types
- Fix `{recruiter_name}` in `notify_stage_change` by passing the actor's name through the notification chain
- Add a "Compose Email" button on the candidate show page that creates a new email thread with subject, body, and sends it via Swoosh
- Add a `create_outbound_email/1` function to the `EmailThreads` context for creating new threads (not just replying)

## Capabilities

### Modified Capabilities
- `stage-email-templates`: Expand allowed stage types from `rejected`/`hired` to all five types; fix `{recruiter_name}` variable population
- `bidirectional-email`: Add compose-new-thread capability (currently only reply is supported)

### New Capabilities
_(none — both changes extend existing capabilities)_

## Impact

- **Schema change**: `email_templates.stage_type` validation widens — no migration needed, just changeset update
- **Context changes**: `EmailTemplates` changeset validation, `Notifications.notify_stage_change/2` actor passthrough, `EmailThreads` new compose function
- **LiveView changes**: `SettingsLive.EmailTemplates` dropdown options, `CandidatesLive.Show` compose button + form
- **No breaking changes**: Existing templates for `rejected`/`hired` continue to work unchanged
- **No new dependencies**: Uses existing Swoosh infrastructure
