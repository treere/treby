## Why

Treby has a mature email infrastructure (Swoosh mailer, stage-based email templates with variable interpolation, bidirectional email threading, and interview scheduling notifications) but lacks the two most fundamental automated notification flows expected of any ATS: (1) notifying candidates when their application status changes, and (2) alerting hiring managers when new applications arrive. The existing `stage-email-templates` spec defines the template system but the trigger in `Pipeline.move_application/2` is never wired up. This is the #1 remaining P1 item from the UX audit — "table stakes for ATS."

## What Changes

- Wire up automated email sending when candidates move between pipeline stages, using the existing stage-based email templates configured in Settings
- Add candidate confirmation emails when they apply via the public career page
- Add "new application" notification emails to job owners/admins when any application is submitted (public form or manual)
- Add a notification preferences section in Settings allowing admins to enable/disable each notification type per tenant
- Log all sent notification emails in the activity audit trail

## Capabilities

### New Capabilities

- `email-notifications`: Automated notification system that sends emails on pipeline stage transitions, new applications, and application confirmations, with per-tenant configurable preferences

### Modified Capabilities

- `stage-email-templates`: Existing spec requires modifications — the template system already defines sending behavior, but the trigger needs to be connected to `Pipeline.move_application/2` and the confirmation dialog flow needs to be implemented in the pipeline LiveView
- `career-page`: The public application submission flow needs to trigger confirmation and team notification emails after successful application creation

## Impact

- **Code changes**: `Pipeline.move_application/2` (add email trigger), `CareersLive.Apply` (add post-submission email sending), new `Notifications` context module, new `NotificationPreference` schema, new settings LiveView for preferences
- **Database**: New `notification_preferences` table (per-tenant settings), potential `sent_emails` log table for audit trail
- **Dependencies**: None new — uses existing Swoosh infrastructure
- **APIs**: No external API changes — all email delivery is internal via Swoosh
- **Existing behavior**: Stage moves will now optionally trigger email sending (non-blocking — if delivery fails, the stage move still completes)
