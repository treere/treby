## 1. Foundation Setup

- [x] 1.1 Add dependencies to mix.exs: bcrypt_elixir, ex_aws, ex_aws_s3, finch
- [x] 1.2 Configure S3/MinIO in config/config.exs and config/dev.exs
- [x] 1.3 Add MinIO service to docker-compose.yml
- [x] 1.4 Download SortableJS to assets/vendor/sortable.min.js
- [x] 1.5 Import SortableJS in assets/js/app.js

## 2. Multi-Tenancy

- [x] 2.1 Create tenants migration (id, name, slug, settings, timestamps)
- [x] 2.2 Create Treby.Tenants context with CRUD functions
- [x] 2.3 Create tenant scoping plug (assigns current_tenant)
- [x] 2.4 Create pipeline_stages migration (id, tenant_id, name, position, color, timestamps)
- [x] 2.5 Create default pipeline stages on tenant creation
- [x] 2.6 Add tenant_id to future tables (document pattern)

## 3. Authentication

- [x] 3.1 Create users migration (id, tenant_id, email, password_hash, name, role, timestamps)
- [x] 3.2 Create Treby.Accounts context with auth functions
- [x] 3.3 Implement password hashing with bcrypt_elixir
- [x] 3.4 Create session management (login, logout, session cookie)
- [x] 3.5 Create auth plug (require_auth, fetch_current_user)
- [x] 3.6 Create LoginLive (email + password form)
- [x] 3.7 Create RegisterLive (registration form)
- [x] 3.8 Add authenticated routes to router

## 4. Jobs Management

- [x] 4.1 Create jobs migration (id, tenant_id, title, description, salary_range, status, custom_fields, timestamps)
- [x] 4.2 Create Treby.Jobs context with CRUD functions
- [x] 4.3 Create JobsLive.Index (job listing page)
- [x] 4.4 Create JobsLive.Show (job detail page)
- [x] 4.5 Create job form component (create/edit)
- [x] 4.6 Add job status management (open/closed)

## 5. Candidates Management

- [x] 5.1 Create candidates migration (id, tenant_id, name, email, phone, linkedin_url, custom_fields, timestamps)
- [x] 5.2 Create Treby.Candidates context with CRUD functions
- [x] 5.3 Create CandidatesLive.Index (candidate listing page)
- [x] 5.4 Create CandidatesLive.Show (candidate profile page)
- [x] 5.5 Create candidate form component

## 6. Pipeline

- [x] 6.1 Create applications migration (id, tenant_id, job_id, candidate_id, pipeline_stage_id, resume_url, applied_at, custom_fields, timestamps)
- [x] 6.2 Create Treby.Pipeline context (stages, applications)
- [x] 6.3 Create PipelineLive.Index (Kanban board for a job)
- [x] 6.4 Implement SortableJS hook for drag-and-drop
- [x] 6.5 Handle move_candidate event (update stage_id)
- [ ] 6.6 Add real-time updates via PubSub
- [ ] 6.7 Create pipeline stage management UI (Settings → Pipeline)

## 7. Notes

- [x] 7.1 Create notes migration (id, tenant_id, application_id, author_id, content, type, rating, timestamps)
- [ ] 7.2 Create Treby.Notes context with CRUD functions
- [ ] 7.3 Create note form component (on candidate profile)
- [ ] 7.4 Display notes list on candidate profile
- [ ] 7.5 Implement delete note (author only)

## 8. File Upload

- [x] 8.1 Create Treby.Uploads module (S3 client wrapper)
- [ ] 8.2 Implement resume upload flow (LiveView upload → S3)
- [ ] 8.3 Implement logo upload flow (Settings → Branding)
- [ ] 8.4 Add file validation (size, type)
- [ ] 8.5 Add secure resume access (presigned URLs or proxy)

## 9. Career Page

- [x] 9.1 Create career_pages migration (id, tenant_id, slug, title, description, logo_url, primary_color, published, timestamps)
- [x] 9.2 Create Treby.Careers context
- [x] 9.3 Create CareersLive.Index (public job listings)
- [x] 9.4 Create CareersLive.Show (job detail + apply button)
- [x] 9.5 Create CareersLive.Apply (application form)
- [x] 9.6 Implement auto-create candidate on application submit
- [x] 9.7 Create thank-you confirmation page
- [x] 9.8 Add tenant slug routing for public pages

## 10. Custom Fields

- [ ] 10.1 Create custom_fields migration (id, tenant_id, name, field_type, applies_to, options, required, position, timestamps)
- [ ] 10.2 Create Treby.Customization context
- [ ] 10.3 Create custom field management UI (Settings → Fields)
- [ ] 10.4 Implement dynamic form rendering based on field definitions
- [ ] 10.5 Add custom field validation (required, type checks)
- [ ] 10.6 Display custom fields on candidate profile and job detail

## 11. Team Management

- [x] 11.1 Create invites migration (id, tenant_id, email, role, token, accepted_at, expires_at, timestamps)
- [x] 11.2 Create invite flow (admin sends invite → email sent)
- [x] 11.3 Create InviteLive.Show (invitee registration form)
- [x] 11.4 Create team management UI (Settings → Team)
- [x] 11.5 Implement role-based access control (admin, member)
- [x] 11.6 Add remove team member functionality

## 12. Branding

- [ ] 12.1 Store branding in tenant.settings JSONB
- [ ] 12.2 Create branding settings UI (Settings → Branding)
- [ ] 12.3 Apply branding to career page (logo, colors, text)
- [ ] 12.4 Add branding preview in settings

## 13. Analytics

- [ ] 13.1 Implement pipeline count queries (candidates per stage per job)
- [ ] 13.2 Implement time-to-hire calculation
- [ ] 13.3 Implement stage conversion rate calculation
- [ ] 13.4 Create AnalyticsLive.Index (analytics dashboard)
- [ ] 13.5 Display charts/visualizations (bar charts for pipeline, metrics cards)

## 14. Polish & Testing

- [x] 14.1 Add seed data for development (demo tenant, jobs, candidates)
- [ ] 14.2 Add integration tests for tenant isolation
- [ ] 14.3 Add integration tests for auth flows
- [ ] 14.4 Add integration tests for career page application flow
- [ ] 14.5 Test drag-and-drop functionality
- [ ] 14.6 Test file upload to MinIO
- [x] 14.7 Run mix precommit and fix any issues
