## 1. Notification Preferences

- [x] 1.1 Add `notification_preferences_enabled/2` and `set_notification_preference/3` functions to `Treby.Notifications` context that read/write from `tenant.settings["notifications"]`
- [x] 1.2 Add default notification preferences (all enabled) to the tenant creation flow in `Treby.Tenants`
- [x] 1.3 Create `SettingsLive.Notifications` LiveView with toggle switches for each notification type (stage_change_candidate, new_application_candidate, new_application_team)
- [x] 1.4 Add route `/app/settings/notifications` to the admin live_session in router.ex
- [x] 1.5 Add "Notifications" link to the settings index page

## 2. Notifications Context Module

- [x] 2.1 Create `Treby.Notifications` context module with `notify_stage_change/2`, `notify_new_application/2`, and `notify_team_new_application/2` public functions
- [x] 2.2 Implement `notify_stage_change/2` — resolves template for target stage type, renders with variables, sends via Swoosh, logs activity
- [x] 2.3 Implement `notify_new_application_candidate/2` — sends confirmation email to candidate after career page submission
- [x] 2.4 Implement `notify_team_new_application/2` — sends alert to tenant admins and job owner when application is created
- [x] 2.5 Add `Treby.Notifications.Email` module with `new_application_confirmation/2` and `new_application_team_alert/3` email builder functions (following `SchedulingEmail` pattern)

## 3. Stage Transition Trigger

- [x] 3.1 Modify `Pipeline.move_application/2` to call `Notifications.notify_stage_change/2` after successful stage update
- [x] 3.2 Ensure notification call is wrapped in try/rescue so delivery failures never crash the stage move
- [x] 3.3 Update the pipeline LiveView confirmation dialog to show notification status (email will be sent automatically if enabled)

## 4. Career Page Application Trigger

- [x] 4.1 Modify `CareersLive.Apply` to call `Notifications.notify_new_application_candidate/2` after successful application creation
- [x] 4.2 Modify `CareersLive.Apply` to call `Notifications.notify_team_new_application/2` after successful application creation
- [x] 4.3 Ensure both notification calls are wrapped in try/rescue so delivery failures never crash the application submission

## 5. Manual Application Trigger

- [x] 5.1 Add team notification to the manual application creation flow (when an authenticated user adds a candidate to a job)
- [x] 5.2 Ensure manual creation does NOT send candidate confirmation emails (only career page submissions do)

## 6. Activity Logging

- [x] 6.1 Log successful notification emails as activity events with metadata: email_type, recipient, subject, status "sent"
- [x] 6.2 Log failed notification emails as activity events with metadata: email_type, recipient, status "failed", error details

## 7. Tests

- [x] 7.1 Unit tests for `Treby.Notifications` context — preference reading/writing, notification dispatch logic
- [x] 7.2 Unit tests for `Treby.Notifications.Email` — email builder functions produce correct content
- [x] 7.3 Integration tests for stage transition notifications — move_application triggers email when template exists and preference enabled
- [x] 7.4 Integration tests for career page application notifications — submission triggers confirmation and team alerts
- [x] 7.5 Tests for notification preference toggling — disabled preferences prevent email sending
- [x] 7.6 Tests for error isolation — email delivery failure does not affect stage move or application submission
- [x] 7.7 Tests for SettingsLive.Notifications — admin can toggle preferences and see changes persisted
