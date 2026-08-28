## REMOVED Requirements

### Requirement: Email booking link to candidate
**Reason**: The email with a self-scheduling booking link is removed. Self-scheduling now happens inside the authenticated candidate portal (`candidate-self-scheduling`), and the candidate receives only a notification ping.
**Migration**: Candidates book their interview slot from `/:tenant_slug/portal/schedule` after logging in via OTP. The booking token/email flow is removed.