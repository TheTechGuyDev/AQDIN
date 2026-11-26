# AQDIN — Initial Architecture

## Applications

- `apps/mobile`: Flutter member application (Android and iOS).
- `apps/wali-portal`: consent-based Wali/family portal (planned).
- `apps/admin`: role-based operations dashboard (planned).
- `apps/website`: public marketing and help website (planned).

The first implementation milestone is the Flutter mobile app. The root Flutter scaffold currently lives in `lib/` and will be moved into `apps/mobile/` when the monorepo layout is introduced.

## Backend

Supabase is planned for PostgreSQL, Auth, Storage, Realtime, and Edge Functions. Database migrations and row-level security policies must be committed before production data is introduced.

## Security requirements

- Enable row-level security on all user-owned tables.
- Keep private photos and verification artifacts in private storage buckets.
- Never expose the Supabase service-role key in a client application.
- Make Wali access explicit, granular, time-bounded where appropriate, and revocable.
- Log privileged administrative actions.
- Restrict access to identity verification data and prefer a specialist verification provider.

## Product safeguards

- Adults 18+ only.
- Verification labels must state exactly what was checked.
- Compatibility explanations are guidance, not predictions of marital success.
- No religious-worth scoring or ranking.
- Private conversations are not available to Wali accounts by default.
