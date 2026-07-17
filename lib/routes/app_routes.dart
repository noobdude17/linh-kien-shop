/// Tên & đường dẫn route cho toàn bộ 31 màn (theo nav graph trong handoff).
/// Dùng hằng số này thay vì gõ chuỗi path trực tiếp.
class AppRoutes {
  AppRoutes._();

  // A · Onboarding & Auth
  static const splash = '/splash';
  static const onboarding = '/onboarding';
  static const login = '/login';
  static const register = '/register';
  static const forgot = '/forgot';
  static const verifyEmail = '/verify-email';
  static const completeProfile = '/complete-profile';

  // B · Home & Browse
  static const home = '/home';
  static const categories = '/categories';
  static const search = '/search';
  static const list = '/list'; // product list (?categoryId=)
  static const results = '/results'; // search results (?q=)
  static const empty = '/empty'; // empty search results
  static const partPicker = '/part-picker';
  static const partPickerSelect = '/part-picker/select';

  // C · Product Detail
  static const detail = '/detail'; // /detail/:id
  static const compare = '/compare';

  // D · Cart & Checkout
  static const cart = '/cart';
  static const checkout = '/checkout';
  static const vnpay = '/vnpay';
  static const processing = '/processing';
  static const success = '/success';

  // E · Account & Orders
  static const profile = '/profile';
  static const editProfile = '/profile/edit';
  static const orders = '/orders';
  static const orderDetail = '/orders/detail'; // /orders/detail/:id
  static const addresses = '/addresses';
  static const addAddress = '/addresses/add';
  static const wishlist = '/wishlist';
  static const wishlistEmpty = '/wishlist/empty';
  static const notifications = '/notifications';

  // F · Admin
  static const admin = '/admin';
  static const adminProducts = '/admin/products';
  static const adminProductEdit = '/admin/products/edit';
  static const adminOrders = '/admin/orders';
  static const adminOrderDetail = '/admin/orders/detail';
  static const adminUsers = '/admin/users';
  static const adminReviews = '/admin/reviews';
}
