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
  static const payVnpayQr = 'vnpay_qr'; // VNPay -> thẳng vào QR (vnp_BankCode=VNPAYQR)
  static const payCod = 'cod';

  // Misc
  static const currencySuffix = 'đ';
  static const freeShipLabel = 'Miễn phí';
}

/// VNPay SANDBOX (môi trường TEST của VNPAY). KHÔNG phải production.
/// Dùng để chứng minh app kết nối được tới cổng thanh toán VNPay.
// ponytail: hash secret nằm ở client — chấp nhận được cho demo sandbox;
// production phải ký (sign) + nhận IPN ở server. Nâng cấp khi lên thật.
class VnpayConfig {
  VnpayConfig._();
  static const tmnCode = '9UFLNCBZ';
  static const hashSecret = 'KY4RBY8YTM8PJO28M13WGJY46OR9U3W7';
  static const payUrl = 'https://sandbox.vnpayment.vn/paymentv2/vpcpay.html';
  // URL trả về (giả) — webview chỉ cần bắt được vnp_ResponseCode trên đó.
  static const returnUrl = 'https://return.lkshop.vn/vnpay';
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
