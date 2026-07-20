## 1. Foundation: Encryption & Dependencies

- [x] 1.1 Add `cloak_ecto ~> 1.3.0` and `goth ~> 1.4` to `mix.exs`
- [x] 1.2 Create `Treby.Vault` module (Cloak vault with AES-GCM, reads `CLOAK_KEY` env var)
- [x] 1.3 Create `Treby.Encrypted.Binary` Ecto type using `Cloak.Ecto.Binary`
- [x] 1.4 Add Vault to application supervision tree (before Repo)
- [x] 1.5 Add `CLOAK_KEY` to `runtime.exs` (with fallback for dev/test)
- [x] 1.6 Create migration for `encrypted_binary` Postgres type

## 2. Google Calendar Connection

- [x] 2.1 Create `calendar_connections` migration (user_id, provider, access_token, refresh_token, token_expires_at, google_email, calendar_id, tenant_id)
- [x] 2.2 Create `Treby.Calendar.CalendarConnection` schema with encrypted fields
- [x] 2.3 Create `Treby.Calendar.Google` module — Req-based Google Calendar API client (free_busy, create_event, delete_event)
- [x] 2.4 Implement lazy token refresh in `Google.get_valid_token/1` (check expiry, refresh if <5min remaining)
- [x] 2.5 Create `Treby.Calendar` context — `connect_google_user/2`, `get_connection/1`, `disconnect_google_user/1`
- [x] 2.6 Add Google OAuth config to `config.exs` and `runtime.exs` (`GOOGLE_CLIENT_ID`, `GOOGLE_CLIENT_SECRET`)
- [x] 2.7 Create `GoogleAuthController` — OAuth redirect + callback (stores tokens, calendar ID, email)
- [x] 2.8 Add OAuth routes to router (`/auth/google`, `/auth/google/callback`)
- [x] 2.9 Create `SettingsLive.Calendar` — show connection status, connect/disconnect buttons

## 3. Availability Rules

- [x] 3.1 Create `availability_rules` migration (user_id, day_of_week, start_time, end_time, timezone, buffer_before, buffer_after, tenant_id)
- [x] 3.2 Create `Treby.Availability.AvailabilityRule` schema
- [x] 3.3 Create `Treby.Availability` context — CRUD functions, scoped by tenant+user
- [x] 3.4 Create `SettingsLive.Availability` — weekly schedule editor (day picker, time inputs, timezone selector, buffer config)
- [x] 3.5 Add availability settings link to `SettingsLive.Index`

## 4. Slot Computation Engine

- [x] 4.1 Implement `Treby.Availability.compute_slots/4` — takes user, date range, duration, returns available slots
- [x] 4.2 Implement slot generation: generate 30min blocks within availability rules
- [x] 4.3 Implement busy period subtraction: query Google FreeBusy, subtract from generated slots
- [x] 4.4 Implement buffer subtraction: exclude slots within buffer_before/after of busy periods
- [x] 4.5 Return slots as list of `{start_utc, end_utc}` tuples

## 5. Interview Events

- [x] 5.1 Create `interview_events` migration (application_id, scheduled_by, interviewer_id, start_at_utc, end_at_utc, duration_minutes, video_conf_url, google_event_id, status, notes, tenant_id)
- [x] 5.2 Create `Treby.Interviews.InterviewEvent` schema
- [x] 5.3 Create `Treby.Interviews` context — `schedule_interview/1`, `cancel_interview/1`, `list_upcoming_for_user/1`, `list_for_application/1`
- [x] 5.4 Implement Google Meet event creation in `Treby.Calendar.Google.create_event_with_meet/3` (conferenceDataVersion=1)
- [x] 5.5 Implement interview scheduling flow: create event → store interview_event → move application to "Interview" stage
- [x] 5.6 Implement interview cancellation: update status → delete Google event

## 6. Interview Scheduling Page (Recruiter)

- [x] 6.1 Create `ScheduleLive.Index` — scheduling page at `/app/schedule/:application_id`
- [x] 6.2 Implement interviewer selection (list tenant users with Google connected)
- [x] 6.3 Implement date range picker and available slots display
- [x] 6.4 Implement slot selection and booking confirmation
- [x] 6.5 Wire up to `Treby.Interviews.schedule_interview/1`

## 7. Candidate Self-Scheduling

- [x] 7.1 Create `booking_tokens` migration (token, application_id, interviewer_id, expires_at, used_at, tenant_id)
- [x] 7.2 Create `Treby.Interviews.BookingToken` schema
- [x] 7.3 Implement token generation in `Treby.Interviews.generate_booking_link/1`
- [x] 7.4 Create `SchedulingLive.Booking` — public page at `/:slug/schedule/:token` (no auth)
- [x] 7.5 Display available slots for next 14 days
- [x] 7.6 Implement slot selection and event creation on confirmation
- [x] 7.7 Handle expired/used tokens with appropriate messages
- [x] 7.8 Add "Generate booking link" button to `ScheduleLive.Index`

## 8. Notifications

- [x] 8.1 Create `Treby.SchedulingEmail` module with Swoosh email templates
- [x] 8.2 Implement candidate notification email (interview details + Meet link)
- [x] 8.3 Implement interviewer notification email (candidate details + Meet link)
- [x] 8.4 Send emails from interview scheduling flow

## 9. Interviews Dashboard

- [x] 9.1 Create `InterviewsLive.Index` — upcoming interviews list at `/app/interviews`
- [x] 9.2 Display interviews sorted by date with candidate name, job, interviewer, Meet link
- [x] 9.3 Add filter by interviewer
- [x] 9.4 Add interviews dashboard link to main navigation

## 10. Pipeline & Candidate Profile Integration

- [x] 10.1 Modify pipeline card view to show camera icon + interview date for "Interview" stage
- [x] 10.2 Modify candidate profile to show "Scheduled Interviews" section with Meet links
- [x] 10.3 Add interviews link to candidate profile

## 11. Polish & Testing

- [x] 11.1 Add tests for `Treby.Calendar` context (token refresh, FreeBusy parsing)
- [x] 11.2 Add tests for `Treby.Availability` (slot computation with mock data)
- [x] 11.3 Add tests for `Treby.Interviews` (schedule, cancel, booking tokens)
- [x] 11.4 Add tests for scheduling LiveViews
- [x] 11.5 Add tests for public booking page
- [x] 11.6 Run `mix precommit` and fix any issues
