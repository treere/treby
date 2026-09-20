# Candidate Portal

Candidates have a personal portal where they track their applications without needing a password — just a 6-digit code.

![Portal Login](/screenshots/26-portal-login.png)

![Portal Code Verification](/screenshots/42-portal-verify.png)

## Code-Based Access

- Candidates enter their email on the portal login page
- They receive a **6-digit code** by email, valid for **10 minutes** and single-use, from `noreply@treby.app` — the login screens remind you to *"check spam folder"* and that *"you can request a new code after 60 seconds"*
- On the code screen you see **Code valid 10 minutes — check spam folder, sender noreply@treby.app**, plus **Didn't receive it? Check spam or correct your email** with a **Correct email** link back to login (no account enumeration)
- If you request a code too quickly, you see *"Wait 60 seconds before requesting another code"*; the **Resend code** button notes the 60-second cooldown
- After **5 wrong codes** the code is locked and the page tells you to request a new one
- They enter the code and access the portal for a few hours, then can sign out explicitly

Candidates never get a password; team access and candidate access are completely separate.

## What Candidates Can Do

| Page | What they see |
|---|---|
| **Dashboard** | At a glance: how many applications you sent, how many unread messages you have, and whether any action is pending — plus a quick **company card** with logo, name and help contact when configured |
| **Overview** | Each application card shows **company and position**, location and work-type badges when available, **human-friendly labels** (e.g., *Received* instead of *new*), stage badge, applied date, an **unread indicator** and a one-line preview of the latest recruiter message |
| **Messages** | Conversations for each application (two-way messaging with recruiters) — unread conversations are also surfaced on the Dashboard |
| **Interviews** | Self-scheduling — pick an available interview slot (see [Interviews](/features/interview-scheduling)) |
| **Settings** | Notification preferences — which events generate an email and the "important only" filter |

The portal header has explicit navigation **Dashboard → Messages → Schedule → Settings** (plus the company brand that also goes to the Dashboard) on desktop, and the same items plus the brand in the **hamburger → drawer** on mobile. The drawer uses an overlay, 44px touch targets and no horizontal overflow — the same pattern as the main app. Application cards show a human-readable badge and the detail pane's close button is 44px with an *aria-label*.

Each new application automatically creates a welcome conversation. Stage moves, messages, interview updates, and rejections are posted to the same conversation and, when configured, generate a short email notification with a link to the portal.

## Portal Messages

- Each application has its own conversation
- Recruiters write from the pipeline card, the candidate profile, or the message queue; candidates reply from **Messages** in the portal
- Messages can be sent immediately or scheduled (see [Message Scheduler](/features/message-scheduler))
- Message templates support variables such as candidate name, job title, company name, and stage name

## Privacy and Notifications

- All real content lives in the portal: email only contains a short notification with a link, never the message body
- Candidates choose in portal **Settings** which events generate notifications
- The portal session is scoped to a single company and expires after a few hours
- Each candidate sees only their own applications: even if someone guesses a URL, the portal shows only their own data and, if the company in the URL does not match, automatically redirects to their own portal
