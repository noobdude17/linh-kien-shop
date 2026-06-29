import 'package:flutter_test/flutter_test.dart';
import 'package:linh_kien_shop/data/repositories/auth_repository.dart';

// ponytail: chỉ chốt logic validate của mock — bug "email bừa cũng vào".
void main() {
  test('Mock login từ chối tài khoản không tồn tại / sai mật khẩu', () async {
    final repo = MockAuthRepository();

    expect(
      () => repo.signIn(email: 'random@x.com', password: 'whatever'),
      throwsA(anything),
    );
    expect(
      () => repo.signIn(email: 'demo@lks.vn', password: 'sai'),
      throwsA(anything),
    );

    final u = await repo.signIn(email: 'demo@lks.vn', password: '123456');
    expect(u.email, 'demo@lks.vn');
  });
}
