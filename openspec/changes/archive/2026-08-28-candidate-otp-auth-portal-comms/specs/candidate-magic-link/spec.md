## REMOVED Requirements

### Requirement: Candidate requests magic link
**Reason**: Replaced by the OTP login flow (see `candidate-otp-auth`).
**Migration**: Candidates authenticate by requesting a one-time code by email at `/:tenant_slug/portal/login` and verifying it at `/:tenant_slug/portal/verify`.

### Requirement: Candidate authenticates via magic link
**Reason**: Replaced by OTP verification; the magic link route `/:tenant_slug/c/:token` is removed.
**Migration**: Use the OTP flow: request a code, receive it by email, enter it on the verification page.

### Requirement: Candidate session management
**Reason**: Session handling now lives in `candidate-otp-auth` with a limited lifetime and explicit logout.
**Migration**: Sessions are created after OTP verification with a configurable expiry (default 4 hours); see `candidate-otp-auth`.

### Requirement: Magic link email content
**Reason**: The magic link email is replaced by the OTP email.
**Migration**: Candidates receive a code email (subject "Your login code") with a link to the verification page.