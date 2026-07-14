# FairImage

## Local Development with Clerk

To run FairImage locally, you'll need to set up Clerk. Follow these steps:

1. Create a Clerk account at [https://clerk.com](https://clerk.com).
2. Create a new application in Clerk.
3. Make sure organizations are enabled 
4. Obtain your Clerk API keys under Instance -> Configure -> API Keys.
5. Plug them into your `.env` file as `VITE_CLERK_PUBLISHABLE_KEY` and `CLERK_SECRET_KEY`.

You won't be able to sign in until the `sso_id` value is set on the FairImage user record you want to use.

Assuming you've got your FairImage database set up with users and orgs (either by `heroku pg:pull`ing from staging or creating some records yourself in the console), take these steps:

For each user you want to work with (you'll probably want one admin and one non-admin):
1. Create a corresponding account in the Users tab in Clerk.
2. Copy the User ID value from Clerk and plug it into the FairImage user's `sso_id` field.
3. If you want the account to be an admin, include `is_global_admin: true` in the private metadata.

For each organization:
1. Create a corresponding organization in the Organizations tab in Clerk.
2. Copy the Organization ID value from Clerk and plug it into the FairImage organization's `sso_id` field.
3. Add whichever users you want under the Members tab on the organization's Clerk page. (Note: roles are irrelevant to FairImage, but you may want to set these if you're planning to use this Clerk org for other apps.)
