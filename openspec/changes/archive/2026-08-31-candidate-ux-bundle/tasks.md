## 1. Resume upload feedback — Careers apply

- [x] 1.1 Render `@uploads.resume.entries` in `CareersLive.Apply` template: filename, human size, progress bar/percentage, remove/cancel control; render `upload_errors(@uploads.resume)` inline next to field (red text, `upload_error_to_string` via `gettext`).
- [x] 1.2 Guard submit in `handle_event("submit_application")`: if upload attempted (entries present) but has errors or `entry.progress < 100`/`!entry.done?`, keep form open, keep error visible, flash "Please fix the resume upload or remove the file to apply without a CV" and do not create application with `nil` resume.
- [x] 1.3 Disable Submit while upload in progress: show "Uploading..." + spinner, re-enable on `phx-upload-done`; add 44px touch targets and `id="resume-upload"` for tests.
- [x] 1.4 Expand `upload_error_to_string(:not_accepted)` copy to include helpful hint (convert photo to PDF / contact support) and keep i18n coverage (`en`/`it` via `gettext`).

## 2. Post-apply guidance & help contact

- [x] 2.1 Update apply thank-you state: replace generic copy with "Check your email — including spam — code valid 10 min" and label primary link "Track your application" → `/:tenant_slug/portal/login`.
- [x] 2.2 Add "Need help?" block on apply form and thank-you state, sourced from tenant settings (`logo/branding` or contact) with fallback to generic support, with `id="candidate-help"`.

## 3. OTP login — expiry / spam / cooldown hints

- [x] 3.1 Update `CandidatePortalLive.RequestLink` and `Verify` templates: add static helper "Code valid 10 min — check spam, sender noreply@treby.app", expiry note, and "Didn't receive it? Check spam or correct your email" link back to login (no enumeration).
- [x] 3.2 Surface 60s resend cooldown: show live countdown/disabled state on "Resend code" and surface `:rate_limited` as "Wait 60s before requesting another code" flash; verify in `CandidateOtpController` path.
- [x] 3.3 Keep anti-enumeration intact: always-success flash for unknown emails, but helper text remains static and does not reveal existence.

## 4. Candidate portal layout — mobile & language

- [x] 4.1 Mirror `Layouts.app` hamburger/drawer in `Layouts.candidate_portal`: overlay, drawer with all nav links + candidate name + Logout, `aria-label`, 44px targets, no overflow at 390px.
- [x] 4.2 Humanize status badge: map raw pipeline names to friendly labels (e.g., `new` → `Received`) alongside existing `candidate_step` sentence; increase close `✕` target to 44px with `aria-label="Close"`.

## 5. Tests

- [x] 5.1 Add LiveView tests for apply: selecting JPG shows `not_accepted` error; valid PDF shows filename/size; submit with failed upload does not create application; submit with no file still succeeds (`test/treby_web/live/careers_live/apply_upload_test.exs`).
- [x] 5.2 Add portal OTP tests: login/verify pages show expiry/spam helper, resend cooldown countdown/rate-limit flash, and typo-recovery link (`test/treby_web/live/candidate_portal_live/otp_ux_test.exs`).
- [x] 5.3 Add layout test: candidate portal at 390px has no horizontal overflow and drawer toggles (`test/treby_web/components/layouts_candidate_portal_test.exs`).

## 6. Specs & docs

- [x] 6.1 Update specs: sync `openspec/specs/file-upload/spec.md`, `candidate-otp-auth/spec.md`, `public-job-board/spec.md`, `candidate-portal-dashboard/spec.md` to match delta; add `openspec/specs/candidate-upload-feedback/spec.md` as new capability.
- [x] 6.2 Update user docs: edit `site/features/*.md` (careers/apply + candidate portal) in English only, update `site/features/index.md` and `site/.vitepress/config.ts` sidebar if new page, and regenerate screenshots via `node scripts/screenshots.mjs` (`site/.vitepress/dist`).

## 7. Final validation

- [x] 7.1 Run `mix precommit` and `openspec validate --strict` and fix issues
