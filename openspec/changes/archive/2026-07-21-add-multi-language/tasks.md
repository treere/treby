## 1. Database & Schema

- [x] 1.1 Add `locale` field (string, default "en", max 5) to users table via migration
- [x] 1.2 Update User schema with `locale` field

## 2. Locale Resolution

- [x] 2.1 Create `SetLocale` plug in `lib/treby_web/plugs/set_locale.ex`
- [x] 2.2 Implement Accept-Language header parsing
- [x] 2.3 Implement session-based locale storage
- [x] 2.4 Add `SetLocale` plug to `:browser` pipeline in router

## 3. Gettext Setup

- [x] 3.1 Create `priv/gettext/it/LC_MESSAGES/default.po` with Italian translations
- [x] 3.2 Extract and translate all hardcoded UI strings in Layouts.app
- [x] 3.3 Extract and translate strings in HomeLive
- [x] 3.4 Extract and translate strings in SettingsLive.Index
- [x] 3.5 Extract and translate flash messages in Layouts.flash_group

## 4. Root Layout

- [x] 4.1 Make `<html lang="...">` dynamic based on `@locale` assign
- [x] 4.2 Pass locale assign through Layouts.app to root layout

## 5. Language Switcher (Header)

- [x] 5.1 Create language switcher dropdown component
- [x] 5.2 Add switcher to Layouts.app header (authenticated pages)
- [x] 5.3 Add language links to HomeLive header (public page)

## 6. Language Settings Page

- [x] 6.1 Create `SettingsLive.Language` LiveView at `/app/settings/language`
- [x] 6.2 Add route in router.ex
- [x] 6.3 Add settings tile in SettingsLive.Index

## 7. LiveView Integration

- [x] 7.1 Import `set_locale_from_session/2` helper in LiveView macro
- [x] 7.2 Call `set_locale_from_session/2` in each LiveView mount

## 8. Cleanup & Verification

- [x] 8.1 Add config for default locale in `config/config.exs`
- [x] 8.2 Test locale resolution fallback chain
- [x] 8.3 Test language switcher saves preference
- [x] 8.4 Run `mix precommit`
