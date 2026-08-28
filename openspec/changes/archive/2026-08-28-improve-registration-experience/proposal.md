## Why

Registration requires a non-obvious technical field ("Company URL slug") and shows generic error flashes ("Email already registered or invalid data"). This friction blocks the core self-serve value: a company should sign up effortlessly and immediately have a working public career page.

## What Changes

- Remove the "Company URL slug" input from the registration form; the slug is derived automatically from the company name (uniquified on collision).
- Registration failures use field-level inline errors (plus a flash) instead of only a generic message.
- Every new tenant is guaranteed a unique slug, so `/:tenant_slug/careers` always serves a real career page (no "Career page coming soon" fallback at first login).

## Capabilities

### New Capabilities
- None.

### Modified Capabilities
- `registration-polish`: registration no longer requires a URL slug and surfaces specific field-level errors.

## Impact

- `lib/treby_web/controllers/registration_controller.ex`.
- `lib/treby_web/controllers/registration_html/new.html.heex`.
- `lib/treby/tenants/tenants.ex` — derive slug inside `create_tenant/1` and remove the slug requirement.
- `lib/treby/careers/careers.ex` — drop the "coming soon" fallback path for tenants with a slug.