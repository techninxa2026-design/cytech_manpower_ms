# Cytech Manpower Management — Flutter Android

A branded, offline-first **Android UI preview** for Cytech Engineering. The application implements the approved Splash → Sign Up / Sign In → Workspace → Teams → Groups → Group Chat, Attendance and Complaints workflow.

## Demo mode (no domain or backend)

- Registration accepts a username and password UI, then creates a **regular local account**. Passwords are **not checked, stored or sent anywhere**.
- Sign-in intentionally bypasses verification. Blank/unrecognized usernames enter the **Admin demo** account; known demo usernames enter their own preview persona.
- Demo users: admin, ayesha (supervisor), fahim (engineer), rafi (member), nabila (supervisor in Project Delta).
- In **Profile**, switch demo personas to explore role-specific group permissions.
- Teams, groups, assignments, group messages, notices and complaints are stored **on this device only** using shared_preferences. No realtime synchronization, cloud service, API, remote database or push notifications exist.
- Group images use the Android gallery picker and store an optimized preview image locally. If no image is chosen, the app displays an illustrated group badge.

> Security note: all privileges are only a **local prototype demonstration**. Before deploying to real users, implement server-verified authentication and authorization, server-side validation and a shared backend. Do not use demo access or local shared_preferences as production access control.

## Current features

1. Cytech Engineering branding, real logo, splash screen, sign-in and sign-up.
2. Admin workspace with operational cards and recent updates.
3. Admin CRUD for teams; selection of multiple registered users.
4. Admin group creation with optional image and optional description.
5. Assign one or more members from teams to each group, with an assignment date and **Supervisor / Engineer / Member** role.
6. Group conversations for assigned people (and demo admin).
7. Highlighted official attendance notices (Admin and assigned Supervisor), selected date and per-member Present / Absent statuses.
8. Highlighted text-only engineering complaints (assigned Engineer), visible in Chat and Issues. Admin and Supervisor can set issue status Open / Under Review / Resolved.
9. Profile with account info, offline data notice, preview persona switcher and sign out.

## Run on Android

Install Flutter stable, Android SDK and emulator or Android device, then:

```bash
flutter pub get
flutter analyze
flutter test
flutter run -d android
```

If your device is plugged in by USB, enable USB debugging and run `flutter devices` first.

## Source structure

- `lib/core/app_store.dart` — local models, seed data, demo roles, CRUD and preferences.
- `lib/core/cytech_theme.dart` — orange/navy brand system, supplied logo and widgets.
- `lib/screens/entry_flow.dart` — onboarding and authentication UI.
- `lib/screens/main_shell.dart` — dashboard, team/group lists and persona profile.
- `lib/screens/management_pages.dart` — team, group and member assignment editor.
- `lib/screens/group_room.dart` — chat, attendance notices, issue board and report forms.
- `test/widget_test.dart` — offline role logic and basic interface tests.
- `.github/workflows/flutter-android.yml` — automated analyze, tests and Android debug APK.

**Android-only scope:** The repository retains the existing Flutter Android project, without adding iOS or web builds.
