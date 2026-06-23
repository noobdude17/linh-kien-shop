import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/config/app_config.dart';
import '../../../data/models/address_model.dart';
import '../../../data/repositories/address_repository.dart';
import '../../auth/providers/auth_providers.dart';

/// Tự chuyển Mock ↔ Firebase theo [AppConfig.firebaseEnabled].
final addressRepositoryProvider = Provider<AddressRepository>((ref) {
  if (AppConfig.firebaseEnabled) {
    return FirestoreAddressRepository(FirebaseFirestore.instance);
  }
  return MockAddressRepository();
});

/// Danh sách địa chỉ của user hiện tại (mặc định lên đầu).
final addressesProvider = StreamProvider<List<AddressModel>>((ref) {
  final user = ref.watch(currentUserProvider);
  if (user == null) return const Stream.empty();
  return ref.watch(addressRepositoryProvider).watch(user.id);
});
