
# Kanban Pipeline

The pipeline is the heart of Treby. It's a drag-and-drop Kanban board where you move candidates through hiring stages.

![Pipeline Kanban](/screenshots/07-pipeline-kanban.png)

## How it works

- **Stages** are configurable: add, remove, reorder, and color-code
- **Cards** show candidate name and email
- **Drag and drop** moves candidates between stages (powered by Sortable.js)
- **Real-time sync**: all connected users see moves instantly via Phoenix PubSub
- **Counts** per stage header show how many candidates are in each

## Card Indicators

- **"Also in N other positions"** — shown when a candidate has applications in other pipelines, so you can spot candidates interviewing for multiple roles
- **DUPLICATE APP** badge — shown when the same candidate has a second application to this job
- **NEW** badge — shown until an application has been reviewed

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

## Usage

1. Open any job from the **Jobs** page and click the pipeline link — there is no separate top-level Pipeline page
2. Click and drag a candidate card to a new stage
3. All team members see the update in real time
4. Click a candidate's name on a card to open their full profile
