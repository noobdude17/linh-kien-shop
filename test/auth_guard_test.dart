import 'package:flutter_test/flutter_test.dart';
import 'package:linh_kien_shop/routes/app_routes.dart';
import 'package:linh_kien_shop/routes/auth_guard.dart';

// ponytail: chốt logic chặn truy cập — phần nhạy cảm (access control).
void main() {
  test('email chưa xác nhận → chặn ở mọi nơi trừ màn xác nhận', () {
    expect(
      authRedirect(
        loc: AppRoutes.home,
        loggedIn: true,
        emailVerified: false,
        profileComplete: true,
      ),
      AppRoutes.verifyEmail,
    );
    expect(
      authRedirect(
        loc: AppRoutes.verifyEmail,
        loggedIn: true,
        emailVerified: false,
        profileComplete: true,
      ),
      isNull,
    );
  });

  test('đã xác nhận mà còn ở màn xác nhận → về Home', () {
    expect(
      authRedirect(
        loc: AppRoutes.verifyEmail,
        loggedIn: true,
        emailVerified: true,
        profileComplete: true,
      ),
      AppRoutes.home,
    );
  });

  test('Google verified nhưng thiếu hồ sơ → hoàn tất hồ sơ', () {
    expect(
      authRedirect(
        loc: AppRoutes.home,
        loggedIn: true,
        emailVerified: true,
        profileComplete: false,
      ),
      AppRoutes.completeProfile,
    );
  });

  test('khách vào khu vực cần đăng nhập → Login (không dính bẫy verify)', () {
    expect(
      authRedirect(
        loc: AppRoutes.orders,
        loggedIn: false,
        emailVerified: true,
        profileComplete: false,
      ),
      AppRoutes.login,
    );
  });

  test('khách duyệt trang công khai → cho qua', () {
    expect(
      authRedirect(
        loc: AppRoutes.home,
        loggedIn: false,
        emailVerified: true,
        profileComplete: false,
      ),
      isNull,
    );
  });
}
