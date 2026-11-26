# AQDIN

**Marriage-minded Muslim matchmaking, built around intention, compatibility, privacy, and trust.**

AQDIN is a global Muslim matrimonial platform planned for an initial Nigeria-first launch.

## Product surfaces

- **Mobile app:** Android and iOS experience for members.
- **Wali portal:** Optional, consent-based family or trusted-representative participation with explicit, revocable permissions.
- **Admin dashboard:** Role-based operations, verification, moderation, support, and platform management.
- **Public website:** Product information, safety guidance, membership, help, and account/legal pages.

## Planned technology

- Flutter and Dart for the custom mobile application.
- Supabase for PostgreSQL, authentication, storage, realtime features, and Edge Functions.
- GitHub Actions for automated checks and builds.

## Product principles

- Adults aged 18 and over only.
- Marriage-oriented introductions, not casual dating.
- Privacy and consent by default.
- Wali/family involvement is optional and permission-based.
- Verification badges describe only what was actually verified.
- Compatibility guidance is explainable and does not predict marital success.
- Users are not ranked by religious worth or practice level.

## Development status

Repository initialized. Application code, database migrations, security policies, automated builds, and deployment workflows will be added in subsequent development stages.

## Security

Never commit Supabase service-role keys, access tokens, passwords, private identity documents, or other secrets. Store deployment credentials in appropriately restricted GitHub Actions secrets.
