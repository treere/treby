## 1. Job Detail — Candidates Section

- [x] 1.1 In `JobsLive.Show.mount/3`, fetch applications using `Pipeline.list_applications_for_job(job.id)` and assign as `:applications`
- [x] 1.2 In `JobsLive.Show.render/1`, add a "Candidates" section below the description/details grid showing each application as a card with: candidate name, email, pipeline stage badge (colored with `stage.color`), and application date
- [x] 1.3 Handle empty state: show "No candidates yet" message when `@applications` is empty

## 2. Job Detail — Pipeline Link & Icons

- [x] 2.1 Add a "View Pipeline" `<.link>` with a `hero-arrow-top-right-on-square` icon in the job detail header, navigating to `~p"/app/pipeline/#{@job.id}"`
- [x] 2.2 Add `hero-pencil` icon to the "Edit" button in the job detail header
- [x] 2.3 Add `hero-arrow-left` icon to the "Back to Jobs" link in the job detail header

## 3. Jobs Index — Link & Icon Changes

- [x] 3.1 Change job title `<.link>` in the index table from `~p"/app/pipeline/#{job.id}"` to `~p"/app/jobs/#{job.id}"`
- [x] 3.2 Add a "Pipeline" icon link (`hero-arrow-top-right-on-square`) in the actions column alongside the existing text link
- [x] 3.3 Add `hero-plus` icon to the "+ New Job" button
- [x] 3.4 Add `hero-x-mark` or `hero-arrow-path` icon to the "Close"/"Reopen" toggle button

## 4. Verification

- [x] 4.1 Run `mix compile --warnings-as-errors` and fix any warnings
- [x] 4.2 Run `mix precommit` and ensure all tests pass
- [x] 4.3 Manually verify both `/app/jobs` and `/app/jobs/:id` pages load correctly in the browser
