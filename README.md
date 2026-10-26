# Anchor Hub

An Android-first personal dashboard for tasks, spending, pantry expiry, and focus sessions. The light appearance uses clean white and cyan; dark mode uses near-black surfaces and bright cyan accents.

## Features

- **Today** summarizes due and completed tasks, monthly spending, and pantry items that need attention.
- **Upcoming** switches between the overdue/near-term timeline and a month calendar with per-day task lists.
- **Manage** includes searchable planner, expense, pantry, shopping, and habit views. Pantry items can be added to the shopping list for restocking.
- **Habits & Routines** lets you choose repeat days, log a single check-in, or track a routine step by step. It shows daily and weekly completion, saves history locally, and counts completed habits toward the activity streak.
- Tasks can repeat daily, weekly, or monthly. Completing an occurrence creates the next one; undoing it removes the still-open next occurrence.
- Expenses and budgets default to INR. Settings include USD/INR conversion with an editable exchange estimate; changing between USD and INR converts saved amounts and budgets.
- **Progress** shows weekly task and focus goals, current activity streak, and the focus timer offering 5, 15, 25, and 50 minute sessions.
- Swipe task, expense, and pantry rows to delete; use the Undo action in the confirmation bar to restore one.
- Tap the Today metrics to filter open/completed tasks or jump straight to expenses and pantry. Adjust numbered pantry quantities in place or mark an item used up.
- Android task and pantry reminders appear as system notifications at 9:00 AM. Task reminders are scheduled for the due date; pantry reminders are scheduled up to three days before expiry. Android notification permission is required, and battery settings may delay inexact reminders slightly.
- New installs get a short onboarding tour. Existing installs keep their saved data and skip it. Controls expose screen-reader labels, and animations respect the operating-system reduced-motion preference.
- Export and restore a versioned JSON backup from Settings, including recurring-task, shopping, habit, and routine history. Version 1 and 2 backups remain importable. Data is stored on the current device; there is no account or cloud sync.
- The web build stores data in the current browser and cannot schedule future local reminders. Browser data does not sync with Android.

## Run on Android

Install Flutter, Android Studio with the Android SDK, and an emulator or USB-connected Android phone. From this folder, run:

```sh
flutter pub get
flutter devices
flutter run -d <device-id>
```

Use the device ID printed by `flutter devices`. Keep the terminal open while testing; press `r` there for hot reload.

## Run in a desktop browser

```sh
flutter pub get
flutter run -d edge
```

Keep that terminal running. After saving Dart changes, Flutter usually reloads the page automatically; press `r` in the terminal if needed. Use `flutter devices` to see other browser targets.

## Prepare a Google Play release

Google Play uploads use a signed Android App Bundle. Create an upload keystore, copy `android/key.properties.example` to `android/key.properties`, and fill in the keystore path and passwords. The keystore and `key.properties` are ignored by Git. Keep a secure backup of the keystore and its passwords; you need the same upload key for future updates.

Build the bundle after signing is configured:

```sh
flutter build appbundle --release
```

The bundle is written to `build/app/outputs/bundle/release/app-release.aab`. Increase the build number in `pubspec.yaml` before each Play upload.

## Verify the project

```sh
flutter analyze
flutter test
```

## Project structure

- `lib/main.dart` — startup recovery, app theme, and app root
- `lib/screens/` — Today, Upcoming, Manage, Progress, and navigation screens
- `lib/widgets/` — cards, dialogs, animation helpers, and the focus timer
- `lib/models.dart` — task, expense, pantry, habit, settings, and focus-session models
- `lib/hub_state.dart` — state management, local persistence, and backup/restore
- `lib/reminder_service.dart` — Android task and pantry reminder scheduling
- `android/` and `web/` — platform-specific app configuration

## Possible next improvements

- Optional local reminders for habits and routines
- A safer file-based backup flow and optional encrypted export
- More accessibility checks and end-to-end testing on Android devices
