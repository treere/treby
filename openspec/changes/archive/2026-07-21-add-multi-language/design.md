## Context

The app has no i18n infrastructure. All UI text is hardcoded English. Gettext is configured but only used for Ecto validation errors. The user schema has no locale preference field. No locale resolution plug exists.

Current state:
- `TrebyWeb.Gettext` backend exists with only `errors` domain
- `priv/gettext/en/` has validation error translations only
- `Layouts.app` has hardcoded English nav strings
- `root.html.heex` has `<html lang="en">` hardcoded
- User schema: `email`, `password_hash`, `name`, `role` — no `locale`

## Goals / Non-Goals

**Goals:**
- Locale resolution: browser config → session → user preference (fallback chain)
- Quick language switcher in the app header (every page)
- Language settings page at `/app/settings/language`
- Italian (`it`) and English (`en`) translations
- Dynamic `<html lang="...">` attribute

**Non-Goals:**
- URL-based locale routing (e.g., `/en/app/...`)
- RTL language support
- Pluralization rules beyond basic
- Date/time/number locale formatting
- Admin-managed translation strings

## Decisions

**1. Locale resolution order**
- Session `"locale"` → browser `Accept-Language` header → default `"en"`
- User preference is loaded from DB into session on login and on settings save
- Rationale: Session avoids DB queries on every request; user DB preference is synced to session when it matters (login, settings change)
- Alternative: URL prefix (`/it/...`) — rejected because it adds routing complexity and breaks existing links

**2. Storage: user schema field + session**
- Add `locale` field to `users` table (string, default "en", max 5 chars)
- Store resolved locale in session for quick access without DB hit
- On login/settings change, persist to user and session
- Rationale: Session avoids DB queries on every request; user field persists preference across sessions

**3. Language switcher placement**
- Dropdown in the app header next to user name (authenticated pages)
- Separate language links on public pages (HomeLive, CareersLive)
- Rationale: Always accessible, minimal UI disruption

**4. Gettext approach**
- Use default domain (`"default"`) for UI strings
- Keep existing `errors` domain for Ecto validation messages
- Create `priv/gettext/it/LC_MESSAGES/default.po` for Italian translations
- Rationale: Standard Phoenix pattern, single domain for UI text

**5. Plugging strategy**
- Add `SetLocale` plug to `:browser` pipeline (before `fetch_session` reads locale)
- Plug reads from conn (params or header), sets session, calls `Gettext.put_locale/1`
- Rationale: Centralized, works for both controllers and LiveViews

## Risks / Trade-offs

- **Risk**: Missing translations show English fallback → **Mitigation**: Gettext defaults to msgid when msgstr is empty
- **Risk**: Performance impact of locale lookup → **Mitigation**: Session-based, no DB query per request
- **Trade-off**: Session vs URL prefix → Choose session for simplicity; URL prefix would be better for SEO but adds complexity
- **Risk**: Hardcoded strings in many files → **Mitigation**: Incremental wrapping, can be done file-by-file
