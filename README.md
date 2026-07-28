# ConnectUs

<p align="center">
  <strong>A modern real-time messaging application built with Flutter and Supabase.</strong>
</p>

<p align="center">
  ConnectUs is being developed as a polished, secure, and cross-platform
  one-to-one messaging application for Android and iOS.
</p>

<p align="center">
  <a href="https://flutter.dev">
    <img src="https://img.shields.io/badge/Flutter-3.44.8-02569B?logo=flutter" alt="Flutter">
  </a>
  <a href="https://dart.dev">
    <img src="https://img.shields.io/badge/Dart-3.12.2-0175C2?logo=dart" alt="Dart">
  </a>
  <a href="https://supabase.com">
    <img src="https://img.shields.io/badge/Backend-Supabase-3ECF8E?logo=supabase" alt="Supabase">
  </a>
  <a href="https://github.com/Vedant2402/ConnectUs">
    <img src="https://img.shields.io/badge/Day%201-Complete-brightgreen" alt="Day 1 complete">
  </a>
  <a href="https://github.com/Vedant2402/ConnectUs">
    <img src="https://img.shields.io/badge/Day%202-In%20Progress-orange" alt="Day 2 in progress">
  </a>
</p>

---

## Development Status

### Day 1 — Complete

Day 1 established the core foundation of ConnectUs.

The application now supports authentication, user profiles, unique usernames, user discovery, one-to-one conversation creation, real-time messaging, message receipts, and conversation history.

### Day 2 — In Progress

Day 2 focuses on improving the quality of the messaging experience.

Planned work includes unread-message tracking, typing indicators, real-time presence, message grouping, conversation updates, profile improvements, and additional interface polish.

---

## Overview

ConnectUs is a cross-platform real-time messaging application inspired by the simplicity and usability of modern communication platforms.

The first development phase focuses on creating a secure and stable messaging foundation where users can:

- Register using email and password
- Verify their email address
- Log in securely
- Create a public profile
- Select a unique username
- Search for people by username
- View another user’s profile
- Start private one-to-one conversations
- Reopen existing conversations
- Send and receive messages in real time
- View message timestamps
- View delivered and read states
- Access conversation history from the homepage
- Use a polished interface with lightweight animations

The project uses a single Flutter codebase for Android, iOS, and web-based development testing.

> ConnectUs is currently under active development and is not yet ready for production use.

---

## Current Progress

### Day 1 Deliverables

- [x] Flutter project setup
- [x] Git and GitHub repository setup
- [x] Responsive welcome screen
- [x] Registration interface
- [x] Login interface
- [x] Registration form validation
- [x] Login form validation
- [x] Supabase project connection
- [x] Supabase email registration
- [x] Email-verification support
- [x] Supabase email and password login
- [x] Secure local environment configuration
- [x] Animated login-success popup
- [x] Liquid Glass UI package initialization
- [x] Automatic profile-row creation
- [x] User profile setup
- [x] Unique username selection
- [x] Username normalization
- [x] Username uniqueness enforcement
- [x] Username-based user search
- [x] User profile preview
- [x] One-to-one conversation creation
- [x] Existing conversation reuse
- [x] Real-time text messaging
- [x] Chronological message ordering
- [x] Message persistence
- [x] Message timestamps
- [x] Delivered and read receipts
- [x] Conversation list
- [x] Latest-message preview
- [x] Latest-message time
- [x] Conversation reopening
- [x] Pull-to-refresh conversation list
- [x] Logout support
- [x] Supabase Row Level Security
- [x] Flutter static-analysis checks
- [x] Initial automated widget test

### Day 2 Work

- [ ] Real-time homepage conversation updates
- [ ] Unread-message counters
- [ ] Last-read message tracking
- [ ] Typing indicators
- [ ] Real-time online presence
- [ ] Last-seen information
- [ ] Conversation search
- [ ] Date separators inside chats
- [ ] Consecutive-message grouping
- [ ] Improved automatic scrolling
- [ ] Optimistic message sending
- [ ] Message retry handling
- [ ] Better loading placeholders
- [ ] Profile editing
- [ ] Settings screen
- [ ] Dark appearance mode
- [ ] Additional animations and motion polish

### Future Work

- [ ] Password reset
- [ ] Push notifications
- [ ] Message pagination
- [ ] Local message caching
- [ ] Profile photographs
- [ ] Android production build
- [ ] iOS production build
- [ ] Integration testing
- [ ] GitHub Actions

---

## Implemented Application Flow

```text
Welcome Screen
      |
      v
Register or Login
      |
      v
Email Verification
      |
      v
Profile and Username Setup
      |
      v
Conversations Home
      |
      v
Search Users by Username
      |
      v
Open User Profile
      |
      v
Create or Reuse Conversation
      |
      v
Real-Time Chat Screen
      |
      v
Conversation Appears on Home Screen
```

---

## Screens

### Welcome Screen

The welcome screen introduces ConnectUs and provides navigation to registration and login.

### Registration Screen

Users can:

- Enter an email address
- Create a password
- Confirm their password
- Register through Supabase Authentication
- Receive an email-verification link

### Login Screen

Verified users can:

- Enter their email address and password
- Show or hide their password
- Log in through Supabase Authentication
- View an animated Liquid Glass success popup
- Continue to profile setup when no username exists
- Continue to the conversation home when setup is complete

### Profile Setup Screen

Authenticated users can:

- Choose a unique username
- Enter a display name
- Create their ConnectUs identity
- Continue to the application after profile completion

### Conversations Home

The authenticated homepage displays:

- Existing one-to-one conversations
- The other user’s display name
- User avatars or generated initials
- Online-status indicators
- Latest-message previews
- Latest-message times
- Search and new-chat navigation
- Account and logout controls
- Empty, loading, and error states
- Pull-to-refresh support

### User Search

Users can:

- Search using normalized usernames
- View case-insensitive prefix results
- Open another user’s profile
- Exclude their own account from search results

### User Profile Preview

The profile-preview screen displays:

- Display name
- Username
- Biography when available
- Avatar or generated initial
- Online indicator
- Message button

### Real-Time Chat

The chat screen currently supports:

- Existing-message loading
- Real-time incoming messages
- Text-message sending
- Correct chronological ordering
- Message timestamps
- Sent, delivered, and read indicators
- Automatic scrolling
- Empty-chat state
- Error state
- Reopening existing conversations

---

## Technology Stack

| Layer | Technology | Purpose |
|---|---|---|
| Cross-platform framework | Flutter | Android, iOS, and web development |
| Language | Dart | Application development |
| Authentication | Supabase Auth | Registration, verification, login, and sessions |
| Backend | Supabase | Authentication, database, and real-time services |
| Database | PostgreSQL | Profiles, conversations, members, messages, and receipts |
| Real-time communication | Supabase Realtime | Instant message and receipt updates |
| Security | Supabase Row Level Security | Database-level access control |
| UI design | Material 3 | Base application design system |
| Glass effects | liquid_glass_widgets | Liquid Glass components and motion |
| Configuration | flutter_dotenv | Local environment-variable loading |
| Testing | flutter_test | Flutter widget and unit testing |
| Source control | Git and GitHub | Version control and project history |

---

## Repository Structure

```text
ConnectUs/
├── README.md
├── Phase_1_Real_Time_Chat_App_Official_Documentation_Final.pdf
└── connectus_app/
    ├── android/
    ├── ios/
    ├── lib/
    │   ├── app/
    │   │   └── connect_us_app.dart
    │   │
    │   ├── core/
    │   │   └── widgets/
    │   │       └── login_success_popup.dart
    │   │
    │   ├── features/
    │   │   ├── authentication/
    │   │   │   └── presentation/
    │   │   │       ├── login_screen.dart
    │   │   │       ├── register_screen.dart
    │   │   │       └── welcome_screen.dart
    │   │   │
    │   │   ├── profile/
    │   │   │   └── presentation/
    │   │   │       └── username_setup_screen.dart
    │   │   │
    │   │   ├── user_search/
    │   │   │   └── presentation/
    │   │   │       └── user_search_screen.dart
    │   │   │
    │   │   ├── conversations/
    │   │   │   └── presentation/
    │   │   │       └── home_screen.dart
    │   │   │
    │   │   └── chat/
    │   │       └── presentation/
    │   │           └── chat_screen.dart
    │   │
    │   └── main.dart
    │
    ├── test/
    ├── web/
    ├── .env.example
    ├── .gitignore
    ├── pubspec.yaml
    └── pubspec.lock
```

---

## Database Architecture

ConnectUs currently uses five main public tables.

### `profiles`

Stores public profile information connected to Supabase Authentication users.

Important fields:

- `id`
- `username`
- `username_normalized`
- `display_name`
- `bio`
- `avatar_url`
- `is_online`
- `last_seen_at`
- `created_at`
- `updated_at`

### `conversations`

Stores conversation metadata.

Important fields:

- `id`
- `type`
- `created_at`
- `updated_at`

The current implementation supports direct one-to-one conversations.

### `conversation_members`

Connects authenticated users to conversations.

Important fields:

- `conversation_id`
- `user_id`
- `joined_at`
- `last_read_message_id`
- `is_muted`

### `messages`

Stores messages sent inside conversations.

Important fields:

- `id`
- `conversation_id`
- `sender_id`
- `content`
- `message_type`
- `reply_to_message_id`
- `created_at`
- `edited_at`
- `deleted_at`

### `message_receipts`

Stores message delivery and read information for recipients.

Important fields:

- `message_id`
- `user_id`
- `delivered_at`
- `read_at`

---

## Database Functions and Triggers

### `handle_new_user`

Automatically creates a corresponding profile row when a new Supabase Authentication user registers.

### `set_profile_normalized_username`

Trims usernames, generates their normalized lowercase values, and updates profile timestamps.

### `create_or_get_direct_conversation`

Creates a one-to-one conversation between two users or returns the existing conversation when one already exists.

This prevents duplicate direct conversations between the same two users.

### `is_conversation_member`

Checks whether the authenticated user belongs to a requested conversation.

This helper is used by Row Level Security policies to avoid recursive membership-policy checks.

### `update_conversation_timestamp`

Updates a conversation’s `updated_at` value after a new message is inserted.

---

## Real-Time Architecture

Supabase Realtime is enabled for:

- `messages`
- `message_receipts`

The chat screen listens to the `messages` table using the active conversation ID.

When a recipient opens the conversation, the application creates or updates message-receipt rows. The sender’s chat screen listens for those receipt changes and updates the message indicator.

Current message-state behavior:

```text
One check       = Message sent
Two checks      = Message delivered or receipt created
Two blue checks = Message read
```

---

## Security

ConnectUs uses Supabase Row Level Security to protect application data.

Current security rules ensure that:

- Users can update only their own profiles.
- Authenticated users can view searchable user profiles.
- Users can view only conversations they belong to.
- Users can view conversation memberships only for their conversations.
- Users can view only messages inside their conversations.
- Users can send messages only inside their conversations.
- Message senders can update only their own messages.
- Users can create and update only their own receipt records.
- Direct conversations are created through a controlled database function.

Sensitive credentials must never be committed.

Never commit:

```text
.env
Database passwords
Supabase secret keys
Supabase service-role keys
Signing certificates
Private Firebase credentials
```

The `.env` file is ignored by Git.

The public `.env.example` file documents the required configuration without containing real credentials.

---

## Getting Started

### Prerequisites

Install the following tools:

- Flutter SDK
- Dart SDK
- Git
- Visual Studio Code or Android Studio
- Flutter and Dart editor extensions
- Android Studio for Android development
- Xcode and CocoaPods for iOS development on macOS

Check Flutter:

```bash
flutter --version
```

Check the development environment:

```bash
flutter doctor
```

---

## Clone the Repository

```bash
git clone https://github.com/Vedant2402/ConnectUs.git
```

Open the Flutter application:

```bash
cd ConnectUs/connectus_app
```

Install dependencies:

```bash
flutter pub get
```

---

## Supabase Configuration

ConnectUs uses Supabase for authentication, PostgreSQL storage, security policies, database functions, and real-time updates.

Create a local `.env` file inside:

```text
ConnectUs/connectus_app/.env
```

Copy the example configuration:

```bash
cp .env.example .env
```

Add the Supabase project URL and publishable client key:

```env
SUPABASE_URL=https://your-project-id.supabase.co
SUPABASE_PUBLISHABLE_KEY=your-publishable-key
```

The Flutter application should use only:

- Supabase project URL
- Supabase publishable client key

Never place these values inside the Flutter client:

- Database password
- Direct PostgreSQL password
- `service_role` key
- `sb_secret_...` key
- Private backend credentials

---

## Run the Application

### Web Development

```bash
flutter run -d chrome
```

Flutter launches its web debug target through Chrome.

The generated local development URL can also be opened manually in another Chromium-based browser such as Brave.

### List Available Devices

```bash
flutter devices
```

### Android

After installing Android Studio and creating an emulator:

```bash
flutter run
```

Select the Android emulator when prompted.

### iOS

After installing and configuring Xcode:

```bash
open -a Simulator
flutter run
```

---

## Code Quality

Format the application:

```bash
dart format lib test
```

Run static analysis:

```bash
flutter analyze
```

Run automated tests:

```bash
flutter test
```

A stable milestone should pass:

```bash
dart format lib test
flutter analyze
flutter test
```

---

## Git Workflow

Review all changes:

```bash
git status
```

Before committing, confirm that `.env` is not listed.

Stage changes:

```bash
git add .
```

Create a commit:

```bash
git commit -m "Describe the completed change"
```

Integrate remote changes safely:

```bash
git pull --rebase origin main
```

Push to GitHub:

```bash
git push origin main
```

Verify the final state:

```bash
git status
```

Expected result:

```text
On branch main
Your branch is up to date with 'origin/main'.

nothing to commit, working tree clean
```

---

## Development Roadmap

### Milestone 1 — Foundation

- [x] Flutter project setup
- [x] Application theme
- [x] Folder architecture
- [x] Supabase connection
- [x] GitHub repository
- [x] Static analysis and initial tests

### Milestone 2 — Accounts

- [x] Email registration
- [x] Email verification
- [x] Email login
- [x] Secure session support
- [x] Logout
- [ ] Password reset

### Milestone 3 — Identity

- [x] Unique usernames
- [x] Display names
- [x] Automatic profile creation
- [x] Username search
- [x] User profile preview
- [ ] Profile editing
- [ ] Profile photographs
- [ ] User biographies through settings

### Milestone 4 — Core Chat

- [x] One-to-one conversation creation
- [x] Existing conversation reuse
- [x] Conversation list
- [x] Real-time text messaging
- [x] Message persistence
- [x] Latest-message preview
- [x] Conversation reopening

### Milestone 5 — Messaging Quality

- [x] Sent-message state
- [x] Delivered-message state
- [x] Read-message state
- [ ] Typing indicators
- [ ] Unread counts
- [ ] Last-read tracking
- [ ] Message pagination
- [ ] Local message caching
- [ ] Retry handling
- [ ] Optimistic updates

### Milestone 6 — Presence and Profiles

- [ ] Real-time online presence
- [ ] Last-seen updates
- [ ] Profile editing
- [ ] Avatar uploads
- [ ] Conversation search
- [ ] Mute controls

### Milestone 7 — Visual Polish

- [x] Liquid Glass surfaces
- [x] Lightweight screen transitions
- [x] Empty, loading, and error states
- [ ] Message-entry animations
- [ ] Loading skeletons
- [ ] Haptic feedback
- [ ] Dark mode
- [ ] Accessibility improvements
- [ ] Mobile layout testing

### Milestone 8 — Release Preparation

- [ ] Firebase Cloud Messaging
- [ ] Crash reporting
- [ ] Integration testing
- [ ] Signed Android build
- [ ] iOS TestFlight build
- [ ] GitHub Actions
- [ ] Production documentation
- [ ] Security review

---

## Day 1 Milestone

```text
Day 1 Complete — Authentication, Profiles, User Search,
Conversations, and Real-Time Messaging
```

Day 1 completed the application’s core communication foundation.

Two users can now:

1. Register using email and password
2. Verify their email accounts
3. Log in securely
4. Choose unique usernames
5. Find each other through username search
6. View profile information
7. Start a private conversation
8. Exchange messages in real time
9. View delivered and read indicators
10. Return to the homepage and reopen the conversation

---

## Day 2 Plan

Day 2 focuses on improving the experience around the working messaging foundation.

Primary Day 2 tasks:

1. Add unread-message counters
2. Track the last-read message
3. Add typing indicators
4. Implement real online and offline presence
5. Display last-seen information
6. Update homepage conversations in real time
7. Add date separators
8. Group consecutive messages
9. Improve message scrolling behavior
10. Improve profile and settings functionality

---

## Phase 1 Definition of Done

Phase 1 will be considered complete when two users can:

1. Register using email and password
2. Verify their email accounts
3. Choose unique usernames
4. Find each other through username search
5. Start a private conversation
6. Exchange messages in real time
7. View delivery and read states
8. View unread-message counts
9. View typing and presence information
10. Receive message notifications
11. Reopen the application without losing message history

All user data must remain protected through Supabase Row Level Security policies.

---

## Planned Later Features

The following features are intentionally excluded from the initial messaging release:

- Phone-number authentication
- Group conversations
- Image and video messages
- Voice notes
- Audio calls
- Video calls
- Voice-command navigation
- Emergency commands
- AI assistant actions

These capabilities will be considered after the core one-to-one messaging experience is stable.

---

## Future Assistant Phase

A later phase of ConnectUs will introduce an assistant accessible from the homepage.

Planned assistant capabilities include:

- Opening chats through voice commands
- Finding users
- Navigating application screens
- Drafting messages
- Sending messages after confirmation
- Performing common in-app actions

Example command:

```text
Open Mummy's chat and send:
"Have you had your lunch?"
```

The assistant phase will begin only after the messaging foundation is stable and secure.

---

## Project Documentation

The complete Phase 1 technical stack, architecture, task list, milestones, and release criteria are available in:

```text
Phase_1_Real_Time_Chat_App_Official_Documentation_Final.pdf
```

---

## Contributing

ConnectUs is currently under active development.

Contribution guidelines, issue templates, coding standards, and pull-request instructions will be added before the project is opened for external contributions.

---

## Author

**Vedant Kankate**

GitHub: [@Vedant2402](https://github.com/Vedant2402)

---

## License

A project license has not yet been selected.

Until a license is added, the source code remains publicly viewable but is not automatically licensed for reuse, redistribution, or commercial use.
