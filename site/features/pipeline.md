
# Kanban Pipeline

The pipeline is the heart of Treby. It's a drag-and-drop Kanban board where you move candidates through hiring stages.

![Pipeline Kanban](/screenshots/07-pipeline-kanban.png)

## Job Page Workspace

The job detail page is the primary daily workspace for a position. Instead of a flat, read-only list, candidates are **grouped by pipeline stage** in columns, so you can see exactly who is where at a glance.

- **Inline stage changes** — each candidate card has a "Move to…" dropdown to change their stage without leaving the page
- **Review toggle** — mark applications as reviewed (NEW badge) directly from the card
- **Reject** — reject candidates with a motivation straight from the job page
- **Contextual cards** — DUPLICATE and "Also in N other positions" badges, upcoming interview chips, and resume links
- **Search** — filter the job's candidates by name or email
- **Candidate profiles** — clicking a candidate opens their profile, and the back link returns you to the job (context is preserved)

### Read-only Pipeline Overview

The pipeline section on the job page is **read-only by default**: it lists the stages in order with their color, type, candidate count, and the names of the assigned examiners, reviewers, and advancers. Admins can open the editor with the **Manage Pipeline** button, keeping configuration out of the daily view.

## How it works

- **Stages** are configurable: add, remove, reorder, and color-code
- **Cards** show candidate name, email, and contextual indicators
- **Drag and drop** moves candidates between stages (powered by Sortable.js)
- **Real-time sync**: all connected users see moves instantly via Phoenix PubSub
- **Counts** per stage header show how many candidates are in each

## Card Indicators

- **"Also in N other positions"** — shown when a candidate has applications in other pipelines, so you can spot candidates interviewing for multiple roles
- **DUPLICATE** badge — shown when the same candidate has a second application to this job
- **NEW** badge — shown until an application has been reviewed
- **Actionable blockers** — on interview-type stages, cards show exactly what stands between the candidate and the next stage, naming the pending examiners ("Scorecard missing: Caio") or an un-completed interview, instead of an opaque count
- **Ready to advance** — a green indicator replaces the blockers once the interview is completed and all scorecards are in

## Role-Based Stage Access

Each pipeline stage can have three types of role assignments:

| Role | Who | What they can do |
|---|---|---|
| **Examiner** | Interviewers assigned to the stage | Conduct interviews, submit scorecards |
| **Reviewer** | Team members reviewing applications | Review applications and provide feedback |
| **Advancer** | Decision-makers for the stage | Advance or reject candidates from the stage |

Only assigned **advancers** can move candidates forward or reject them. Non-advancers can view the pipeline but cannot advance or reject candidates.

### Advancement Gating

For interview-type stages, advancement is gated on both the interview being marked **completed** and all scorecards being submitted:

- The **Advance** button is only visible to advancers
- **Mark as completed** on the card (with a confirmation dialog) explicitly records that the interview happened
- The **Advance** button stays disabled until the interview is completed and every examiner has submitted their scorecard
- Drag-and-drop moves to interview stages also require the user to be an advancer

Examiners can open the scorecard form directly from a candidate's card instead of hunting for the interviews page.

### Rejection

Advancers can reject candidates directly from the pipeline board:

1. Click **Reject** on a candidate card
2. Enter a rejection motivation (required)
3. The candidate moves to the "Rejected" stage

Use the **Rejected** filter button to view only rejected candidates.

## Pipeline Stages

The default pipeline has 6 stages:

| Stage | Purpose |
|---|---|
| New | Fresh applications from career page or manual add |
| Screen | Quick review of qualifications |
| Phone Screen | Initial phone conversation |
| Interview | In-depth technical/cultural interviews |
| Offer | Offer negotiation stage |
| Hired | Successfully hired |

You can customize these in **Settings → Pipeline Stages**: change names, colors, or create entirely new stages.

## Pipeline Templates

Create reusable pipeline configurations to avoid repetitive setup for similar positions.

- **Create templates** from scratch in **Settings → Pipeline Templates**
- **Save as Template** from any existing pipeline (copies all stages and role assignments)
- **Clone when creating a job** — select a template in the job creation form to start with a pre-configured pipeline
- Templates copy all role assignments (examiners, reviewers, advancers), min_examiners settings, and scorecard template associations

## Usage

1. Open any job from the **Jobs** page — the job detail page is your workspace: candidates grouped by stage, inline moves, review, and reject. There is no separate top-level Pipeline page.
2. Click the **View Pipeline** link on the job page for the advanced board (drag-and-drop, bulk actions, scheduling, scorecards)
3. Click and drag a candidate card to a new stage (or use the Advance button on interview stages)
4. All team members see the update in real time
5. Click a candidate's name on a card to open their full profile
