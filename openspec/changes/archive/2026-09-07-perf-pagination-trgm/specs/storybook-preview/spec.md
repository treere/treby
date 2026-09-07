## MODIFIED Requirements

### Requirement: Storybook shows every design-system component
The storybook SHALL define a story for each design-system component — `Button`, `Badge`, `Card`, `Modal`, `Dropdown`, `Tabs`, `Avatar`, `Feedback` (`Spinner`/`Skeleton`/`Toast`), `Pagination`, and `Pattern` (`ConfirmDialog`, `PageHeader`, `EmptyState`, `FilterBar`, `FormSection`, `LoadingOverlay`) — with controls for variants, sizes, and boolean props, and with usage notes.

#### Scenario: Button story covers variants and states
- **WHEN** a developer opens the Button story
- **THEN** controls allow switching `variant` (`primary`/`secondary`/`danger`/`ghost`/`outline`), `size` (`sm`/`md`/`lg`), `loading`, `disabled`, and the preview updates live

#### Scenario: All components have stories
- **WHEN** the storybook index is viewed
- **THEN** entries exist for Badge, Card, Modal, Dropdown, Tabs, Avatar, Spinner, Skeleton, Toast, Pagination, ConfirmDialog, PageHeader, EmptyState, FilterBar, FormSection, and LoadingOverlay

#### Scenario: Pagination story covers states
- **WHEN** a developer opens the Pagination story
- **THEN** controls allow switching `page`/`total_pages`, and states for first page (Prev disabled), last page (Next disabled), and single page (hidden) are previewable
