## Context

The landing page had an inline footer with a single Careers link; careers pages had no footer. `/terms` and `/privacy` were orphaned.

## Goals / Non-Goals

- Goal: make the legal pages reachable from every public page.
- Goal: one footer component instead of duplicated markup.
- Non-goal: add legal links to authenticated app pages or the candidate portal.

## Decisions

- `Layouts.public_footer/1` renders the brand, tagline, a Discover list (Careers, Terms, Privacy), and the copyright, reusing the landing footer layout.
- The landing page replaces its inline footer with the component; the four public careers LiveViews render it after their content.

## Risks / Trade-offs

- The footer is repeated in the DOM of pages that already embed the shared header; acceptable and consistent.
