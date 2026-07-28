## Context

The registration flow is a traditional Phoenix controller (`RegistrationController`) with a plain HTML form. It does not use LiveView or the `<.input>` core component. The form currently collects: company name, company slug, your name, email, and password. There is no password confirmation and no Terms of Service consent.

The page title is set in `root.html.heex` with a hardcoded `suffix=" · Phoenix Framework"`.

## Goals / Non-Goals

**Goals:**
- Remove "Phoenix Framework" from browser tab title
- Add password confirmation field that must match password
- Add Terms of Service / Privacy Policy checkbox that must be checked
- Keep changes minimal and focused — no refactoring the form to LiveView
- Create stub `/terms` and `/privacy` pages with "Coming soon" content

**Non-Goals:**
- Refactoring registration to use LiveView or `<.input>` component
- Building actual Terms of Service / Privacy Policy pages (just the checkbox and placeholder links)
- Storing ToS acceptance timestamp in the database (validate at form level only)
- Password strength indicator or zxcvbn integration

## Decisions

### 1. Page title: Remove suffix entirely

**Decision:** Change `suffix=" · Phoenix Framework"` to `suffix=""` or remove the suffix param.

**Rationale:** The `default="Treby"` already provides the base title. Pages can set `@page_title` for specific titles. No suffix needed.

**Alternative considered:** Change to `suffix=" · Treby"` — rejected because it would double "Treby" when `@page_title` is set.

### 2. Password confirmation: Controller-level validation

**Decision:** Add a `password_confirmation` input field. Validate match in `RegistrationController.create/2` before calling `Tenants.create_tenant`. Return flash error if mismatch.

**Rationale:** The form is controller-based, so validation happens in the controller action. No changeset modification needed since the password is already hashed by `User.changeset/2`.

**Alternative considered:** Add `password_confirmation` to `User.changeset/2` — rejected because it would require a schema change and the confirmation is only needed at registration time, not for all password operations.

### 3. Terms of Service: Validate at controller level, don't store

**Decision:** Add a required checkbox. Validate it's "true" in the controller. If not checked, redirect with flash error.

**Rationale:** For an MVP, storing ToS acceptance is not critical. The checkbox gates form submission. A future iteration could add a `tos_accepted_at` column if audit trail is needed.

**Alternative considered:** Add `tos_accepted_at` field to users table — deferred to future work if compliance requires it.

### 4. Links: Use placeholder hrefs

**Decision:** Link ToS checkbox label to `/terms` and Privacy Policy to `/privacy`. These pages don't exist yet but the links are functional placeholders.

**Rationale:** Creates the UX pattern now. Actual legal pages are a separate concern.

## Risks / Trade-offs

- **[Risk]** Users can bypass ToS checkbox via HTTP client → **Mitigation:** Server-side validation in controller. Checkbox is UX, not security.
- **[Risk]** No actual ToS/Privacy pages exist → **Mitigation:** Placeholder links. Could add simple static pages in a follow-up.
- **[Trade-off]** Not storing ToS acceptance → Acceptable for MVP. Can add database column later if needed for compliance audit trail.

## Migration Plan

1. Edit `root.html.heex` to remove title suffix
2. Add password confirmation and ToS fields to registration template
3. Add validation logic in `RegistrationController.create/2`
4. Create stub `/terms` and `/privacy` pages
5. Test registration flow manually and via existing tests
6. No database migration required

## Open Questions

- ~~Should we create stub `/terms` and `/privacy` pages, or leave as 404s?~~ **Decided:** Create stub pages with "Coming soon" content.
