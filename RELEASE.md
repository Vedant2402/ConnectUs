# ConnectUs Release Guide

ConnectUs is not yet a production release. This checklist documents the steps
that must be completed before distributing Android or iOS builds.

## Required checks

From `connectus_app`:

```bash
dart format --output=none --set-exit-if-changed lib test
flutter analyze
flutter test
flutter build web --release
```

The GitHub Actions workflow runs formatting, analysis, and tests for every pull
request and every push to `main`.

## Configuration

- Use a dedicated production Supabase project.
- Apply every migration under `connectus_app/supabase/migrations`.
- Audit all Row Level Security policies.
- Configure authentication redirect URLs for production.
- Keep `.env`, signing files, and privileged keys outside Git.

## Android

1. Choose the final application ID.
2. Create an upload keystore and store it securely.
3. Configure release signing outside source control.
4. Run `flutter build appbundle --release`.
5. Test the bundle through Google Play internal testing.
6. Complete the data-safety and privacy disclosures.

## iOS

1. Choose the final bundle identifier.
2. Configure the Apple Developer team and signing in Xcode.
3. Set the app icons, privacy strings, and capabilities.
4. Run `flutter build ipa --release`.
5. Upload through Xcode or Transporter.
6. Test using TestFlight before App Store review.

## Release approval

Do not publish until authentication, password recovery, messaging, receipts,
presence, unread counts, offline behavior, and data isolation have been tested
on real Android and iOS devices.

