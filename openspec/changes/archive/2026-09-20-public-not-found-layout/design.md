## Context

`/404` is a public route (browser pipeline only, no membership hook), so `current_tenant` was always nil and the app shell rendered without tenant context, while the CTAs fell back to legacy `/app/*`.

## Goals / Non-Goals

- Goal: a 404 that looks like the rest of the public site.
- Goal: useful links (global job board, homepage).
- Non-goal: keep app navigation on the 404 for logged-in users.

## Decisions

- Reuse `Layouts.public_header/1` and `Layouts.public_footer/1`, already used by the landing and careers pages.
- The page is a full-height flex column so the footer stays at the bottom.
