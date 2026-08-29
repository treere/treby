# CSV Import

Migrate candidates from spreadsheets in three steps: upload, map, import.

## Flow

Implemented in `lib/treby/csv_import/csv_import.ex` (powered by `NimbleCSV`) and `lib/treby_web/live/import_live/index.ex` (`/app/import`).

1. **Upload** — drag a `.csv` (max 10 MB, `text/csv`) via `allow_upload :csv`. Parsed by `CsvImport.parse_csv/1` into `{headers, rows}`.
2. **Map** — auto-detected mapping via `CsvImport.auto_detect_mapping/1`:

   | CSV header | Maps to |
   |---|---|
   | `name` / `full_name` / `candidate_name` | `name` |
   | `email` / `e-mail` / `email_address` | `email` |
   | `phone` / `mobile` / `phone_number` | `phone` |
   | `linkedin` / `linkedin_url` | `linkedin_url` |

   You can correct the mapping manually, choose a **job** + **stage** and an optional **source** for the import.
3. **Import** — `CsvImport.import_rows/4` creates/finds `Candidate` records (deduplicating by email within the tenant), creates an `Application` per row in the selected stage with `source` set, and writes an `ImportLog` (`lib/treby/csv_import/import_log.ex`) with counts and per-row errors.

The UI is a 4-step wizard (Upload → Map → Preview → Result) with validation and error reporting.

## Deduplication

Candidates are matched by normalized email (`lib/treby/candidates/duplicates.ex`). Existing candidates are reused rather than duplicated; the application is still created (flagged `is_duplicate` if the same candidate already has an application for that job).

## Sources

If a source is selected during import, all created applications carry that `source` value, feeding the **Source Breakdown** in Analytics and the per-application source tag.

## Route

`/app/import` — authenticated (`:require_auth`), no extra role gate, but typically used by admins/members managing hiring.
