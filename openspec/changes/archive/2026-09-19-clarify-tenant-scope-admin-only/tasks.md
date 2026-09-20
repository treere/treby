## 1. Specs

- [x] 1.1 Update `openspec/specs/data-privacy-export/spec.md` to clarify tenant scope admin-only (already done in delta)
- [x] 1.2 Update `openspec/specs/data-privacy-erasure/spec.md` similarly

## 2. Implementation (already done in fix/bug-fixes:c20aa0a)

- [x] 2.1 Verify `lib/treby_web/router.ex` data-privacy live_session is `:data_privacy` (not admin) — already done
- [x] 2.2 Verify `lib/treby_web/settings_nav.ex` role :member for data_privacy — already done
- [x] 2.3 Verify `lib/treby_web/live/settings_live/data_privacy.ex` handles tenant vs user scope checks — already done

## 3. Tests

- [x] 3.1 Verify `test/treby_web/live/data_privacy_live_test.exs` covers member user scope and tenant blocked — already done (5 passed)

## 4. Docs

- [x] 4.1 Ensure `site/features/data-privacy.md` already distinguishes user vs tenant scope — verify, no change needed

## 5. Verification

- [x] 5.1 Run `mix precommit` and `openspec validate --strict` and fix issues
