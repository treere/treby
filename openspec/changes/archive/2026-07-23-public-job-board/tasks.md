## 1. Database & Schema

- [x] 1.1 Create migration to add `visible` boolean field (default: true) to `jobs` table
- [x] 1.2 Update `Job` schema to include `visible` field
- [x] 1.3 Update `Job` changeset to cast `visible`

## 2. Context Functions

- [x] 2.1 Add `list_visible_jobs/1` to `Jobs` context (filtered by tenant, visible + open)
- [x] 2.2 Add `list_all_visible_jobs/0` to `Jobs` context (all tenants, visible + open)
- [x] 2.3 Add `search_visible_jobs/2` to `Jobs` context (search within tenant)
- [x] 2.4 Add `search_all_visible_jobs/1` to `Jobs` context (search across all tenants)

## 3. Router

- [x] 3.1 Add `/careers` route to public scope pointing to `CareersLive.GlobalIndex`

## 4. Global Board

- [x] 4.1 Create `CareersLive.GlobalIndex` LiveView with tenant info preloaded
- [x] 4.2 Implement global board template with company logo, name, job title, salary
- [x] 4.3 Add search input and `handle_event("search", ...)` handler

## 5. Per-Tenant Board

- [x] 5.1 Update `CareersLive.Index` to filter by `visible=true`
- [x] 5.2 Add search input to per-tenant board template
- [x] 5.3 Add `handle_event("search", ...)` handler to filter jobs

## 6. Public Job Detail

- [x] 6.1 Update `CareersLive.Show` to display company logo, name, and description from career page
- [x] 6.2 Add "not found" state for closed jobs in `CareersLive.Show`

## 7. Internal Job Listing

- [x] 7.1 Add "Public" column with visibility toggle to `JobsLive.Index` table
- [x] 7.2 Add `handle_event("toggle_visibility", ...)` handler to toggle `visible` field
- [x] 7.3 Disable toggle for closed jobs

## 8. Internal Job Detail

- [x] 8.1 Add "Copy Public Link" button to `JobsLive.Show` template
- [x] 8.2 Add colocated JS hook for clipboard copy with confirmation feedback

## 9. Cleanup & Testing

- [x] 9.1 Verify `mix precommit` passes
- [x] 9.2 Test global board loads and filters correctly
- [x] 9.3 Test per-tenant board filters by visible flag
- [x] 9.4 Test search on both boards
- [x] 9.5 Test closed job shows "not found" page
- [x] 9.6 Test visibility toggle in internal listing
