import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/config/app_config.dart';
import '../../../data/models/review_model.dart';
import '../../../data/repositories/review_repository.dart';

final reviewRepositoryProvider = Provider<ReviewRepository>((ref) {
  if (AppConfig.firebaseEnabled) {
    return FirestoreReviewRepository(FirebaseFirestore.instance);
  }
  return MockReviewRepository();
});

final reviewProvider = FutureProvider.family<List<ReviewModel>, String>((
  ref,
  productId,
) {
  return ref.watch(reviewRepositoryProvider).getForProduct(productId);
});
