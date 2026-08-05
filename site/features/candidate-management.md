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
