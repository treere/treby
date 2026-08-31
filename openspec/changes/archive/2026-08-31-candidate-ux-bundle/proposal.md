## Why

Live Playwright testing as a low-PC candidate (390px phone, picking a JPG "photo of CV") proved the biggest drop-off is silent and invisible: after choosing a resume file, no filename or progress appears; picking a JPG shows no error; submitting still shows "Thank you!" but DB stores `resume_url=nil` (recruiter receives an application with no CV). Post-apply, the thank-you screen, OTP login (no spam/expiry hint, anti-enumeration masks typos), and portal (overflowed nav, pipeline jargon, no help contact) compound anxiety and abandonment for non-technical candidates.

## What Changes

- **Resume upload feedback & guardrails**: render selected file name/size, live progress, success/error states (`File type not accepted`, `Too large (max 10MB)`) inline from `upload_errors`, disable/replace submit with spinner until upload completes, and reject submit when a file was picked but failed validation (no silent `nil` resume).
- **Post-apply clarity**: replace "Access Your Portal" generic copy with human steps ("Check your email — including spam — code valid 10 min") and add a visible help/contact fallback on apply/thank-you.
- **OTP UX**: surface expiry (10 min), 60s resend cooldown, and "check spam folder" hint on `portal/login` → `portal/verify`; keep anti-enumeration but surface "didn't receive it? correct your email" path.
- **Candidate portal polish**: fix mobile nav overflow for `candidate_portal` layout (hamburger/drawer), increase close-target size, clarify statuses in human language alongside pipeline badge, and keep "Where you are" guidance.
- **Docs & screenshots**: update `site/features` user manual and regenerate screenshots with `node scripts/screenshots.mjs`.

## Capabilities

### New Capabilities
- `candidate-upload-feedback`: candidate-visible resume upload states (filename, progress, errors) with guard against nil-resume submit when file was attempted.

### Modified Capabilities
- `public-job-board`: add help/contact and human post-apply guidance to public career/apply flow.
- `candidate-otp-auth`: add expiry/cooldown/spam hints and typo-recovery path to OTP login without weakening anti-enumeration.
- `candidate-portal-dashboard`: mobile nav and humanized status language fixes for candidate portal.
- `file-upload`: require visible feedback and rejection messaging for candidate resume uploads (was previously present but not surfaced).

## Impact

- Affected modules: `lib/treby_web/live/careers_live/apply.ex`, `lib/treby_web/live/candidate_portal_live/request_link.ex`, `verify.ex`, `index.ex`, `lib/treby_web/components/layouts.ex` (candidate_portal), `lib/treby/candidate_portal/candidate_portal.ex`, `lib/treby_web/controllers/candidate_otp_controller.ex`, `site/features/**`.
- Dependencies: no new deps; uses existing `Phoenix.LiveView` uploads, `Treby.Uploads` (S3/RustFS). No migrations (behavioral/UI only).
- APIs: public career apply and candidate portal OTP flows change copy/behavior but keep routes (`/:tenant_slug/careers/:job_id/apply`, `/:tenant_slug/portal/{login,verify}`, `/:tenant_slug/portal`) unchanged.
