## Approach

Single-file template change in `Layouts.app`. No new abstractions, no new JS file.

### Breakpoint strategy (Tailwind defaults: `sm`=640, `md`=768, `lg`=1024, `xl`=1280)

- Inline links group: `hidden sm:flex sm:space-x-8` → `hidden xl:flex xl:space-x-8`
- Right group (theme / locale / user name / logout): `hidden sm:flex sm:items-center sm:space-x-4` → `hidden xl:flex xl:items-center xl:space-x-4`
- Notification bell: render outside the right group as an always-visible element (no responsive hide) so it stays in the bar at every width.
- Hamburger button: remove the standalone `fixed top-4 left-4 z-50` element; add an inline `xl:hidden` button as the first child of the nav left group.
- Drawer + backdrop overlay: `sm:hidden` → `xl:hidden`.

### Drawer contents (already complete)

Left sidebar (`w-64`) lists all 8 nav links (plus admin-gated Settings), theme toggle, locale switcher, and logout. The notification bell is intentionally absent from the drawer because it remains in the top bar.

### Close-on-navigate

Each drawer nav link gets:

```elixir
phx-click={
  Phoenix.LiveView.JS.toggle_class("hidden", to: "#mobile-nav-overlay")
  |> Phoenix.LiveView.JS.toggle_class("-translate-x-full", to: "#mobile-nav-drawer")
}
```

This toggles the drawer closed on tap while the `navigate` attribute still performs the route change.

### Accessibility / theme

- Keep `aria-label` on the hamburger.
- Verify light and dark (per AGENTS.md): drawer already uses `bg-white dark:bg-zinc-800`.
- No new contrast issues — reuses existing zinc / primary classes.

### Table responsiveness

Data tables must scroll horizontally inside their card on narrow viewports (they must not be clipped by `overflow-hidden` nor push the page wide).

- Shared `<.table>` component (`core_components.ex`): change its card from `overflow-hidden` to `overflow-x-auto` so every usage scrolls. This single change covers all component-based tables.
- Card-wrapped raw tables (`fields`, `scorecards`, `availability`, `email_templates`, `pipeline_stages`, `candidates/index`, `jobs/index`, `team`): change the card class `overflow-hidden` → `overflow-x-auto`. Rounded corners stay clipped because `overflow-x-auto` still clips to the border-radius box.
- Bare raw tables without a card (`messages_queue`, `webhooks` x2): wrap them in `<div class="overflow-x-auto">`.

This reuses the existing convention already present in `audit_log.ex` (card `overflow-hidden` + inner `overflow-x-auto`).

### Out of scope

- The separate ~72px horizontal page overflow observed at 350px width (non-nav content) is a different bug; track separately.
- A "More" overflow dropdown was explicitly rejected by product.
