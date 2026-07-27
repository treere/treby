## 1. Active Link Infrastructure

- [x] 1.1 Add `data-nav` attributes to all nav links (desktop and mobile) with target paths
- [x] 1.2 Create `highlightActiveNav()` JS function in `app.js` that toggles active Tailwind classes based on `window.location.pathname` matching `data-nav` values, runs on page load and `phx:page-loading-stop`

## 2. Desktop Nav Updates

- [x] 2.1 Add Pipeline, Import, Compare links to the desktop nav bar in correct order
- [x] 2.2 Apply `nav-link` class to all desktop nav links for JS active detection

## 3. Mobile Drawer Updates

- [x] 3.1 Add Pipeline, Import, Compare links to the mobile drawer
- [x] 3.2 Apply `mobile-nav-link` class to mobile drawer links for JS active detection
- [x] 3.3 Add locale switcher to the mobile drawer (with `id_suffix` to avoid duplicate IDs)
- [x] 3.4 Add logout link to the mobile drawer

## 4. Verification

- [x] 4.1 Run `mix precommit` and fix any issues
