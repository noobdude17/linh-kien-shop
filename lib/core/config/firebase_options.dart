import 'dart:convert';

import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show TargetPlatform, defaultTargetPlatform, kIsWeb;
import 'package:flutter/services.dart' show rootBundle;

class DefaultFirebaseOptions {
  static const _assetPath = 'assets/config/firebase_config.json';

  /// Config thô đã đọc từ asset (null nếu chạy mock). Dùng cho cấu hình ngoài
  /// Firebase, vd Cloudinary — tránh đọc lại file.
  static Map<String, dynamic>? rawConfig;

  static Future<FirebaseOptions> get currentPlatform async {
    final config = await _loadAssetConfig();
    rawConfig = config;
    if (config != null) return _fromMap(config);
    return _fromDartDefines();
  }

  static Future<Map<String, dynamic>?> _loadAssetConfig() async {
    try {
      final raw = await rootBundle.loadString(_assetPath);
      final decoded = jsonDecode(raw);
      if (decoded is! Map<String, dynamic>) {
        throw const FormatException('Firebase config must be a JSON object.');
      }
      return decoded;
    } catch (_) {
      return null;
    }
  }

  static FirebaseOptions _fromMap(Map<String, dynamic> config) {
    if (kIsWeb) {
      return FirebaseOptions(
        apiKey: _required(config, 'FIREBASE_WEB_API_KEY'),
        appId: _required(config, 'FIREBASE_WEB_APP_ID'),
        messagingSenderId: _required(config, 'FIREBASE_MESSAGING_SENDER_ID'),
        projectId: _required(config, 'FIREBASE_PROJECT_ID'),
        authDomain: _optional(config, 'FIREBASE_AUTH_DOMAIN'),
        storageBucket: _optional(config, 'FIREBASE_STORAGE_BUCKET'),
        measurementId: _optional(config, 'FIREBASE_MEASUREMENT_ID'),
      );
    }

    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return FirebaseOptions(
          apiKey: _required(config, 'FIREBASE_ANDROID_API_KEY'),
          appId: _required(config, 'FIREBASE_ANDROID_APP_ID'),
          messagingSenderId: _required(config, 'FIREBASE_MESSAGING_SENDER_ID'),
          projectId: _required(config, 'FIREBASE_PROJECT_ID'),
          storageBucket: _optional(config, 'FIREBASE_STORAGE_BUCKET'),
        );
      case TargetPlatform.iOS:
        return FirebaseOptions(
          apiKey: _required(config, 'FIREBASE_IOS_API_KEY'),
          appId: _required(config, 'FIREBASE_IOS_APP_ID'),
          messagingSenderId: _required(config, 'FIREBASE_MESSAGING_SENDER_ID'),
          projectId: _required(config, 'FIREBASE_PROJECT_ID'),
          storageBucket: _optional(config, 'FIREBASE_STORAGE_BUCKET'),
          iosBundleId: _optional(config, 'FIREBASE_IOS_BUNDLE_ID'),
        );
      default:
        throw UnsupportedError('Platform is not supported by Firebase config.');
    }
  }

  static FirebaseOptions _fromDartDefines() {
    FirebaseOptions opts;
    if (kIsWeb) {
      opts = web;
    } else {
      switch (defaultTargetPlatform) {
        case TargetPlatform.android:
          opts = android;
        case TargetPlatform.iOS:
          opts = ios;
        default:
          throw UnsupportedError(
            'Platform is not supported by Firebase config.',
          );
      }
    }
    // Placeholder values mean no real --dart-define was provided → throw so
    // main.dart catch block sets firebaseEnabled = false (mock mode).
    if (opts.apiKey.startsWith('YOUR_')) {
      throw StateError(
        'Firebase not configured. Provide assets/config/firebase_config.json '
        'or --dart-define=FIREBASE_*_API_KEY=<real-key>.',
      );
    }
    return opts;
  }

  static String _required(Map<String, dynamic> config, String key) {
    final value = _optional(config, key);
    if (value == null ||
        value.startsWith('your-') ||
        value.startsWith('YOUR_')) {
      throw StateError('Missing Firebase config value: $key');
    }
    return value;
  }

  static String? _optional(Map<String, dynamic> config, String key) {
    final value = config[key];
    if (value is! String || value.trim().isEmpty) return null;
    return value.trim();
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
