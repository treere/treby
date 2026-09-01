# CSV Import

Migrate candidates from a spreadsheet in three steps: upload, map, import.

![CSV Import wizard](/screenshots/29-csv-import.png)

## Steps

Find it under **Import** in the main menu.

1. **Upload** — drag a `.csv` file (max 10 MB). The system reads headers and rows.
2. **Map** — Treby auto-detects the most common columns:

   | Header in CSV | Field in Treby |
   |---|---|
   | `name` / `full_name` / `candidate_name` | Name |
   | `email` / `e-mail` / `email_address` | Email |
   | `phone` / `mobile` / `phone_number` | Phone |
   | `linkedin` / `linkedin_url` | LinkedIn profile |

   You can correct the mapping, choose the **job** and **stage** destination, and optionally set a **source**.
3. **Import** — the system creates or reuses profiles (looking up by email inside your company), creates one application per row in the chosen stage, and shows a summary with counts and per-row errors.

The interface is a 4-step wizard (Upload → Map → Preview → Result) with validation and error reporting.

## Duplicates

If an email already exists, the existing profile is reused instead of creating a new one; the application is still created and marked as duplicate if the same candidate already had an application for that job.

## Sources

If you specify a source during import, all created applications carry that value, which you can later find in the per-source breakdown in **Analytics** and as a label on the application.
