class AppConstants {
  static const appName = 'Linh Kiện Shop';

  // Firestore collections
  static const colUsers = 'users';
  static const colProducts = 'products';
  static const colCategories = 'categories';
  static const colOrders = 'orders';
  static const colCart = 'cart';

  // Order status
  static const statusPending = 'pending';
  static const statusConfirmed = 'confirmed';
  static const statusShipping = 'shipping';
  static const statusDelivered = 'delivered';
  static const statusCancelled = 'cancelled';

  // User roles
  static const roleCustomer = 'customer';
  static const roleAdmin = 'admin';
}
