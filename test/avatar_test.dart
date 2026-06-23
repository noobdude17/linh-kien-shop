import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:linh_kien_shop/data/models/user_model.dart';
import 'package:linh_kien_shop/data/repositories/auth_repository.dart';

// Chốt chiến lược avatar: Firestore CHỈ lưu ảnh tự tải lên (custom); avatar
// Google đọc live từ Auth, không persist. Nếu ai đó thêm photoUrl vào
// toFirestore() thì URL Google sẽ bị lưu và phá thứ tự ưu tiên → test này chặn.
void main() {
  const u = UserModel(
    id: '1', name: 'A', email: 'a@x.com', role: 'customer',
    photoUrl: 'https://google/avatar.jpg',
  );

  test('toFirestore KHÔNG ghi photoUrl', () {
    expect(u.toFirestore().containsKey('photoUrl'), isFalse);
  });

  test('copyWith đặt/giữ photoUrl', () {
    expect(u.copyWith(photoUrl: 'https://cloudinary/x.jpg').photoUrl,
        'https://cloudinary/x.jpg');
    expect(u.copyWith(name: 'B').photoUrl, u.photoUrl); // giữ khi sửa field khác
  });

  test('Mock updateAvatar lưu ảnh vào hồ sơ', () async {
    final repo = MockAuthRepository();
    await repo.signIn(email: 'demo@lks.vn', password: '123456');
    final r = await repo.updateAvatar(File('/tmp/pic.jpg'));
    expect(r.photoUrl, '/tmp/pic.jpg');
    expect(repo.currentUser?.photoUrl, '/tmp/pic.jpg');
  });
}
