import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:intl/intl.dart';

import '../constants/app_constants.dart';

/// Tạo URL thanh toán VNPay đã ký HMAC-SHA512 (chuẩn `vnp_SecureHash`, v2.1.0).
///
/// Đây chính là logic mà package `vnpay_flutter` làm bên trong — tự viết lại
/// (~10 dòng) để khỏi phải kéo theo webview plugin cũ làm vỡ build AGP 8.
/// Thông tin sandbox lấy từ [VnpayConfig].
///
/// Giá trị được URL-encode đồng nhất ở cả chuỗi ký lẫn query (space -> '+',
/// trùng cách `URLEncoder` của VNPay) nên hash khớp khi VNPay verify.
String buildVnpayUrl({
  required String txnRef,
  required double amount,
  required String orderInfo,
  String? bankCode, // 'VNPAYQR' -> vào thẳng màn QR; null -> để VNPay tự chọn
  String ipAddr = '127.0.0.1',
  DateTime? createdAt,
  Duration expiresIn = const Duration(minutes: 15),
}) {
  final now = createdAt ?? DateTime.now();
  final fmt = DateFormat('yyyyMMddHHmmss');
  final params = <String, String>{
    'vnp_Version': '2.1.0',
    'vnp_Command': 'pay',
    'vnp_TmnCode': VnpayConfig.tmnCode,
    'vnp_Amount': (amount * 100).toStringAsFixed(0), // VNPay tính theo *100
    'vnp_CreateDate': fmt.format(now),
    'vnp_CurrCode': 'VND',
    'vnp_IpAddr': ipAddr,
    'vnp_Locale': 'vn',
    'vnp_OrderInfo': orderInfo,
    'vnp_OrderType': 'other',
    'vnp_ReturnUrl': VnpayConfig.returnUrl,
    'vnp_ExpireDate': fmt.format(now.add(expiresIn)),
    'vnp_TxnRef': txnRef,
  };
  if (bankCode != null) params['vnp_BankCode'] = bankCode;

  final keys = params.keys.toList()..sort();
  final query = keys
      .map((k) => '$k=${Uri.encodeQueryComponent(params[k]!)}')
      .join('&');
  final secureHash = Hmac(sha512, utf8.encode(VnpayConfig.hashSecret))
      .convert(utf8.encode(query))
      .toString();
  return '${VnpayConfig.payUrl}?$query&vnp_SecureHash=$secureHash';
}
