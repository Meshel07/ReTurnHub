import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

/// Default [FirebaseOptions] for use with your Firebase apps.
///
/// Example:
/// ```dart
/// import 'firebase_options.dart';
/// // ...
/// await Firebase.initializeApp(
///   options: DefaultFirebaseOptions.currentPlatform,
/// );
/// ```
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
    apiKey: 'AIzaSyBS-uSh_hsNTp7IpG81FnVlMT12HCw3lxs',
    appId: '1:834788930124:web:15c14bd262ab9904cc3ae9',
    messagingSenderId: '834788930124',
    projectId: 'returnhub-8ef28',
    authDomain: 'returnhub-8ef28.firebaseapp.com',
    storageBucket: 'returnhub-8ef28.firebasestorage.app',
  );

  // Android configuration from google-services.json
  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyAMvprsiR8eqYouIM_7GXXY2zk_P_HTOOQ',
    appId: '1:834788930124:android:6c9ade00f8d40a35cc3ae9',
    messagingSenderId: '834788930124',
    projectId: 'returnhub-8ef28',
    storageBucket: 'returnhub-8ef28.firebasestorage.app',
  );

  // TODO: Add your iOS configuration from Firebase Console
  // Go to Firebase Console > Project Settings > Your iOS App
  // Download GoogleService-Info.plist and get the values from there
  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'YOUR_IOS_API_KEY',
    appId: 'YOUR_IOS_APP_ID',
    messagingSenderId: '834788930124',
    projectId: 'returnhub-8ef28',
    storageBucket: 'returnhub-8ef28.firebasestorage.app',
    iosBundleId: 'com.example.appfinal',
  );
}

