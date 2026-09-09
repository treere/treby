# Job Analytics — Job Views

Understand how many people view each job posting and where they come from, so you can optimize visibility and conversion.

![Job Analytics](/screenshots/12-job-analytics.png)

## Where to Find It

- **Jobs list** (`Jobs`): each row shows a compact summary — total views and views in the last 7 days — or "No views yet" if the posting is new.
- **Job detail** (`Jobs → Detail`): above the title you'll see a badge with the same summary; in the top-right actions there's an **Analytics** button (chart icon) that opens the dedicated page.
- **Per-job analytics page** (`Jobs → Detail → Analytics`): accessible only to members of your team. If you try to open a job from another company, you'll see a "Not found" page.

## What the Analytics Page Shows

- **KPIs** at the top:
  - *Total views* and *Unique views* (same person counted once)
  - *Last 7 / 30 days* and *Daily average*
  - *Conversion* — % of views that become applications, with total applications and company average for comparison
- **Daily chart** — line chart with points for the last 7, 30, or 90 days (period selector at the top re-renders the chart). Days with no views appear as 0 on the line.
- **Monthly** — vertical bar chart for the last 12 months (from the first of the month) with value labels on each bar.
- **Traffic sources** — pie chart with legend showing where views come from: `utm_source` if present (e.g., LinkedIn, Indeed), otherwise referrer domain, otherwise "Direct". Percentage and count per slice.
- **View → Application funnel** — total views vs total applications and conversion rate; useful to tell whether a posting is seen but not compelling.

Charts keep their card height even when there is no data — you'll see a centered dashed placeholder with an icon and message instead of a collapsed card. If the posting is **closed**, the page remains accessible with historical charts but no longer records new views. If there are no views yet, you'll see "No views yet" at the top and placeholders in each chart card.

## How to Use It — Step by Step

1. Open `Jobs` and find the posting you want to analyze.
2. Go to the detail page and click **Analytics** in the top right.
3. Check the KPIs: many views but few applications → revisit title/description; few views → promote the public link more.
4. Pick a time range (7/30/90 days) to spot spikes after shares on LinkedIn or a newsletter.
5. Read the sources: if "Direct" dominates, add `?utm_source=linkedin` when you share the posting to track better.
6. Compare the conversion against the company average under the funnel to prioritize positions.

## Privacy

No plain IP address or personal visitor data is stored — only an anonymous session identifier, referrer domain, and `utm_source`. Views from your own team (while signed in) are not counted, nor are the most common bots.

## Useful Details

- Repeated views by the same person within about an hour count as one (anti-refresh).
- Direct public links (`/:company/careers/:id`) are counted even when the posting is "Private" but open; closed postings no longer increment the counter.
