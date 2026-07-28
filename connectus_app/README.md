# ConnectUs Flutter App

ConnectUs is a real-time one-to-one messaging app built with Flutter and
Supabase.

## Development status

- Day 1: Complete — authentication, profiles, user search, conversations, and
  real-time messaging.
- Day 2: Complete — unread counts, last-read tracking, real-time conversation
  refresh, typing feedback, online/last-seen presence, conversation search,
  date separators, message grouping, session restoration, and profile settings.

## Day 2 highlights

- Conversations refresh when messages, memberships, or profiles change.
- Unread badges use the `get_unread_conversation_counts` RPC.
- Opening a chat and receiving messages calls
  `mark_conversation_as_read`.
- Message receipt upserts continue to track delivered and read states.
- Typing state uses ephemeral Supabase Realtime broadcasts.
- Presence updates `profiles.is_online` and `profiles.last_seen_at`.
- Chats display date separators and visually group consecutive messages.
- Conversation lists can be searched by name, username, or latest message.
- Existing Supabase sessions are restored when the app starts.
- Settings allow users to edit their display name and biography.

## Local setup

```bash
flutter pub get
cp .env.example .env
flutter run -d chrome
```

The `.env` file must contain:

```env
SUPABASE_URL=your-project-url
SUPABASE_PUBLISHABLE_KEY=your-publishable-key
```

Never commit `.env`, database passwords, service-role keys, or secret keys.

## Validation

```bash
dart format lib test
flutter analyze
flutter test
```
