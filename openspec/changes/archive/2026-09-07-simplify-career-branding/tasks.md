## 1. Schema & migration

- [x] 1.1 Generate migration adding `about` (:string) to `career_pages`, migrate dev DB
- [x] 1.2 Permit `about` in career page changeset (cast only; columns `logo_url`/`primary_color`/`published` stay)
- [x] 1.3 Delete `get_published_career_page_by_tenant/1`; point the 3 public LiveViews (index, show, apply) at `get_career_page_by_tenant/1`

## 2. Brand settings form

- [x] 2.1 Remove logo upload (input + `allow_upload` + consume logic), color picker, and Published checkbox from Brand form
- [x] 2.2 Add `about` Markdown textarea with hint; keep title + description (subtitle)
- [x] 2.3 Add Edit/Preview tab switcher; Preview renders title/subtitle/about via `<.markdown>` from the live `@form` assign

## 3. Public career pages

- [x] 3.1 Career index header: neutral layout (name + centered subtitle + left-aligned `<.markdown>` about, `:if` empty), drop logo/color band
- [x] 3.2 Career job detail + apply pages: drop logo/color display, keep name + subtitle; Apply button default style

## 4. Verify

- [x] 4.1 Update LiveView tests (branding form, published gating removal); full suite green
- [x] 4.2 `mix precommit` clean, translation catalog complete
- [x] 4.3 Update user manual (branding/career pages) + regenerate screenshots
