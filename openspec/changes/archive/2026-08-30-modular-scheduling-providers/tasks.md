# Tasks: Modular Calendar & Meeting Providers

## 1. Schema & migrations

- [x] 1.1 Generate migration for `calendar_connections`: rename `google_email` → `provider_email`, drop unique `(tenant_id, user_id)`, add unique `(tenant_id, user_id, provider)`
- [x] 1.2 Generate migration for `interview_events`: rename `google_event_id` → `provider_event_id`, add `calendar_provider` and `calendar_owner_id`, backfill `calendar_provider = "google"` where `provider_event_id` not null, backfill `calendar_owner_id` from first `event_examiner`
- [x] 1.3 Update `CalendarConnection` schema/changeset: `provider_email`, uniqueness per `(tenant_id, user_id, provider)`
- [x] 1.4 Update `InterviewEvent` schema/changeset: `provider_event_id`, `calendar_provider`, `calendar_owner_id`

## 2. Provider abstractions

- [x] 2.1 Define `Treby.Calendar.Provider` (CalendarProvider behaviour): `fetch_busy/3`, `create_event/3`, `delete_event/2`
- [x] 2.2 Define `Treby.Calendar.MeetingProvider` behaviour: `create_meeting_link/1`
- [x] 2.3 Implement `Treby.Calendar.Providers.Treby`: internal busy from user's scheduled `interview_events` over a date range
- [x] 2.4 Implement `Treby.Calendar.Providers.Jitsi`: generates `https://meet.jit.si/treby-<tenant-slug>-<uuid>`
- [x] 2.5 Refactor `Treby.Calendar.Google` to implement the `CalendarProvider` behaviour and use `provider_email`

## 3. Resolver & Calendar facade

- [x] 3.1 Add provider-aware connection accessors in `Treby.Calendar`: `list_connections_for_user/1`, `connected?(user_id, provider)`, `get_connection(user_id, provider)`
- [x] 3.2 Add meeting resolver: `resolve_meeting(examiner_ids)` → `{:calendar_event, owner, :google_meet}` or `{:meeting_url, :jitsi}`
- [x] 3.3 Update `create_event_with_meet/3`, `delete_event/2`, `get_free_busy/3` in the facade to be provider-aware
- [x] 3.4 Remove now-obsolete `list_connected_users/1` usage from scheduling (replaced by availability-rules picker)

## 4. Distributed provider cache

- [x] 4.1 Implement `Treby.Availability.ProviderCache` (GenServer + ETS, `:global` name registration, standby failover)
- [x] 4.2 Cache external provider busy responses keyed `{provider, user_id, from, to}` with 5-minute TTL; never cache internal busy
- [x] 4.3 Remove `SlotCache` (slot_cache.ex) and its references
- [x] 4.4 Start `ProviderCache` under the application supervision tree

## 5. Availability aggregation

- [x] 5.1 Rewrite `Availability.get_busy_periods/3` to aggregate internal provider (always) + all connected external providers (via cache)
- [x] 5.2 Make fail-closed error handling consistent in `compute_slots/5` and `compute_overlapping_slots/6` (a connected provider error returns an error identifying the provider)
- [x] 5.3 Ensure internal busy is always read fresh from the DB (never cached)

## 6. Meeting resolution & booking flows

- [x] 6.1 Update `CandidatePortalLive.Schedule` booking: resolve meeting provider, create single Google event with all examiners + candidate or generate Jitsi link, store `provider_event_id`/`calendar_provider`/`calendar_owner_id`
- [x] 6.2 Update `ScheduleLive.Index` booking: same resolution and single-event-with-all-examiners behavior
- [x] 6.3 Fix `Interviews.cancel_interview/1`: delete external event using `calendar_owner_id` connection + `provider_event_id` (404 treated as success)
- [x] 6.4 Keep `video_conf_url` as the single meeting link used by confirmations and notifications

## 7. Internal scheduler & UI

- [x] 7.1 `ScheduleLive.Index`: list examiners with availability rules instead of Google-connected users, show per-examiner connection badge
- [x] 7.2 `SettingsLive.Calendar`: provider-aware copy ("Connected as ...", per-provider connect/disconnect)
- [x] 7.3 De-Google user-facing copy: "Join Google Meet" → provider-agnostic join button; "Video (Google Meet)" → "Video"
- [x] 7.4 Update candidate portal confirmation page to show the resolved meeting link label

## 8. Tests

- [x] 8.1 Update `calendar_test.exs` for `provider_email` and per-provider uniqueness
- [x] 8.2 Add internal-provider tests: existing interviews block slots; no external connection still yields internal-only slots
- [x] 8.3 Add multi-provider aggregation tests: busy from internal + external all excluded; provider error blocks slot computation
- [x] 8.4 Add meeting resolution tests: Google connected → single event with all examiners + candidate; no Google → Jitsi URL with expected format
- [x] 8.5 Add booking-flow tests: candidate portal and recruiter booking store provider fields and one meeting link
- [x] 8.6 Add cancel test: event deleted with calendar owner's token
- [x] 8.7 Add `ProviderCache` tests: cross-call cache hit, cache miss on TTL expiry, cache loss is safe
- [x] 8.8 Update existing availability/interview-scheduling/candidate-self-scheduling tests for new behavior

## 9. Verification

- [x] 9.1 Run `mix precommit` and fix all formatting, credo, sobelow, and test issues
- [x] 9.2 Update documentation site: regenerate screenshots (`node scripts/screenshots.mjs`) and update `site/features/` pages describing scheduling/calendar