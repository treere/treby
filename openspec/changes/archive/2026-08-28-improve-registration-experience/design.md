## Context

`registration_controller.ex` (`create/2`) builds company + owner + tenant from a form that includes a required "Company URL slug" field — a technical concept that non-technical users shouldn't have to reason about. On failure the controller flashes generic messages ("Email already registered or invalid data", "Could not create company") and re-renders. `Tenants.create_tenant/1` (tenants.ex:22-46) already seeds notification preferences and the default pipeline, but creates no career page, so a fresh tenant sees the "Career page coming soon" fallback in `careers_live/index.ex`.

## Goals / Non-Goals

**Goals:**
- One fewer technical field: slug derived from the company name and always unique.
- Specific, field-level errors on registration failure (consistent with `error-feedback`).
- Every new tenant has a working `/:tenant_slug/careers` page immediately.

**Non-Goals:**
- Not changing password/ToS validations (already covered by `registration-polish`).
- Not adding company-rename slug workflows (out of scope; slug is derived once at registration).

## Decisions

- Remove the slug input from the form and drop the slug requirement from the tenant changeset's registration cast.
- Derive the slug inside the registration path: downcase the company name, strip to URL-safe characters (`[a-z0-9-]`), and uniquify with `-2`, `-3`, … on collision.
- Return `{:error, changeset}` tuples so the controller re-renders with inline field errors plus a flash, mirroring the standard Phoenix pattern.
- Ensure slug presence in the tenant insert so the fallback in the careers LiveView is bypassed.

## Risks / Trade-offs

- [Collisions on common company names] → Mitigation: uniquify suffix loop with a uniqueness check.
- [Existing tenants without a slug] → Mitigation: backfill migration deriving slugs from company names (idempotent).
- [Company renamed later → stale slug] → Accepted; slug management in Settings is a separate future concern.

## Open Questions

- Should the slug be editable in Settings > Branding later? (Not now; noted as follow-up.)