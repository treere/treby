## Context

Current candidate journey (proven via Playwright on 390px):
- `CareersLive.Apply` mounts `allow_upload(:resume, accept: ~w(.pdf .doc .docx), max_file_size: 10_000_000, max_entries: 1)` but template never renders `@uploads.resume.entries` or `upload_errors` visibly — after picking a file, body text remains unchanged, `data-phx-active-refs=""`. Picking a JPG (classic low-PC mistake: photo of CV) sets `files.length=1` / `fakepath` yet no error appears, and submit still succeeds with `resume_url=nil` (`Treby.Uploads.upload_file` fallback). Recruiter receives application without CV; candidate sees "Thank you!" and assumes success.
- Thank-you → portal handoff uses generic "Access Your Portal" copy, no spam/expiry hint. OTP login at `CandidatePortalLive.RequestLink/Verify` + `CandidateOtpController` always flashes "Check your email" (anti-enumeration), with 10-min validity and 60s resend cooldown enforced in `CandidatePortal.generate_otp` but never surfaced in UI. No typo-recovery path.
- `Layouts.candidate_portal` has no mobile drawer; at 390px `Logout` overflows (`right 402 > viewport`), unlike `Layouts.app` which has a hamburger+drawer. Status badge in `CandidatePortalLive.Index` shows raw pipeline names (`New`) with minimal human guidance.

Stakeholders: candidates (especially low digital literacy, mobile-first), recruiters (need complete applications), support.

## Goals / Non-Goals

**Goals:**
- Make resume selection visibly acknowledged (filename/size, progress, done/error) and prevent silent nil-resume when user attempted a file.
- Surface expiry/cooldown/spam guidance on OTP flow without weakening anti-enumeration.
- Fix mobile usability of candidate portal layout and humanize status language.
- Keep behavior tenant-isolated, accessible (44px touch targets, clear labels), and i18n-ready via `gettext`.

**Non-Goals:**
- Changing auth model (keep OTP, no password).
- Changing S3/upload backend (keep `Treby.Uploads` / ExAWS / RustFS).
- Adding new file types beyond PDF/DOC/DOCX or increasing 10MB limit.
- Full redesign of career pages.

## Decisions

**D1 — Use native LiveView upload rendering (entries + errors) vs custom JS dropzone**
- Choose LiveView's `for entry <- @uploads.resume.entries` + `upload_errors/1` with progress (`entry.progress`) and cancel, styled with Tailwind (no new deps). Alternatives (Sortable.js / custom dropzone) rejected: adds JS complexity, diverges from existing `allow_upload` contract; native approach is enough to prove filename feedback.
- Rationale: stays within `phx-hook="Phoenix.LiveFileUpload"` lifecycle, works on mobile file picker, minimal risk.

**D2 — Guard submit: if upload attempted but failed/incomplete, block and surface error**
- On `handle_event("submit_application")`, inspect `uploaded_entries` vs `upload_errors`. If errors present or `entry` exists but `entry.done?` false, flash inline error and refuse silent nil. Only when no file was picked should `resume_url=nil` be allowed.
- Alternative (auto-reject nil resume) rejected: some tenants intentionally allow no-CV applications.

**D3 — OTP hints without leaking existence**
- Keep controller's always-success flash, but add *static* helper text on both `RequestLink` and `Verify` ("Code valid 10 min, check spam, sender noreply@treby.app") and render resend cooldown countdown client-side (LiveView `phx-mounted` timer or JS). On verify, add "Didn't receive it? Check spam or correct email" link back to `/portal/login` with no enumeration via existence check.
- Alternative (per-email "not found" error) rejected for privacy.

**D4 — Portal layout parity with app layout**
- Mirror `Layouts.app` mobile drawer pattern (hamburger, `phx-click={JS.toggle_class...}`, overlay) for `Layouts.candidate_portal`. Keep desktop nav unchanged. Ensure Logout and candidate name remain reachable at 390px.
- Humanize status: keep badge but augment with `candidate_step` human sentence already present, and map raw stage names to friendly labels (e.g., `new` → `Received`).

**Provider / caching / error handling**
- No new provider abstraction. Upload: fail-closed on validation (show error, don't create application with nil if file attempted). Email OTP: fail-closed on rate-limit (`:rate_limited`) → flash "Wait 60s before requesting another code" (already in context, now surfaced). Calendar/meeting not touched.

## Risks / Trade-offs

- **LiveView upload race on slow 4G** → Mitigation: disable Submit, show spinner while `entry.progress < 100`, re-enable on `phx-upload-done`. Tested via manual slow throttle.
- **JPG photo CV users still blocked** → Mitigation: clear error copy suggests "Take a photo then convert to PDF — or ask for help at [contact]" and allow submit without CV fallback if they remove file.
- **Anti-enumeration tension** → Mitigation: generic helper text doesn't reveal existence; cooldown hint is static, not per-email.
- **Drawer a11y** → Mitigation: replicate existing `Layouts.app` focus management and `aria-label`.

## Migration Plan

1. Deploy UI-only — no migration. Old applications with `resume_url=nil` unaffected.
2. Rollback: revert templates/layout; no data migration needed.
3. Docs: update `site/features` pages and run `node scripts/screenshots.mjs` to regenerate.

## Open Questions

- Contact fallback email/phone — per-tenant `settings` or global fallback? Decision: use tenant branding settings if present, else generic support link.
- Should we persist "cv_missing_but_attempted" flag for recruiter visibility? Out of scope for this bundle; follow-up if needed.
