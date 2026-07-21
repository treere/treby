## Why

The application currently only supports English with hardcoded UI strings. To serve a broader user base, multi-language support is needed. Starting with Italian and English, users should see the app in their preferred language, with a quick way to switch.

## What Changes

- Add Gettext locale resolution via a plug (browser config → session → user preference)
- Add `locale` field to user schema for persistent language preference
- Add language switcher dropdown in the app header (visible on every page)
- Add language settings page under `/app/settings/language`
- Wrap all hardcoded UI strings in `gettext()` calls
- Create Italian translation files (`it/` locale directory)
- Make the `<html lang="...">` attribute dynamic based on resolved locale

## Capabilities

### New Capabilities
- `i18n`: Internationalization infrastructure — locale resolution, Gettext integration, translation file management
- `language-settings`: User-facing language preference page and header switcher

### Modified Capabilities

## Impact

- **User schema**: New `locale` field (string, default "en") + migration
- **Router**: New route for language settings page
- **Layouts**: Dynamic `lang` attribute, new language switcher component
- **All LiveViews/Controllers**: UI strings need `gettext()` wrapping
- **Gettext files**: New `it/` locale directory with Italian translations
- **No API changes**: Frontend-only feature
- **No breaking changes**: Default behavior (English) preserved
