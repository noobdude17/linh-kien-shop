import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app.dart';
import 'core/config/firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await Firebase.initializeApp(
      options: await DefaultFirebaseOptions.currentPlatform,
    );
  } catch (e) {
    debugPrint('Firebase chưa cấu hình — chạy ở chế độ mock UI. ($e)');
  }
  runApp(const ProviderScope(child: App()));
}
