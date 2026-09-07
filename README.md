# Periods Tracker

A Flutter period tracking app with Firebase Authentication, Firestore-backed cycle data, local PIN/biometric app lock, cycle predictions, symptom logging, calendar views, and insights.

## Required Firebase Setup

This repository does not include Firebase project credentials. To run the authenticated app against your Firebase project:

1. Install and sign in to the Firebase CLI.
2. Enable Email/Password sign-in in Firebase Authentication.
3. Create a Firestore database.
4. Run:

   ```sh
   flutterfire configure
   ```

5. Commit the generated platform config files that are safe for your release process, including `lib/firebase_options.dart`, Android `google-services.json`, and iOS/macOS `GoogleService-Info.plist` as needed.
6. Update `lib/main.dart` to initialize Firebase with `DefaultFirebaseOptions.currentPlatform` after `flutterfire configure` generates `lib/firebase_options.dart`.
7. Deploy rules:

   ```sh
   firebase deploy --only firestore:rules
   ```

## Development

```sh
flutter pub get
flutter analyze
flutter test
flutter build web
```

## Privacy Notes

Cycle data and app preferences sync under each Firebase user account. The app lock is local to the device: the PIN itself is not stored in Firestore, and lock settings do not sync between devices.
