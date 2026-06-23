import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app.dart';
import 'core/config/app_config.dart';
import 'core/config/firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await Firebase.initializeApp(
      options: await DefaultFirebaseOptions.currentPlatform,
    );
    AppConfig.firebaseEnabled = true; // có config hợp lệ → dùng backend thật
    final cfg = DefaultFirebaseOptions.rawConfig;
    AppConfig.cloudinaryCloudName = cfg?['CLOUDINARY_CLOUD_NAME'] ?? '';
    AppConfig.cloudinaryUploadPreset = cfg?['CLOUDINARY_UPLOAD_PRESET'] ?? '';
  } catch (e) {
    AppConfig.firebaseEnabled = false; // chưa có config → chạy mock
    debugPrint('Firebase chưa cấu hình — chạy ở chế độ mock UI. ($e)');
  }
  runApp(const ProviderScope(child: App()));
}
