## 1. Derive company slug

- [x] 1.1 Add a slug derivation helper (downcase company name, URL-safe, uniquify with `-2`, `-3`, … on collision)
- [x] 1.2 Remove the "Company URL slug" field from the registration form (`registration_html/new.html.heex`)
- [x] 1.3 Drop the slug requirement from the registration changeset and derive the slug inside the registration/`Tenants.create_tenant/1` path, ensuring uniqueness
- [x] 1.4 Add an idempotent migration backfilling slugs for existing tenants without one

## 2. Field-level registration errors

- [x] 2.1 Return `{:error, changeset}` from the registration flow so inline field errors render on the form
- [x] 2.2 Keep/verify a specific error message (instead of generic "invalid data") for duplicate email
- [x] 2.3 Confirm the form re-renders with inline errors for invalid data

## 3. Career page ready at first login

- [x] 3.1 Ensure a fresh tenant's `/:tenant_slug/careers` serves the real career page (no "coming soon" fallback)

## 4. Verify

- [x] 4.1 Add a test: registration without a slug field creates a tenant with a derived unique slug
- [x] 4.2 Add a test: registration with duplicate email shows field-level error
- [x] 4.3 Add a test: career page is accessible for a tenant created during registration
- [x] 4.4 Run `mix precommit` and fix any pending issues