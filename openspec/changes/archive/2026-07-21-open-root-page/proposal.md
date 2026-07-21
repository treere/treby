## Why

The current root page (`/`) is a bare-bones `PageController` rendering a static template. There is no public-facing landing page that introduces the product or provides navigation to key public features (careers, login, register). An open, well-designed root page is needed to give visitors a proper first impression and clear entry points.

## What Changes

- Replace the existing static `PageController` home action with a new `HomeLive` LiveView
- Design a polished landing page with hero section, feature highlights, and call-to-action buttons
- Add navigation links to login, register, and public career pages
- Maintain backward compatibility with existing public routes (careers, scheduling, invites)

## Capabilities

### New Capabilities
- `landing-page`: Public-facing root page at '/' with hero section, feature showcase, and navigation to login/register/careers

### Modified Capabilities

## Impact

- **Code**: New `HomeLive` module, updated router to use LiveView instead of controller for `/`, new template
- **Controllers**: `PageController` can be removed or repurposed
- **Templates**: New landing page template with responsive design
- **No API changes**: This is a frontend-only change
- **No dependencies**: Uses existing Phoenix LiveView and Tailwind CSS
