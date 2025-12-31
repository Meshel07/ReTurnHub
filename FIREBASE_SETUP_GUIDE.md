# Firebase Setup Guide for ReTurnHub Flutter App

This guide will walk you through setting up Firebase for your ReTurnHub Flutter application.

## Table of Contents
1. [Prerequisites](#prerequisites)
2. [Firebase Console Setup](#firebase-console-setup)
3. [Install FlutterFire CLI](#install-flutterfire-cli)
4. [Configure Firebase for Android](#configure-firebase-for-android)
5. [Configure Firebase for iOS](#configure-firebase-for-ios)
6. [Configure Firebase for Web](#configure-firebase-for-web)
7. [Add Firebase Packages](#add-firebase-packages)
8. [Initialize Firebase in Your App](#initialize-firebase-in-your-app)
9. [Test Your Setup](#test-your-setup)
10. [Next Steps](#next-steps)

---

## Prerequisites

Before starting, ensure you have:
- ✅ A Google account
- ✅ Flutter SDK installed (3.9.0 or higher)
- ✅ Dart SDK installed
- ✅ Android Studio / Xcode (for platform-specific setup)
- ✅ Node.js installed (for FlutterFire CLI)

---

## Firebase Console Setup

### Step 1: Create a Firebase Project

1. Go to [Firebase Console](https://console.firebase.google.com/)
2. Click **"Add project"** or **"Create a project"**
3. Enter your project name: **ReTurnHub**
4. (Optional) Enable Google Analytics
5. Click **"Create project"**
6. Wait for the project to be created, then click **"Continue"**

### Step 2: Note Your Project Details

- Keep the Firebase Console open
- You'll need to add your Android/iOS/Web apps to this project

---

## Install FlutterFire CLI

The FlutterFire CLI makes it easy to configure Firebase for your Flutter app.

### Step 1: Install FlutterFire CLI

Open your terminal and run:

```bash
dart pub global activate flutterfire_cli
```

### Step 2: Verify Installation

```bash
flutterfire --version
```

You should see the version number if installed correctly.

### Step 3: Login to Firebase

```bash
firebase login
```

This will open a browser window for you to authenticate with your Google account.

---

## Configure Firebase for Android

### Step 1: Register Android App in Firebase Console

1. In Firebase Console, click the **Android icon** (or "Add app")
2. Enter your Android package name:
   - Check `android/app/build.gradle.kts` for `applicationId`
   - Usually: `com.example.appfinal` or similar
3. (Optional) Enter app nickname: **ReTurnHub Android**
4. (Optional) Enter Debug signing certificate SHA-1 (for development)
5. Click **"Register app"**

### Step 2: Download google-services.json

1. Download the `google-services.json` file
2. Place it in: `android/app/google-services.json`

**Important:** Make sure the file is in `android/app/` directory, not `android/`

### Step 3: Update Android Build Files

#### Update `android/build.gradle.kts` (Project level)

Add the Google services classpath:

```kotlin
buildscript {
    repositories {
        google()
        mavenCentral()
    }
    dependencies {
        classpath("com.android.tools.build:gradle:8.1.0")
        classpath("org.jetbrains.kotlin:kotlin-gradle-plugin:1.9.0")
        // Add this line:
        classpath("com.google.gms:google-services:4.4.0")
    }
}
```

#### Update `android/app/build.gradle.kts` (App level)

Add at the **bottom** of the file:

```kotlin
plugins {
    id("com.android.application")
    id("kotlin-android")
    // Add this line:
    id("com.google.gms.google-services")
}
```

### Step 4: Set Minimum SDK Version

In `android/app/build.gradle.kts`, ensure minimum SDK is 21 or higher:

```kotlin
android {
    defaultConfig {
        minSdk = 21  // Required for Firebase
    }
}
```

---

## Configure Firebase for iOS

### Step 1: Register iOS App in Firebase Console

1. In Firebase Console, click the **iOS icon** (or "Add app")
2. Enter your iOS bundle ID:
   - Check `ios/Runner.xcodeproj` or `ios/Runner/Info.plist`
   - Usually: `com.example.appfinal` or similar
3. (Optional) Enter app nickname: **ReTurnHub iOS**
4. Click **"Register app"**

### Step 2: Download GoogleService-Info.plist

1. Download the `GoogleService-Info.plist` file
2. Open Xcode: `open ios/Runner.xcworkspace`
3. Right-click on the `Runner` folder in Xcode
4. Select **"Add Files to Runner"**
5. Select the downloaded `GoogleService-Info.plist`
6. Make sure **"Copy items if needed"** is checked
7. Click **"Add"**

**Important:** The file must be in the `Runner` folder, not a subfolder.

### Step 3: Update iOS Deployment Target

In Xcode:
1. Select the **Runner** project
2. Go to **Build Settings**
3. Set **iOS Deployment Target** to **12.0** or higher

Or in `ios/Podfile`, ensure:

```ruby
platform :ios, '12.0'
```

### Step 4: Install CocoaPods Dependencies

```bash
cd ios
pod install
cd ..
```

---

## Configure Firebase for Web

### Step 1: Register Web App in Firebase Console

1. In Firebase Console, click the **Web icon** (</>)
2. Enter app nickname: **ReTurnHub Web**
3. (Optional) Check "Also set up Firebase Hosting"
4. Click **"Register app"**

### Step 2: Copy Firebase Configuration

You'll see a configuration object. Copy it for later use.

### Step 3: Update `web/index.html`

Add Firebase SDK scripts before the closing `</body>` tag:

```html
<!-- Add before </body> -->
<script src="https://www.gstatic.com/firebasejs/10.7.1/firebase-app-compat.js"></script>
<script src="https://www.gstatic.com/firebasejs/10.7.1/firebase-auth-compat.js"></script>
<script src="https://www.gstatic.com/firebasejs/10.7.1/firebase-firestore-compat.js"></script>
<script src="https://www.gstatic.com/firebasejs/10.7.1/firebase-storage-compat.js"></script>

<script>
  // Your Firebase config will be added here by FlutterFire CLI
  // Or add manually:
  const firebaseConfig = {
    apiKey: "YOUR_API_KEY",
    authDomain: "YOUR_PROJECT_ID.firebaseapp.com",
    projectId: "YOUR_PROJECT_ID",
    storageBucket: "YOUR_PROJECT_ID.appspot.com",
    messagingSenderId: "YOUR_MESSAGING_SENDER_ID",
    appId: "YOUR_APP_ID"
  };
  firebase.initializeApp(firebaseConfig);
</script>
```

---

## Add Firebase Packages

### Step 1: Update `pubspec.yaml`

Add Firebase packages to your `pubspec.yaml`:

```yaml
dependencies:
  flutter:
    sdk: flutter
  
  # Firebase Core
  firebase_core: ^2.24.2
  
  # Firebase Services (add as needed)
  firebase_auth: ^4.15.3
  cloud_firestore: ^4.13.6
  firebase_storage: ^11.5.6
  firebase_messaging: ^14.7.9  # For push notifications
  
  # Other existing dependencies
  cupertino_icons: ^1.0.8
  image_picker: ^1.0.7
  http: ^1.1.0
```

### Step 2: Install Packages

Run in your terminal:

```bash
flutter pub get
```

---

## Initialize Firebase in Your App

### Step 1: Update `lib/main.dart`

Update your `main.dart` to initialize Firebase:

```dart
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart'; // This will be generated
import 'auth/splash_page.dart';
// ... other imports

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize Firebase
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  
  runApp(const ReTurnHubApp());
}
```

### Step 2: Generate Firebase Options (Recommended)

Use FlutterFire CLI to automatically configure Firebase:

```bash
# From your project root directory
flutterfire configure
```

This command will:
- Detect your Firebase projects
- Let you select which project to use
- Automatically configure all platforms
- Generate `lib/firebase_options.dart`

**Alternative:** If you prefer manual setup, create `lib/firebase_options.dart` manually (see below).

### Step 3: Manual Firebase Options (If not using CLI)

Create `lib/firebase_options.dart`:

```dart
import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      return web;
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return ios;
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not supported for this platform.',
        );
    }
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'YOUR_WEB_API_KEY',
    appId: 'YOUR_WEB_APP_ID',
    messagingSenderId: 'YOUR_MESSAGING_SENDER_ID',
    projectId: 'YOUR_PROJECT_ID',
    authDomain: 'YOUR_PROJECT_ID.firebaseapp.com',
    storageBucket: 'YOUR_PROJECT_ID.appspot.com',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'YOUR_ANDROID_API_KEY',
    appId: 'YOUR_ANDROID_APP_ID',
    messagingSenderId: 'YOUR_MESSAGING_SENDER_ID',
    projectId: 'YOUR_PROJECT_ID',
    storageBucket: 'YOUR_PROJECT_ID.appspot.com',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'YOUR_IOS_API_KEY',
    appId: 'YOUR_IOS_APP_ID',
    messagingSenderId: 'YOUR_MESSAGING_SENDER_ID',
    projectId: 'YOUR_PROJECT_ID',
    storageBucket: 'YOUR_PROJECT_ID.appspot.com',
    iosBundleId: 'YOUR_IOS_BUNDLE_ID',
  );
}
```

Replace the placeholder values with your actual Firebase configuration from:
- Android: `google-services.json`
- iOS: `GoogleService-Info.plist`
- Web: Firebase Console web app settings

---

## Test Your Setup

### Step 1: Run the App

```bash
flutter run
```

### Step 2: Check for Errors

- ✅ No Firebase initialization errors
- ✅ App runs without crashes
- ✅ Check console for Firebase connection messages

### Step 3: Verify Firebase Connection

Add a test in your app to verify Firebase is connected:

```dart
// In your splash_page.dart or any page
import 'package:firebase_core/firebase_core.dart';

// Check if Firebase is initialized
if (Firebase.apps.isNotEmpty) {
  print('Firebase initialized successfully!');
  print('Firebase app name: ${Firebase.app().name}');
}
```

---

## Next Steps

### 1. Enable Firebase Services

In Firebase Console, enable the services you need:

- **Authentication**: Enable Email/Password, Google, etc.
- **Firestore Database**: Create your database
- **Storage**: For file uploads
- **Cloud Messaging**: For push notifications

### 2. Update Your Services

Update your service files to use Firebase:

- `lib/services/auth_service.dart` - Use Firebase Auth
- `lib/services/api_service.dart` - Use Firestore
- `lib/services/chat_service.dart` - Use Firestore for messages

### 3. Set Up Firestore Security Rules

Go to Firebase Console → Firestore Database → Rules

Example rules for development:

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    // Allow read/write access to all documents (for development only)
    match /{document=**} {
      allow read, write: if request.auth != null;
    }
  }
}
```

**⚠️ Important:** Update these rules for production!

### 4. Set Up Firebase Storage Rules

Go to Firebase Console → Storage → Rules

Example rules:

```javascript
rules_version = '2';
service firebase.storage {
  match /b/{bucket}/o {
    match /{allPaths=**} {
      allow read: if request.auth != null;
      allow write: if request.auth != null;
    }
  }
}
```

---

## Troubleshooting

### Common Issues

1. **"FirebaseApp not initialized"**
   - Ensure `Firebase.initializeApp()` is called before `runApp()`
   - Check that `firebase_options.dart` exists and is correct

2. **Android: "google-services.json not found"**
   - Verify file is in `android/app/google-services.json`
   - Check that Google services plugin is applied in `build.gradle.kts`

3. **iOS: "GoogleService-Info.plist not found"**
   - Verify file is added to Xcode project
   - Check file is in `Runner` folder (not subfolder)

4. **Build errors**
   - Run `flutter clean`
   - Run `flutter pub get`
   - For iOS: `cd ios && pod install && cd ..`

5. **Package version conflicts**
   - Check `pubspec.lock` for version conflicts
   - Use `flutter pub upgrade` to update packages

---

## Additional Resources

- [FlutterFire Documentation](https://firebase.flutter.dev/)
- [Firebase Console](https://console.firebase.google.com/)
- [FlutterFire CLI](https://firebase.flutter.dev/docs/cli/)
- [Firebase Authentication](https://firebase.google.com/docs/auth)
- [Cloud Firestore](https://firebase.google.com/docs/firestore)
- [Firebase Storage](https://firebase.google.com/docs/storage)

---

## Quick Command Reference

```bash
# Install FlutterFire CLI
dart pub global activate flutterfire_cli

# Configure Firebase
flutterfire configure

# Install packages
flutter pub get

# Clean and rebuild
flutter clean
flutter pub get
flutter run

# iOS specific
cd ios && pod install && cd ..
```

---

**🎉 Congratulations!** Your Firebase setup is complete. You can now start using Firebase services in your ReTurnHub app!

