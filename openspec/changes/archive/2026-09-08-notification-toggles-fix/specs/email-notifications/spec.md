# email-notifications (delta)

## Modified Requirements

### Requirement: Notification preferences
Toggle switches must visibly reflect their state so admins can tell what is
enabled.

#### Scenario: Toggle switch shows state
- **WHEN** an admin looks at Settings > Notifications
- **THEN** each enabled preference shows its switch in the ON position with
  the accent background, and each disabled one in the OFF position
- **AND** clicking a switch flips its position immediately and persists the
  new value
