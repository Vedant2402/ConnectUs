# Contributing to ConnectUs

## Local setup

1. Install the stable Flutter SDK.
2. Open `connectus_app`.
3. Copy `.env.example` to `.env`.
4. Add a development Supabase URL and publishable key.
5. Run `flutter pub get`.

Never commit `.env` or privileged backend credentials.

## Before submitting changes

Run:

```bash
dart format lib test
flutter analyze
flutter test
```

Keep features inside the existing feature folders, preserve Row Level Security,
and include tests for behavior that can be exercised without production data.

## Commit style

Use a concise action-oriented message, for example:

```text
Add password recovery flow
Improve chat loading state
Fix unread conversation count
```

## Pull requests

Describe what changed, how it was tested, any database migration required, and
screenshots for visible interface changes.

