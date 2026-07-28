## 1. Page Title Fix

- [x] 1.1 Remove "Phoenix Framework" suffix from `root.html.heex`

## 2. Registration Form Updates

- [x] 2.1 Add password confirmation input field to registration template
- [x] 2.2 Add Terms of Service checkbox with links to `/terms` and `/privacy`
- [x] 2.3 Add server-side validation for password match in `RegistrationController.create/2`
- [x] 2.4 Add server-side validation for ToS acceptance in `RegistrationController.create/2`

## 3. Stub Pages

- [x] 3.1 Create `/terms` page with "Coming soon" content
- [x] 3.2 Create `/privacy` page with "Coming soon" content
- [x] 3.3 Add routes for `/terms` and `/privacy` in router

## 4. Testing

- [x] 4.1 Test registration with mismatched passwords shows error
- [x] 4.2 Test registration without ToS acceptance shows error
- [x] 4.3 Test successful registration with all fields
- [x] 4.4 Test `/terms` and `/privacy` pages load correctly
