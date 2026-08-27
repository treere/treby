# Candidate Management

A central database of all candidates across all jobs, with full application history.

![Candidates List](/screenshots/08-candidates-list.png)

## Candidates List

The candidates page shows:
- Name (links to detail page)
- Email
- Phone
- Number of applications
- **Duplicates** button with a live count, linking to the merge center
- Bulk actions, including **Merge into one** with a primary picker
- Delete action

## Adding Candidates

![Add Candidate Form](/screenshots/21-add-candidate-form.png)

Click **+ Add Candidate** to manually add a candidate with:
- Name, email, phone, LinkedIn URL
- Custom candidate fields (if configured)

## Candidate Detail

![Candidate Detail](/screenshots/09-candidate-detail.png)

Each candidate detail page shows:
- Contact information (name, email, phone, LinkedIn)
- All applications with job title and current pipeline stage
- **Progress panel** — the current stage, any blockers (named pending examiners, un-completed interviews), and the next actions for the team
- **Complete interview + Scorecard actions** — mark a scheduled interview as completed and open the scorecard form directly from the page
- **Concurrent-application visibility** — when a candidate is in more than one pipeline, each application shows "Also in N other positions"
- **Duplicate-application badges** when a candidate applied to the same job more than once
- Per-application **anagrafica** — the name, email, and phone captured at apply time ("as submitted"), shown when it differs from the candidate's current master data
- Notes and feedback per application with star ratings
- Custom fields
- **Undo merge** action when the profile was merged into another

## Duplicate Detection & Merging

![Merge Center](/screenshots/24-merge-center.png)

Treby automatically detects candidates that may be the same person using:
- **Exact email match** — high confidence, safe to auto-merge
- **Phone + name match** — high confidence
- **Name + email match** — medium confidence

The **Merge Duplicates** center (`/app/candidates/merge`) lists these groups with:
- Confidence and matching-signal badges
- Side-by-side profiles (name, email, phone, LinkedIn, application count)
- A primary-profile selector (radio buttons)
- **Merge** and **Dismiss** actions per group

Merging reassigns all applications, email threads, and activity to the primary profile; the absorbed profiles are archived and shown as a merged badge. Merges are recorded and can be undone.

Dismissed suggestions stay hidden across reloads for the whole workspace — the duplicates badge on the candidates list only counts undismissed groups.

## Undo Merge

When a candidate profile has been absorbed into another, its page redirects to the primary profile with a notice. The primary profile shows a **Undo merge** action that restores all applications, threads, and activity to the absorbed candidate.

## Notes & Feedback

![Add Note Form](/screenshots/20-add-note-form.png)

Team members can add notes to any application:
- **Type** — Note or Interview Feedback
- **Rating** — optional 1–5 star rating
- **Content** — free-text feedback

Authors can delete their own notes.

## Candidate Portal

When the portal is enabled, candidates get a self-service dashboard accessible via magic link — no account or password needed.

### How It Works

- **Magic link auth**: Candidates enter their email on the login page and receive a one-time login link (valid 15 minutes)
- **Portal dashboard**: Shows all applications with current stage, applied date, and status
- **Application details**: Click any application to see job title, stage, applied date and source, plus a timeline of status changes
- **Progress panel**: Each application shows where the candidate is ("Your application is under review", "You have an interview scheduled") in clear, candidate-friendly language — no internal roles or blocker jargon
- **Pending actions**: If the recruiter is waiting on the candidate (e.g. a request for more info), the panel highlights it and links straight to the conversation
- **Active conversations**: The application detail embeds the latest conversation thread with a reply form, so candidates can respond without leaving the page
- **Conversations**: In-platform messaging between candidates and recruiters, created automatically at lifecycle moments (application, stage changes, rejection)
- **Notifications**: Candidates receive short "ping" emails linking to the portal instead of full email bodies; they can configure which events trigger pings

### Recruiter Side

On the candidate detail page, recruiters see a **Conversations** tab with:
- All portal conversations for that candidate
- Ability to start new conversations
- Structured message types: text, status update, interview invite, rejection, request info
- Read/unread tracking per message

### Rejection Flow

When a candidate is rejected (via the pipeline or candidate detail page), recruiters can:
- Select a structured rejection reason
- Optionally write feedback visible to the candidate
- The candidate receives a ping email and can view the rejection in their portal

### Notification Preferences

Candidates can toggle which events generate pings in their portal settings:
- Application updates (stage changes, rejections, offers)
- Interview invitations
- New messages from recruiters

Default: all enabled. A separate "important only" flag filters out non-critical pings.
