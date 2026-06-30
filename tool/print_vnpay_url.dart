// Debug helper: in URL thanh toán VNPay đã ký để kiểm thử bằng trình duyệt/curl.
// Chạy: dart run tool/print_vnpay_url.dart
import 'package:linh_kien_shop/core/services/vnpay.dart';

void main() {
  final url = buildVnpayUrl(
    txnRef: DateTime.now().millisecondsSinceEpoch.toString(),
    amount: 50000,
    orderInfo: 'ThanhToanDonTEST',
  );
  print(url);
}
