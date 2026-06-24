class AppConstants {
  static const appName = 'Linh Kiện Shop';

  // Firestore collections
  static const colUsers = 'users';
  static const colProducts = 'products';
  static const colCategories = 'categories';
  static const colOrders = 'orders';
  static const colCart = 'cart';
  static const colReviews = 'reviews'; // subcollection products/{id}/reviews
  static const colAddresses = 'addresses'; // subcollection users/{uid}/addresses

  // Order status
  static const statusPending = 'pending';
  static const statusConfirmed = 'confirmed';
  static const statusShipping = 'shipping';
  static const statusDelivered = 'delivered';
  static const statusCancelled = 'cancelled';

  // User roles
  static const roleCustomer = 'customer';
  static const roleAdmin = 'admin';

  // Payment methods
  static const payVnpay = 'vnpay';
  static const payCod = 'cod';

  // Misc
  static const currencySuffix = 'đ';
  static const freeShipLabel = 'Miễn phí';
}

/// Nhãn tiếng Việt cho trạng thái đơn hàng (dùng cho badge/timeline).
class OrderStatusLabel {
  OrderStatusLabel._();
  static const map = {
    AppConstants.statusPending: 'Chờ xác nhận',
    AppConstants.statusConfirmed: 'Đã xác nhận',
    AppConstants.statusShipping: 'Đang giao',
    AppConstants.statusDelivered: 'Hoàn thành',
    AppConstants.statusCancelled: 'Đã hủy',
  };
}
