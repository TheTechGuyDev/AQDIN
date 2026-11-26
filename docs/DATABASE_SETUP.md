# AQDIN database setup

A green GitHub Actions build does not apply SQL migrations to the hosted Supabase project.

## Fix the profile-save error

1. Open the AQDIN Supabase project.
2. Open **SQL Editor** and create a new query.
3. Copy and run the complete contents of `supabase/migrations/202611260002_profile_onboarding_repair.sql`.
4. Wait for the query to finish successfully.
5. In **Table Editor**, confirm `public.user_profiles` exists.
6. Return to AQDIN and use the profile form's **Save and continue** button.

The migration creates the profile table, applies owner-scoped row-level security and refreshes the PostgREST schema cache. It is safe to run more than once.

Never add the Supabase service-role key to the Flutter app or a public repository.
