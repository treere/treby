## Context

Treby uses a custom hand-rolled auth system (no `phx_gen_auth` or Pow). Passwords are bcrypt-hashed. Sessions are cookie-based via Plug. Email is sent via Swoosh (local adapter in dev, unconfigured in prod). The invite flow already demonstrates the pattern: generate a `:crypto.strong_rand_bytes(32)` token, store it in a database table with expiry, send an email with the link, validate on access.

The login page (`/login`) currently has no "Forgot Password" link. There is no mechanism to reset a lost password.

## Goals / Non-Goals

**Goals:**
- Allow users to request a password reset via email
- Send a time-limited, single-use reset link
- Let users set a new password through a secure form
- Add a "Forgot Password?" link to the login page
- Follow existing patterns (invite token flow) for consistency

**Non-Goals:**
- Email verification on registration (separate concern)
- Social login / SSO (separate concern)
- Password strength meter or confirmation field (separate concern — UX-007)
- Account lockout after failed reset attempts (out of scope)

## Decisions

### 1. Token storage: new `password_reset_tokens` table
**Decision:** Create a dedicated table rather than reusing invites or adding a column to users.
**Why:** Follows the existing `invite_tokens` pattern. Keeps token lifecycle isolated. Supports multiple concurrent reset requests (last-one-wins or all-valid). Token is stored as a SHA-256 hash (not plaintext) to limit damage if the database is compromised.
**Alternative considered:** Store token directly on users table — rejected because it conflates concerns and makes token lifecycle harder to manage.

### 2. Token format: 32-byte random, URL-safe base64
**Decision:** Use `:crypto.strong_rand_bytes(32) |> Base.url_encode64(padding: false)` — identical to the invite token pattern.
**Why:** Proven pattern in this codebase. 256 bits of entropy is more than sufficient. URL-safe encoding avoids issues in email clients.

### 3. Token expiry: 1 hour
**Decision:** Tokens expire after 1 hour.
**Why:** Balances security (short window) with usability (user may not check email immediately). The invite flow uses 7 days, but password resets are higher-risk and should be shorter-lived.

### 4. Token hashing: SHA-256 before storage
**Decision:** Store `sha256(token)` in the database, not the raw token.
**Why:** If the database is compromised, attackers cannot use the tokens directly. The raw token is only in the email link. This is a standard security practice.
**Alternative considered:** Store raw token (simpler) — rejected because it exposes valid tokens in the DB.

### 5. Controller-based (not LiveView) for reset pages
**Decision:** Use regular Phoenix controllers for `/reset-password` and `/reset-password/:token`, matching the existing login and registration pattern.
**Why:** These are simple forms with no real-time interaction. Controllers are already used for all auth pages in this project. No reason to introduce LiveView for a two-field form.

### 6. Email via existing Swoosh infrastructure
**Decision:** Create a `PasswordResetEmail` module similar to `InvitesEmail`, using `Treby.Mailer.deliver/1`.
**Why:** Consistent with how all other emails are sent. Reuses existing infrastructure. Works with local adapter in dev for testing.

### 7. Token invalidation: mark as used on successful reset
**Decision:** Set `used_at` timestamp when the token is consumed. Reject tokens that are already used.
**Why:** Prevents replay attacks. The token table also gets cleaned up periodically (tokens older than 24 hours can be pruned).

### 8. User enumeration prevention
**Decision:** Always show "If an account exists with that email, you'll receive a reset link" — regardless of whether the email exists.
**Why:** Prevents attackers from discovering valid email addresses. Standard security practice for auth flows.

## Risks / Trade-offs

- **[Risk] Token table grows unbounded** → Mitigation: Add a periodic cleanup task (delete tokens older than 24 hours). Can be a simple mix task or scheduled job.
- **[Risk] Email not configured in production** → Mitigation: The reset flow will fail silently (Swoosh returns error). The user sees the same success message regardless. This is acceptable because email configuration is a separate infrastructure concern.
- **[Race condition] Multiple rapid reset requests** → Mitigation: Each request generates a new token. Previous tokens remain valid until used or expired. This is acceptable — worst case the user has multiple valid links.
- **[Risk] Token in URL logged by proxies/browsers** → Mitigation: Tokens are single-use and short-lived (1 hour). The risk window is small.
