import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:webview_flutter/webview_flutter.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/services/vnpay.dart';
import '../../../core/theme/app_colors.dart';
import '../../../data/models/order_model.dart';
import '../../../routes/app_routes.dart';
import '../providers/order_providers.dart';

/// Cổng thanh toán VNPay — mở trang SANDBOX (TEST) thật của VNPAY trong webview.
///
/// URL thanh toán được ký HMAC-SHA512 bằng [buildVnpayUrl]. Nếu đơn dùng
/// `payVnpayQr` thì truyền `vnp_BankCode=VNPAYQR` để vào thẳng màn QR.
/// Khi VNPay redirect về URL chứa `vnp_ResponseCode`, ta bắt lại: `00` → đánh
/// dấu đơn đã thanh toán và sang màn thành công; khác → báo lỗi, quay về giỏ.
///
/// Có dải log debug hiện ngay trên màn (khỏi cần console `flutter run`).
class VnpayGatewayScreen extends ConsumerStatefulWidget {
  const VnpayGatewayScreen({super.key});

  @override
  ConsumerState<VnpayGatewayScreen> createState() => _VnpayGatewayScreenState();
}

class _VnpayGatewayScreenState extends ConsumerState<VnpayGatewayScreen> {
  WebViewController? _controller;
  bool _loading = true;
  bool _handled = false; // tránh xử lý return 2 lần
  String? _error; // hiện lỗi thay vì spinner treo mãi
  String? _cancelMsg; // != null → hiện màn huỷ + nút thử lại
  String? _paymentUrl; // giữ lại để debug / thử lại
  Timer? _watchdog;
  final List<String> _log = []; // log hiện trên màn hình

  void _d(String s) {
    debugPrint('[VNPAY] $s');
    if (mounted) {
      setState(() {
        _log.add(s);
        if (_log.length > 12) _log.removeAt(0);
      });
    }
  }

  @override
  void initState() {
    super.initState();
    final order = ref.read(orderCreationProvider).valueOrNull;
    if (order == null) {
      _d('initState: order == null (không có đơn để thanh toán)');
      return;
    }

    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(Colors.white)
      ..setNavigationDelegate(NavigationDelegate(
        onProgress: (p) => _d('progress=$p%'),
        onPageStarted: (u) {
          _d('pageStarted: ${_short(u)}');
          if (mounted) setState(() => _loading = true);
        },
        onPageFinished: (u) {
          _d('pageFinished: ${_short(u)}');
          if (mounted) setState(() => _loading = false);
        },
        onUrlChange: (c) {
          _d('urlChange: ${_short(c.url ?? "")}');
          if (c.url != null && c.url!.contains('vnp_ResponseCode')) {
            _onReturn(c.url!);
          }
        },
        onWebResourceError: (e) {
          _d('ERR code=${e.errorCode} type=${e.errorType} '
              'mainFrame=${e.isForMainFrame} ${e.description}');
          if ((e.isForMainFrame ?? true) && mounted) {
            setState(() {
              _loading = false;
              _error = 'Không tải được trang VNPay: ${e.description} '
                  '(code ${e.errorCode})';
            });
          }
        },
        onHttpError: (e) =>
            _d('httpError status=${e.response?.statusCode} ${e.request?.uri}'),
        onNavigationRequest: (req) {
          _d('navRequest: ${_short(req.url)}');
          if (req.url.contains('vnp_ResponseCode')) {
            _onReturn(req.url);
            return NavigationDecision.prevent;
          }
          return NavigationDecision.navigate;
        },
      ));
    _loadPayment(order);

    // Nếu sau 25s vẫn quay tròn → bỏ spinner để lộ trang (giúp chẩn đoán).
    _watchdog = Timer(const Duration(seconds: 25), () {
      if (mounted && _loading) {
        _d('watchdog: vẫn loading sau 25s → ẩn spinner');
        setState(() => _loading = false);
      }
    });
  }

  /// Dựng URL ký HMAC (txnRef mới mỗi lần để VNPay không báo trùng) rồi nạp vào
  /// webview. Dùng cho cả lần đầu và khi bấm "Thử thanh toán lại".
  void _loadPayment(OrderModel order) {
    final isQr = order.paymentMethod == AppConstants.payVnpayQr;
    final url = buildVnpayUrl(
      txnRef: DateTime.now().millisecondsSinceEpoch.toString(),
      amount: order.totalAmount,
      orderInfo: 'ThanhToanDon${order.code}',
      bankCode: isQr ? 'VNPAYQR' : null,
    );
    _paymentUrl = url;
    _handled = false;
    _d('order=${order.code} amount=${order.totalAmount} isQr=$isQr');
    _controller?.loadRequest(Uri.parse(url));
  }

  void _retry() {
    final order = ref.read(orderCreationProvider).valueOrNull;
    if (order == null) return;
    setState(() {
      _cancelMsg = null;
      _error = null;
      _loading = true;
    });
    _loadPayment(order);
  }

  String _short(String u) => u.length > 60 ? '${u.substring(0, 60)}…' : u;

  @override
  void dispose() {
    _watchdog?.cancel();
    super.dispose();
  }

  void _onReturn(String url) {
    if (_handled) return;
    _handled = true;
    final code = Uri.parse(url).queryParameters['vnp_ResponseCode'];
    _d('return: code=$code');
    if (code == '00') {
      ref.read(orderCreationProvider.notifier).markCurrentPaid();
      if (mounted) context.go(AppRoutes.success);
    } else {
      // Huỷ/thất bại: KHÔNG đẩy về checkout (giỏ đã xoá → không trả lại được).
      // Hiện màn huỷ ngay tại đây để khách bấm thử thanh toán lại đơn đã tạo.
      if (mounted) {
        setState(() {
          _loading = false;
          _cancelMsg = 'Thanh toán chưa hoàn tất (mã $code). '
              'Đơn đã được tạo và đang chờ thanh toán.';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            _header(),
            if (_controller != null && _error == null && _cancelMsg == null)
              _testCardStrip(),
            Expanded(
              child: _controller == null
                  ? _noOrder()
                  : _error != null
                      ? _errorView()
                      : _cancelMsg != null
                          ? _cancelledView()
                          : Stack(
                              children: [
                                Positioned.fill(
                                    child: WebViewWidget(
                                        controller: _controller!)),
                                if (_loading)
                                  const Center(
                                      child: CircularProgressIndicator()),
                              ],
                            ),
            ),
            if (_controller != null) _debugStrip(),
          ],
        ),
      ),
    );
  }

  Widget _debugStrip() => Container(
        width: double.infinity,
        height: 110,
        color: Colors.black87,
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        child: ListView(
          reverse: true,
          children: _log.reversed
              .map((l) => Text('• $l',
                  style: const TextStyle(
                      color: Colors.greenAccent,
                      fontSize: 10,
                      fontFamily: 'monospace')))
              .toList(),
        ),
      );

  Widget _header() => Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration:
            const BoxDecoration(gradient: AppColors.vnpayGatewayGradient),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text.rich(TextSpan(children: [
              TextSpan(
                  text: 'VN',
                  style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w900,
                      fontSize: 20)),
              TextSpan(
                  text: 'PAY',
                  style: TextStyle(
                      color: AppColors.vnpOrange,
                      fontWeight: FontWeight.w900,
                      fontSize: 20)),
            ])),
            GestureDetector(
              onTap: () {
                _handled = true; // chặn return đang chờ
                setState(() {
                  _loading = false;
                  _cancelMsg = 'Bạn đã huỷ giao dịch. '
                      'Đơn vẫn được giữ và đang chờ thanh toán.';
                });
              },
              child: const Text('Huỷ giao dịch',
                  style: TextStyle(color: Colors.white70, fontSize: 13)),
            ),
          ],
        ),
      );

  /// Gợi ý thẻ test sandbox (chọn ngân hàng NCB trên trang VNPay).
  Widget _testCardStrip() => Container(
        width: double.infinity,
        color: const Color(0xFFFFF7E6),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        child: const Text(
          'Thẻ test (NCB): 9704198526191432198 · NGUYEN VAN A · 07/15 · OTP 123456',
          style: TextStyle(fontSize: 11, color: AppColors.textPrimary),
        ),
      );

  /// Màn lỗi + URL để debug (copy mở trên trình duyệt máy tính để so sánh).
  Widget _errorView() => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(_error!,
                style: const TextStyle(color: AppColors.error, fontSize: 13)),
            const SizedBox(height: 16),
            const Text('URL thanh toán (debug):',
                style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
            const SizedBox(height: 4),
            SelectableText(_paymentUrl ?? '-',
                style: const TextStyle(fontSize: 11)),
            const SizedBox(height: 16),
            Row(
              children: [
                ElevatedButton(
                  onPressed: () {
                    setState(() {
                      _error = null;
                      _loading = true;
                    });
                    if (_paymentUrl != null) {
                      _controller?.loadRequest(Uri.parse(_paymentUrl!));
                    }
                  },
                  child: const Text('Thử lại'),
                ),
                const SizedBox(width: 12),
                TextButton(
                  onPressed: () => context.go(AppRoutes.checkout),
                  child: const Text('Về giỏ hàng'),
                ),
              ],
            ),
          ],
        ),
      );

  /// Màn huỷ/thất bại — cho phép thử thanh toán lại đúng đơn đã tạo.
  Widget _cancelledView() => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.cancel_outlined,
                size: 56, color: AppColors.vnpOrange),
            const SizedBox(height: 16),
            Text(
              _cancelMsg ?? 'Giao dịch chưa hoàn tất.',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 14, color: AppColors.textPrimary),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _retry,
                child: const Text('Thử thanh toán lại'),
              ),
            ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: () => context.go(AppRoutes.orders),
              child: const Text('Xem đơn hàng của tôi'),
            ),
          ],
        ),
      );

  Widget _noOrder() => Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Không tìm thấy đơn hàng để thanh toán'),
            const SizedBox(height: 12),
            TextButton(
              onPressed: () => context.go(AppRoutes.cart),
              child: const Text('Về giỏ hàng'),
            ),
          ],
        ),
      );
}
