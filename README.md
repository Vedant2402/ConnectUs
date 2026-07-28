# ConnectUs

<p align="center">
  <strong>A modern real-time messaging application built with Flutter and Supabase.</strong>
</p>

<p align="center">
  ConnectUs is being developed as a polished, secure, and cross-platform
  one-to-one chat application for Android and iOS.
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
    <img src="https://img.shields.io/badge/Status-In%20Development-orange" alt="Project status">
  </a>
</p>

---

## Overview

ConnectUs is a cross-platform real-time messaging application inspired by the simplicity of modern messaging platforms.

The first development phase focuses on creating a stable messaging foundation where users can:

- Register using email and password
- Verify their email address
- Log in securely
- Create a unique username
- Search for people by username
- Start one-to-one conversations
- Send and receive messages in real time
- View typing indicators and message-read states
- Receive push notifications
- Use a polished interface with smooth animations
- Use light and dark appearance modes

The project uses a single Flutter codebase for Android and iOS.

> ConnectUs is currently under active development and is not yet ready for production use.

---

## Current Progress

The following functionality is currently implemented:

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
- [x] Initial automated widget test
- [x] Flutter static-analysis checks
- [ ] User profile creation
- [ ] Unique username selection
- [ ] Username search
- [ ] Conversation creation
- [ ] Real-time text messaging
- [ ] Read receipts
- [ ] Typing indicators
- [ ] Online presence
- [ ] Push notifications
- [ ] Android and iOS production builds

---

## Screens

The application currently includes:

### Welcome Screen

The first screen introduces ConnectUs and provides navigation to registration and login.

### Registration Screen

Users can:

- Enter an email address
- Create a password
- Confirm their password
- Register through Supabase Authentication
- Receive an email-verification link

### Login Screen

Verified users can:

- Enter their email and password
- Show or hide their password
- Log in through Supabase Authentication
- View an animated Liquid Glass success popup

### Conversations Home

The initial authenticated home screen is being prepared to contain:

- Conversation history
- Username search
- New-chat creation
- Profile and account controls
- Logout functionality

---

## Technology Stack

| Layer | Technology | Purpose |
|---|---|---|
| Mobile framework | Flutter | Cross-platform Android and iOS development |
| Language | Dart | Application development |
| Authentication | Supabase Auth | Registration, verification, login, and sessions |
| Backend | Supabase | Authentication, database, storage, and real-time services |
| Database | PostgreSQL | Users, profiles, conversations, and messages |
| Real-time communication | Supabase Realtime | Instant message and presence updates |
| UI design | Material 3 | Base application design system |
| Glass effects | liquid_glass_widgets | Shader-based Liquid Glass components and motion |
| Configuration | flutter_dotenv | Local environment-variable loading |
| Testing | flutter_test | Flutter widget and unit testing |
| Source control | Git and GitHub | Version control and collaboration |

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
    │   ├── core/
    │   │   └── widgets/
    │   ├── features/
    │   │   ├── authentication/
    │   │   │   └── presentation/
    │   │   │       ├── login_screen.dart
    │   │   │       ├── register_screen.dart
    │   │   │       └── welcome_screen.dart
    │   │   └── conversations/
    │   │       └── presentation/
    │   │           └── home_screen.dart
    │   └── main.dart
    ├── test/
    ├── web/
    ├── .env.example
    ├── .gitignore
    ├── pubspec.yaml
    └── pubspec.lock
```

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

Check your Flutter installation:

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

Open the Flutter application folder:

```bash
cd ConnectUs/connectus_app
```

Install dependencies:

```bash
flutter pub get
```

---

## Supabase Configuration

ConnectUs uses Supabase for authentication and backend services.

Create a local `.env` file inside:

```text
ConnectUs/connectus_app/.env
```

Copy the example file:

```bash
cp .env.example .env
```

Add your Supabase client configuration:

```env
SUPABASE_URL=https://your-project-id.supabase.co
SUPABASE_PUBLISHABLE_KEY=your-publishable-key
```

The `.env` file is ignored by Git and must not be committed.

### Never place these values in the Flutter application

- Database password
- Direct PostgreSQL connection password
- `service_role` key
- `sb_secret_...` key
- Private backend credentials

The Flutter client should use only the Supabase project URL and publishable client key.

---

## Run the Application

### Web

```bash
flutter run -d chrome
```

Flutter launches its web debug target through Chrome. The generated local URL can also be opened manually in another Chromium-based browser such as Brave.

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

Run static analysis:

```bash
flutter analyze
```

Run automated tests:

```bash
flutter test
```

Format the Dart code:

```bash
dart format lib test
```

A stable contribution should pass both:

```bash
flutter analyze
flutter test
```

---

## Git Workflow

After completing a stable change:

```bash
git status
git add .
git commit -m "Describe the completed change"
git push
```

Before committing, always verify that `.env` is not included:

```bash
git status
```

The public `.env.example` file should be committed, but the real `.env` file must remain local.

---

## Development Roadmap

### Milestone 1 — Foundation

- Flutter project setup
- Application theme
- Folder architecture
- Supabase connection
- GitHub repository
- Static analysis and tests

### Milestone 2 — Accounts

- Email registration
- Email verification
- Email login
- Password reset
- Secure session restoration
- Logout

### Milestone 3 — Identity

- Unique usernames
- Display names
- Profile photographs
- User biographies
- Username search

### Milestone 4 — Core Chat

- One-to-one conversation creation
- Conversation list
- Real-time text messaging
- Message persistence

### Milestone 5 — Messaging Quality

- Sent, delivered, and read states
- Typing indicators
- Unread counts
- Message pagination
- Local message caching
- Retry handling

### Milestone 6 — Visual Polish

- Liquid Glass surfaces
- Smooth screen transitions
- Message animations
- Loading placeholders
- Haptic feedback
- Dark mode
- Accessibility support

### Milestone 7 — Release Preparation

- Firebase Cloud Messaging
- Crash reporting
- Integration testing
- Signed Android build
- iOS TestFlight build
- Documentation
- GitHub Actions

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
8. Receive message notifications
9. Reopen the application without losing their messages

All user data must be protected using Supabase Row Level Security policies.

---

## Planned Later Features

The following features are intentionally excluded from the first release:

- Phone-number authentication
- Group conversations
- Image and video messages
- Voice notes
- Audio calls
- Video calls
- Voice-command navigation
- Emergency commands
- AI assistant actions

These features will be considered after the one-to-one messaging foundation is stable.

---

## Project Documentation

The complete Phase 1 technical stack, architecture, task list, milestones, and release criteria are available in:

```text
Phase_1_Real_Time_Chat_App_Official_Documentation_Final.pdf
```

---

## Security

Please do not publicly report security vulnerabilities through GitHub issues.

Never commit:

```text
.env
Database passwords
Supabase secret keys
Service-role keys
Signing certificates
Private Firebase credentials
```

A dedicated `SECURITY.md` policy will be added before the first public release.

---

## Contributing

ConnectUs is currently in its initial development phase.

Contribution guidelines, issue templates, coding standards, and pull-request instructions will be added as the project becomes ready for external contributors.

---

## Author

**Vedant Kankate**

GitHub: [@Vedant2402](https://github.com/Vedant2402)

---

## License

A project license has not been selected yet.

Until a license is added, the source code remains publicly viewable but is not automatically licensed for reuse, redistribution, or commercial use.
