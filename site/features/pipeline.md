# Kanban Pipeline

The pipeline is the heart of Treby: a board where you move candidates through hiring stages.

![Pipeline Kanban](/screenshots/07-pipeline-kanban.png)

## Jobs Overview

![Jobs List](/screenshots/05-jobs-list.png)

The **Jobs** page lists every open position with salary, visibility (Public/Private), view counts, and candidate totals. The list shows 25 jobs per page with a pager at the bottom; the Open/Closed filter resets to page 1. Click **New Job** to create a position.

### Creating a Job — Dedicated Page with Live Preview

![Create Job Preview](/screenshots/05-jobs-list.png)

Creating a job happens on a dedicated page at **Jobs → New Job** (`/app/jobs/new`). The page is split into two:

- **Left: Form** — title, description (Markdown), salary range, location, employment type, workplace type, pipeline, and any tenant custom fields. A **Status** control sets **Open** (active) or **Closed** (hidden from all public boards). A **Visibility** control sets **Public** (appears on `/careers` and `/:tenant_slug/careers` when open) or **Private** (only via direct link). Visibility defaults to **Public** and is disabled with a hint when Status is **Closed** — a closed job cannot be public.
- **Right: Live public preview** — the job as candidates will see it on the career page: title, company name, location/badges, salary, posted date, and Markdown-rendered description inside a card that matches the public detail page. It updates on every change without saving, so you can check formatting before publishing. When Status is **Closed** the preview shows a *“This position is closed”* banner; when Visibility is **Private** it shows a *“Private — only via direct link”* notice.

Fill the form and click **Create job** — you are redirected to the job detail page. Use **Cancel** to return to the listing without creating. The description hint *Supports Markdown formatting* is shown under the textarea. All fields are scoped to your company (tenant): pipelines and custom fields are filtered to the current company.

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

The pipeline section on the job page is read-only by default: it shows stages in order with color, type, candidate count, and who is responsible for each stage.

- **Owner line** — every stage always shows responsibility. If specific people are assigned you see `Examiner: Name`, `Reviewer: Name`, `Advancer: Name`; if no one is assigned you see `Responsible: Everyone` — meaning anyone on the team can act in that stage.
- **Roles legend** — a one-line legend above the list explains `Examiner — runs interviews · Reviewer — reviews · Advancer — moves candidates`.
- **How it works** — below the title a short note explains that stages are ordered, interview stages require an Advancer to move candidates, and editing stages here creates a pipeline copy for this job only (other jobs are not affected). Click `How the pipeline works` to see more.

Admins can open the editor with the **Manage pipeline** button — the editor shows the same owner line for each stage, so the overview and the editor never contradict.

## How It Works

- **Configurable stages**: add, remove, reorder, and recolor
- **Cards** with name, email, and contextual indicators
- **Drag & drop** to move candidates between stages
- **Real-time sync**: every team member sees moves instantly
- **Counters** in each column header
- **Paging**: the board shows 25 applications per page with a pager below the columns; drag & drop and bulk actions apply to the visible page

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

On the job page each stage shows full role labels (`Examiner:`, `Reviewer:`, `Advancer:`) — not single letters — and when no one is assigned it shows `Responsible: Everyone`. The legend above the pipeline explains the three roles.

Only Advancers (and admins) can advance or reject in interview stages; in other stages anyone can move. Others can view the pipeline but cannot make advancement decisions.

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

## Reusing Pipelines

Each job gets its own pipeline, so you can customize stages per position without affecting other jobs.

- **Duplicate** a pipeline in **Settings → Pipeline** to reuse its stages and assignments as a starting point
- Editing stages from a job page automatically detaches a private copy for that job when the pipeline is shared

## Tips for Getting the Most Out of It

1. Open a job from the **Jobs** page — the detail page is your workspace with grouped candidates, quick moves, read status, and rejections
2. Click **View pipeline** for the advanced board with drag & drop, bulk actions, scheduling, and scorecards
3. Drag a card to another column (or use the Advance button in interview stages)
4. All team members see the update in real time
5. Click a candidate name to open the full profile
