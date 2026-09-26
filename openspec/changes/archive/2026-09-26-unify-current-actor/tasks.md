## 1. Actor helper

- [x] 1.1 Add `Authorization.Actor.id/1` (nil-safe) with unit tests in `test/treby/authorization_policy_test.exs`
- [x] 1.2 Migrate `actor && actor.id` sites in contexts and AI tools to `Actor.id/1`, verify with `mix test` on touched suites

## 2. Guard assigns

- [x] 2.1 Assign `current_actor` in `Plugs.RequireMembership` and `Hooks.RequireMembership` via `Actor.from(membership, tenant)`; delete unreachable catch-all clause in hook
- [x] 2.2 Add guard tests: actor matches membership derivation, legacy fallback derives actor, contract (redirect/flash) unchanged

## 3. Lookup migration

- [x] 3.1 Replace redundant `get_membership/2` lookups in guard-mounted settings LiveViews (`team`, `webhooks`, `language`, `company_availability`) with assign reads
- [x] 3.2 Dropped: `messages_queue_live` passes `current_membership` to components that consume `membership.role` directly — legitimate component input, not duplication; changing it would churn component APIs for zero benefit

## 4. Verify

- [x] 4.1 Run `mix precommit` and `openspec validate --changes`, fix all issues

No `site/` update: internal refactor, no user-visible change.
