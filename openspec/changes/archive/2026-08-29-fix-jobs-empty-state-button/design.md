## Context

The jobs index LiveView (`TrebyWeb.JobsLive.Index`) shows an empty state via the shared `<.empty_state>` component when a tenant has no jobs. Its CTA uses `action={%{href: "#", label: "Create your first job"}}`, which the component renders as `<.link navigate="#">` — a navigation to the current page, i.e. a dead button. The inline creation form already exists on the page and is toggled by `phx-click="show_create_form"`.

## Goals / Non-Goals

**Goals:**
- Make the empty-state button open the existing inline job creation form.
- Add a regression test that exercises the click (the current test only checks text presence, which cannot catch a dead link).

**Non-Goals:**
- No new routes or separate create page.
- No changes to other empty states.

## Decisions

- **Use the `:cta` slot instead of the `action` attr.** The `action` attr is hard-wired to `<.link navigate={href}>`, which cannot trigger server events. The `:cta` slot allows arbitrary content, so a `<button phx-click="show_create_form">` can reveal the inline form directly. This matches the onboarding spec intent of "linking to the job creation form" — which, in this UI, is the inline form.
  - Alternative considered: changing `href` to `/app/jobs` (like the dashboard) — rejected, since the user is already on `/app/jobs` and the link would still do nothing useful.
- **Test the interaction, not the markup.** Use `Phoenix.LiveViewTest` to click the button (`element(..., "button").click()` via the CTA) and assert the create form appears (e.g. `has_element?(view, "#job-form")`), replacing the weak text-only assertion.

## Risks / Trade-offs

- The `:cta` slot renders with its own button styling (`btn btn-primary`) rather than the shared action styling — consistent with other CTAs in the design system → Mitigation: reuse the same `btn btn-primary` classes the component applies to action links.
- Spec delta must use the full MODIFIED requirement block or archive loses detail → Mitigation: copy the entire "Jobs page empty state" requirement verbatim from `openspec/specs/onboarding/spec.md` and edit the scenario.