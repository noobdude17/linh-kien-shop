import 'app_routes.dart';

/// Route CẦN đăng nhập (theo prefix). Khách (guest) duyệt thoải mái phần còn lại;
/// chỉ chặn khu vực tài khoản, đặt hàng và admin.
const _protectedPrefixes = <String>[
  // /profile (tab Tài khoản) cho khách vào được — màn tự hiện prompt đăng nhập.
  AppRoutes.editProfile, // /profile/edit
  AppRoutes.orders, // gồm /orders/detail/:id
  AppRoutes.addresses, // gồm /addresses/add
  AppRoutes.wishlist,
  AppRoutes.notifications,
  AppRoutes.checkout,
  AppRoutes.vnpay,
  AppRoutes.processing,
  AppRoutes.admin, // gồm /admin/*
];

bool needsAuth(String loc) =>
    _protectedPrefixes.any((p) => loc == p || loc.startsWith('$p/'));

bool needsAdmin(String loc) =>
    loc == AppRoutes.admin || loc.startsWith('${AppRoutes.admin}/');

/// Quyết định điều hướng theo trạng thái — tách thuần (không phụ thuộc context)
/// để test được. Trả `null` = cho phép ở lại [loc].
String? authRedirect({
  required String loc,
  required bool loggedIn,
  required bool emailVerified,
  required bool profileComplete,
  bool isAdmin = false,
  bool isLocked = false,
}) {
  // Splash & onboarding tự điều hướng, không chặn.
  if (loc == AppRoutes.splash || loc == AppRoutes.onboarding) return null;

  // Đã đăng nhập nhưng email chưa xác nhận → buộc xác nhận email.
  // (Tài khoản Google luôn verified nên đi thẳng — đồng nhất trải nghiệm.)
  if (loggedIn && !emailVerified) {
    return loc == AppRoutes.verifyEmail ? null : AppRoutes.verifyEmail;
  }
  // Đã xác nhận mà còn nán ở màn xác nhận → vào Home.
  if (loggedIn && loc == AppRoutes.verifyEmail) return AppRoutes.home;

  // Tài khoản bị khóa mềm: không cho đi tiếp vào app.
  if (loggedIn && isLocked) {
    return loc == AppRoutes.login ? null : AppRoutes.login;
  }

  if (loggedIn && needsAdmin(loc) && !isAdmin) return AppRoutes.home;

  // Đã đăng nhập nhưng thiếu thông tin (vd: đăng nhập Google) → buộc hoàn tất.
  if (loggedIn && !profileComplete && loc != AppRoutes.completeProfile) {
    return AppRoutes.completeProfile;
  }

  // Khách vào khu vực cần đăng nhập → chuyển sang Login.
  if (!loggedIn && needsAuth(loc)) return AppRoutes.login;

  // Đã đăng nhập mà còn ở Login/Register → về Home.
  if (loggedIn && (loc == AppRoutes.login || loc == AppRoutes.register)) {
    return AppRoutes.home;
  }
  return null;
}
