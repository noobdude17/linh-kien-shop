import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb;
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/config/app_config.dart';
import '../../../data/models/user_model.dart';
import '../../../data/repositories/auth_repository.dart';

/// Nguồn xác thực. Tự chuyển Mock ↔ Firebase theo cờ [AppConfig.useFirebase].
final authRepositoryProvider = Provider<AuthRepository>((ref) {
  if (AppConfig.firebaseEnabled) {
    return FirebaseAuthRepository(
        fb.FirebaseAuth.instance, FirebaseFirestore.instance);
  }
  return MockAuthRepository();
});

/// Trạng thái đăng nhập (null = chưa đăng nhập).
final authStateProvider = StreamProvider<UserModel?>((ref) {
  return ref.watch(authRepositoryProvider).authStateChanges();
});

/// User hiện tại (tiện đọc nhanh trong UI).
final currentUserProvider = Provider<UserModel?>((ref) {
  return ref.watch(authStateProvider).valueOrNull;
});
