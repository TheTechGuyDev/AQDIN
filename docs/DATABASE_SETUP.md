# AQDIN Supabase setup

GitHub Actions builds the Flutter app; committing SQL files does **not** execute them against the hosted Supabase project.

## Protecting the existing account

These migrations are additive. They do not drop or recreate `auth.users`, do not delete existing member accounts, and do not reset passwords. Keep the existing Supabase project and its current account. Do not run a project reset.

## Apply the database migrations

In the existing AQDIN Supabase project, open **SQL Editor** and run any migrations that have not already been applied, in timestamp order:

1. `supabase/migrations/202611260001_initial_schema.sql`
2. `supabase/migrations/202611260002_profile_onboarding_repair.sql`
3. `supabase/migrations/202611260003_matchmaking_messaging.sql`
4. `supabase/migrations/202611260004_member_experience.sql`
5. `supabase/migrations/202611260005_private_profile_photo_storage.sql`

The repair migration is safe to rerun. The later migrations are additive and designed to preserve existing user/profile rows. If an earlier migration has already been applied, do not re-run it blindly if Supabase reports a policy or object conflict; check the existing object first.

The fifth migration creates a **private** `profile-photos` Storage bucket. Member photos are not publicly exposed; the app uses time-limited signed URLs. New uploads remain pending until a moderation workflow approves them.

## Email OTP settings

AQDIN sends a one-time email code during new account registration and supports code-based sign-in for existing accounts. In Supabase Dashboard:

1. Open **Authentication → Providers → Email** and ensure Email provider is enabled.
2. Enable email confirmation.
3. Open **Authentication → Email Templates → Confirm signup**.
4. Use a numeric token template containing `{{ .Token }}` so the email contains the code the app asks the member to enter.
5. Save the template and use a real inbox for testing.

The existing account can continue to sign in with its current email and password. Do not delete it or create a replacement account. If email delivery limits are reached, use a configured SMTP provider before public launch.

## Required configuration

The Flutter client uses only `SUPABASE_URL` and the Supabase publishable key. Never place the service-role key in Flutter, GitHub source, or a public build. Privileged verification-provider calls and moderation actions must be performed by trusted server-side functions.

## Current scope notes

- Email OTP verification is implemented in the registration flow; password sign-in remains available to protect access to existing accounts.
- The app's member discovery and swipe actions now read/write member records when the corresponding migrations are applied.
- Government-ID/selfie verification requires a selected verification provider and secure server-side integration; a client-side badge must never claim verification before that provider confirms it.
- Wali invitations require the invited person's AQDIN user ID at this stage. Email-address invitation delivery needs a trusted Edge Function so private account lookup is never exposed to the client.
- Payment processing must be connected to a supported payment provider before subscriptions can accept real money.
