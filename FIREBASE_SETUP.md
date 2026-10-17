# BorrowNow — Firebase Integration Guide

This document outlines the steps to connect the **BorrowNow** Flutter application to Firebase for production backend operation.

---

## 1. Prerequisites
- [Firebase CLI](https://firebase.google.com/docs/cli) installed (`npm install -g firebase-tools`)
- FlutterFire CLI installed (`dart pub global activate flutterfire_cli`)

---

## 2. Fast Automatic Configuration (Recommended)
Run the following command in the root folder of the project:
```bash
flutterfire configure --project=<your-firebase-project-id>
```
Select `android`, `ios`, and `web`. This generates `lib/firebase_options.dart` automatically.

Then update `lib/main.dart`:
```dart
import 'firebase_options.dart';

await Firebase.initializeApp(
  options: DefaultFirebaseOptions.currentPlatform,
);
```

---

## 3. Manual Android Configuration
1. Go to the [Firebase Console](https://console.firebase.google.com/).
2. Create or select a project named **BorrowNow**.
3. Add an Android app with package name:
   `com.borrownow.app.borrow_now`
4. Download `google-services.json` and place it in:
   `android/app/google-services.json`
5. Ensure `android/build.gradle.kts` has the Google Services classpath:
   ```kotlin
   buildscript {
       dependencies {
           classpath("com.google.gms:google-services:4.4.2")
       }
   }
   ```
6. In `android/app/build.gradle.kts`, apply the plugin:
   ```kotlin
   plugins {
       id("com.android.application")
       id("dev.flutter.flutter-gradle-plugin")
       id("com.google.gms.google-services")
   }
   ```

---

## 4. Deploying Firestore & Storage Security Rules
Run the following from your terminal:
```bash
firebase deploy --only firestore:rules,storage:rules
```
The application comes pre-configured with secure rules:
- `firestore.rules`: Protects student ID cards, roles, item availability, and transactions.
- `storage.rules`: Ensures college ID card images can only be inspected by authorized campus admins and the student.

---

## 5. Firebase Authentication Setup
1. In the Firebase Console, go to **Authentication** > **Sign-in method**.
2. Enable **Email/Password**.

---

## 6. Cloud Firestore Setup
1. In the Firebase Console, go to **Firestore Database** > **Create database**.
2. Select **Production Mode**.
3. Choose the closest cloud region to your campus.

---

## 7. Firebase Storage Setup
1. In the Firebase Console, go to **Storage** > **Get Started**.
2. Choose **Production Mode**.

---

## 8. Firebase Cloud Messaging (FCM)
Push notification permissions and channels are pre-configured in `lib/services/notification_service.dart`. Once `google-services.json` is attached, FCM tokens can be received automatically.
