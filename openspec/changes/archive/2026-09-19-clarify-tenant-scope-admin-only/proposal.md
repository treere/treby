## Why

Members expect to download their own data via Data & Privacy, but currently the whole page is admin-gated, blocking user-scope export/erasure. We need to clarify why tenant-scope (company data) remains admin-only: it contains PII of all candidates, jobs, and audit history, not just the requester's data, and must be audited and rate-limited.

## What Changes

- Keep `/settings/data-privacy` accessible to all authenticated members (already moved from `live_session :admin` to `:data_privacy`).
- Tenant scope (`scope=tenant`) for export and erasure remains admin-only, with explicit `Only admins can ...` flashes and UI hidden for members.
- User scope (`scope=user`) remains available to all members for `Export my data` and `Delete my account`.
- No new routes or DB changes; only spec clarification and UI copy.

## Capabilities

### New Capabilities
- (none)

### Modified Capabilities
- `data-privacy-export`: Clarify that tenant-scope export is admin-only because it contains company-wide PII, while user-scope is for the requester's own data.
- `data-privacy-erasure`: Clarify that tenant-scope erasure (Delete company) is admin-only and requires slug confirmation, while user-scope erasure (Delete my account) is for any member.

## Impact

- Affected specs: `openspec/specs/data-privacy-export/spec.md`, `openspec/specs/data-privacy-erasure/spec.md`, `openspec/specs/data-privacy-requests/spec.md` (if exists).
- Code: `lib/treby_web/live/settings_live/data_privacy.ex` (already handles `scope=="tenant" and role!="admin"`), `lib/treby_web/router.ex` (already moved to `:data_privacy` live_session), `lib/treby_web/settings_nav.ex` (role :member).
- Docs: `site/features/data-privacy.md` already distinguishes user vs tenant scope; no code change needed beyond spec clarification.
