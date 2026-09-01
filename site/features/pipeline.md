# Kanban Pipeline

The pipeline is the heart of Treby: a board where you move candidates through hiring stages.

![Pipeline Kanban](/screenshots/07-pipeline-kanban.png)

## Jobs Overview

![Jobs List](/screenshots/05-jobs-list.png)

The **Jobs** page lists every open position with salary, visibility (Public/Private), view counts, and candidate totals — create new jobs from here.

## Job Detail Page

![Job Detail](/screenshots/22-job-detail.png)

The job detail page is your daily workspace: candidates are **grouped by stage** into columns so you can see at a glance who is where.

- **Quick stage change** — each card has a "Move to…" menu to change stage without leaving the page
- **Read status** — mark applications as read (NEW badge) directly from the card
- **Reject** — reject with a reason directly from the page
- **Contextual badges** — DUPLICATE badge and "Also in N other positions", chips for upcoming interviews and CV link
- **Search** — filter candidates for this job by name or email
- **Profiles** — click a name to open the profile, with back navigation to the originating job

### Pipeline Overview

The pipeline section on the job page is read-only by default: it shows stages in order with color, type, candidate count, and names of assigned examiners, reviewers, and advancers. Admins can open the editor with the **Manage pipeline** button.

## How It Works

- **Configurable stages**: add, remove, reorder, and recolor
- **Cards** with name, email, and contextual indicators
- **Drag & drop** to move candidates between stages
- **Real-time sync**: every team member sees moves instantly
- **Counters** in each column header

## Card Indicators

- **"Also in N other positions"** — when a candidate has applications in other jobs
- **DUPLICATE badge** — when the same candidate has two applications for the same job
- **NEW badge** — until the application has been marked as read
- **Blockers** — in interview stages you see what is missing to advance, with names of pending examiners ("Missing scorecard: John") or interview not yet completed
- **Ready to advance** — green indicator when the interview is completed and all scorecards are in

## Per-Stage Permissions

Each stage can have three assignments:

| Role | Who | What they can do |
|---|---|---|
| **Examiner** | Runs the interviews | Conducts interviews and fills out scorecards |
| **Reviewer** | Reviews applications | Reviews and leaves feedback |
| **Advancer** | Decides | Advances or rejects candidates in that stage |

Only advancers can advance or reject. Others can view the pipeline but cannot make advancement decisions.

### Advancement Gating

In interview stages, advancing requires both the interview marked as **completed** and all scorecards submitted:

- The **Advance** button is visible only to advancers
- **Mark as completed** on the card requires confirmation
- The button stays disabled until a scorecard is missing or the interview is not completed
- Drag & drop to the next stage also requires advancer permission

Examiners can open the scorecard form directly from the candidate card.

### Rejection

Advancers can reject from the board:

1. Click **Reject** on the card
2. Enter a reason (required)
3. The candidate moves to the "Rejected" stage

Use the **Rejected** filter to see only rejected candidates.

## Default Stages

The default pipeline has 7 stages:

| Stage | Color | Purpose |
|---|---|---|
| New | green | New applications from the career page, manual creation, or CSV import |
| Screening | blue | Initial requirements screening |
| Phone Screen | purple | First phone contact |
| Interview | orange | In-depth interviews — with scorecards and advancement gating |
| Offer | pink | Offer negotiation |
| Hired | light green | Hiring completed — used for average time metrics |
| Rejected | red | Candidates not selected (requires a reason) |

You can customize them in **Settings → Pipeline** / **Settings → Pipeline Stages**: names, colors, order, stage type, minimum number of examiners and linked scorecard template, plus managing multiple pipelines per company.

![Settings — Pipeline](/screenshots/12-settings-pipeline.png)

![Pipeline Stages](/screenshots/40-pipeline-stages.png)

## Pipeline Templates

Create reusable configurations so you don't repeat the same setup for similar jobs.

- **Create templates** from scratch in **Settings → Pipeline Templates**
- **Save as template** from an existing pipeline (copies stages and assignments)
- **Use a template** when creating a new job
- Templates copy assignments, minimum examiner count, and scorecard templates

## Tips for Getting the Most Out of It

1. Open a job from the **Jobs** page — the detail page is your workspace with grouped candidates, quick moves, read status, and rejections
2. Click **View pipeline** for the advanced board with drag & drop, bulk actions, scheduling, and scorecards
3. Drag a card to another column (or use the Advance button in interview stages)
4. All team members see the update in real time
5. Click a candidate name to open the full profile
