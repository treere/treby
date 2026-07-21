## Context

The current root page (`/`) is a static controller-rendered template (`PageController.home`) showing Phoenix framework branding. The app needs a proper public landing page that introduces Treby as an ATS product and provides clear entry points for visitors.

The app uses Phoenix LiveView with Tailwind CSS. The authenticated app lives under `/app` with a `Layouts.app` wrapper. Public routes (careers, scheduling, invites) already exist under `/:tenant_slug/`.

## Goals / Non-Goals

**Goals:**
- Replace the static home page with a polished, branded landing page
- Provide clear CTAs to login, register, and public career pages
- Showcase key product features (job management, candidate tracking, interviews)
- Responsive design that works on mobile and desktop
- Use existing Tailwind CSS patterns and component structure

**Non-Goals:**
- Marketing copy changes or content management
- Analytics tracking for landing page visits
- A/B testing infrastructure
- Authentication state detection (redirect logic)

## Decisions

**1. LiveView vs Controller**
- Use `HomeLive` (LiveView) instead of `PageController`
- Rationale: Consistency with other public pages (CareersLive, SchedulingLive), future interactivity potential, no additional complexity for a simple page

**2. Layout strategy**
- Use `Layouts.app` with `current_scope: nil` for public navigation
- Rationale: Consistent nav structure, login/register links visible without auth

**3. Page structure**
- Hero section with product name, tagline, and primary CTA
- Feature cards section (3-4 key features)
- Footer with links
- Rationale: Standard SaaS landing page pattern, proven UX

**4. Route placement**
- Keep existing `get "/", PageController, :home` but change to `live "/", HomeLive`
- Rationale: Single route change, no scope restructuring needed

## Risks / Trade-offs

- **Risk**: Removing default Phoenix home page content → **Mitigation**: This is intentional; the Phoenix branding is not relevant to the product
- **Risk**: Layout may not look right without auth scope → **Mitigation**: Test with `current_scope: nil`, ensure nav adapts
- **Trade-off**: Simple static content vs. dynamic → Choose static for MVP; can add dynamic elements later
