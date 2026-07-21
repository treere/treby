## 1. Router Update

- [x] 1.1 Change `get "/", PageController, :home` to `live "/", HomeLive` in router.ex

## 2. HomeLive Module

- [x] 2.1 Create `HomeLive` module at `lib/treby_web/live/home_live.ex`
- [x] 2.2 Implement `mount/3` with empty assigns (no auth required)
- [x] 2.3 Implement `render/1` with `Layouts.app` wrapper and `current_scope: nil`

## 3. Landing Page Template

- [x] 3.1 Create hero section with product name "Treby" and tagline
- [x] 3.2 Add primary CTA button linking to `/register`
- [x] 3.3 Create feature cards section (job management, candidate tracking, interviews)
- [x] 3.4 Add header navigation with login and register links
- [x] 3.5 Add footer with product name and attribution

## 4. Cleanup

- [x] 4.1 Remove or repurpose `PageController` and `PageHTML` modules
- [x] 4.2 Remove old `home.html.heex` template
- [x] 4.3 Update or remove page controller tests

## 5. Verification

- [x] 5.1 Test landing page loads at `/` without authentication
- [x] 5.2 Verify all navigation links work correctly
- [x] 5.3 Test responsive layout on mobile viewport
