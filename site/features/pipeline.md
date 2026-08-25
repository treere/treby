
# Kanban Pipeline

The pipeline is the heart of Treby. It's a drag-and-drop Kanban board where you move candidates through hiring stages.

![Pipeline Kanban](/screenshots/07-pipeline-kanban.png)

## How it works

- **Stages** are configurable: add, remove, reorder, and color-code
- **Cards** show candidate name, email, and contextual indicators
- **Drag and drop** moves candidates between stages (powered by Sortable.js)
- **Real-time sync**: all connected users see moves instantly via Phoenix PubSub
- **Counts** per stage header show how many candidates are in each

## Card Indicators

- **"Also in N other positions"** — shown when a candidate has applications in other pipelines, so you can spot candidates interviewing for multiple roles
- **DUPLICATE APP** badge — shown when the same candidate has a second application to this job
- **NEW** badge — shown until an application has been reviewed
- **Scorecard progress** — on interview-type stages, shows how many examiners have submitted their scorecards (e.g., "2/3 scorecards")

## Role-Based Stage Access

Each pipeline stage can have three types of role assignments:

| Role | Who | What they can do |
|---|---|---|
| **Examiner** | Interviewers assigned to the stage | Conduct interviews, submit scorecards |
| **Reviewer** | Team members reviewing applications | Review applications and provide feedback |
| **Advancer** | Decision-makers for the stage | Advance or reject candidates from the stage |

Only assigned **advancers** can move candidates forward or reject them. Non-advancers can view the pipeline but cannot advance or reject candidates.

### Advancement Gating

For interview-type stages, advancement is gated on scorecard completion:

- The **Advance** button is only visible to advancers
- It is disabled until all examiners have submitted their scorecards
- Drag-and-drop moves to interview stages also require the user to be an advancer

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

1. Open any job from the **Jobs** page and click the pipeline link — there is no separate top-level Pipeline page
2. Click and drag a candidate card to a new stage (or use the Advance button on interview stages)
3. All team members see the update in real time
4. Click a candidate's name on a card to open their full profile
