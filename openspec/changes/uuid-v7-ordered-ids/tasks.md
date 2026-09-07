## 1. Primary Key Switch

- [x] 1.1 Replace `@primary_key {:id, :binary_id, autogenerate: true}` with `@primary_key {:id, Ecto.UUID, autogenerate: [version: 7, precision: :monotonic]}` in all 35 schemas under `lib/treby/**` (leave `@foreign_key_type :binary_id` untouched)
- [x] 1.2 Verify `grep -R "@primary_key {:id, :binary_id" lib/` returns zero matches
- [x] 1.3 Run `mix ecto.migrate` (expect no-op, no new migration) and `mix compile --warnings-as-errors`

## 2. Ordering Tests

- [x] 2.1 Add same-`inserted_at` descending-id ordering assertions to `test/treby/candidates_test.exs`, `test/treby/jobs_test.exs` and `test/treby/pipeline_test.exs` (applications)

## 3. Verification

- [x] 3.1 Run `mix test` (expect 551+ passing, zero warnings)
- [x] 3.2 Run `mix precommit` (expect EXIT 0)
- [x] 3.3 Run `openspec validate --strict` (expect all specs valid)
