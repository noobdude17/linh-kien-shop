import 'package:flutter_test/flutter_test.dart';
import 'package:linh_kien_shop/core/services/vnpay.dart';

void main() {
  final at = DateTime(2026, 6, 28, 10, 0, 0);

  test('signed url is deterministic and well-formed', () {
    final a = buildVnpayUrl(
        txnRef: '123', amount: 29800000, orderInfo: 'X', createdAt: at);
    final b = buildVnpayUrl(
        txnRef: '123', amount: 29800000, orderInfo: 'X', createdAt: at);
    expect(a, b); // cùng input -> cùng URL (ký xác định)
    expect(a, contains('vnp_Amount=2980000000')); // VNPay tính *100
    final hash = Uri.parse(a).queryParameters['vnp_SecureHash']!;
    expect(hash.length, 128); // HMAC-SHA512 = 128 hex
  });

  test('hash changes when amount changes', () {
    final a =
        buildVnpayUrl(txnRef: '1', amount: 100, orderInfo: 'X', createdAt: at);
    final b =
        buildVnpayUrl(txnRef: '1', amount: 200, orderInfo: 'X', createdAt: at);
    expect(Uri.parse(a).queryParameters['vnp_SecureHash'],
        isNot(Uri.parse(b).queryParameters['vnp_SecureHash']));
  });
}
