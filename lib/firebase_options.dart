import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show TargetPlatform, defaultTargetPlatform, kIsWeb;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) return web;

    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return ios;
      default:
        throw UnsupportedError('Platform is not supported by Firebase config.');
    }
  }

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: String.fromEnvironment(
      'FIREBASE_ANDROID_API_KEY',
      defaultValue: 'YOUR_ANDROID_API_KEY',
    ),
    appId: String.fromEnvironment(
      'FIREBASE_ANDROID_APP_ID',
      defaultValue: 'YOUR_ANDROID_APP_ID',
    ),
    messagingSenderId: String.fromEnvironment(
      'FIREBASE_MESSAGING_SENDER_ID',
      defaultValue: 'YOUR_SENDER_ID',
    ),
    projectId: String.fromEnvironment(
      'FIREBASE_PROJECT_ID',
      defaultValue: 'YOUR_PROJECT_ID',
    ),
    storageBucket: String.fromEnvironment(
      'FIREBASE_STORAGE_BUCKET',
      defaultValue: 'YOUR_PROJECT_ID.appspot.com',
    ),
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: String.fromEnvironment(
      'FIREBASE_IOS_API_KEY',
      defaultValue: 'YOUR_IOS_API_KEY',
    ),
    appId: String.fromEnvironment(
      'FIREBASE_IOS_APP_ID',
      defaultValue: 'YOUR_IOS_APP_ID',
    ),
    messagingSenderId: String.fromEnvironment(
      'FIREBASE_MESSAGING_SENDER_ID',
      defaultValue: 'YOUR_SENDER_ID',
    ),
    projectId: String.fromEnvironment(
      'FIREBASE_PROJECT_ID',
      defaultValue: 'YOUR_PROJECT_ID',
    ),
    storageBucket: String.fromEnvironment(
      'FIREBASE_STORAGE_BUCKET',
      defaultValue: 'YOUR_PROJECT_ID.appspot.com',
    ),
    iosBundleId: String.fromEnvironment(
      'FIREBASE_IOS_BUNDLE_ID',
      defaultValue: 'com.nhom.lks',
    ),
  );

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: String.fromEnvironment(
      'FIREBASE_WEB_API_KEY',
      defaultValue: 'YOUR_WEB_API_KEY',
    ),
    appId: String.fromEnvironment(
      'FIREBASE_WEB_APP_ID',
      defaultValue: 'YOUR_WEB_APP_ID',
    ),
    messagingSenderId: String.fromEnvironment(
      'FIREBASE_MESSAGING_SENDER_ID',
      defaultValue: 'YOUR_SENDER_ID',
    ),
    projectId: String.fromEnvironment(
      'FIREBASE_PROJECT_ID',
      defaultValue: 'YOUR_PROJECT_ID',
    ),
    authDomain: String.fromEnvironment(
      'FIREBASE_AUTH_DOMAIN',
      defaultValue: 'YOUR_PROJECT_ID.firebaseapp.com',
    ),
    storageBucket: String.fromEnvironment(
      'FIREBASE_STORAGE_BUCKET',
      defaultValue: 'YOUR_PROJECT_ID.appspot.com',
    ),
    measurementId: String.fromEnvironment(
      'FIREBASE_MEASUREMENT_ID',
      defaultValue: 'YOUR_MEASUREMENT_ID',
    ),
  );
}
