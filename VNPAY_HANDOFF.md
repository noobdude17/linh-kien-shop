# VNPay Sandbox Integration — Handoff

> Branch: `vnpay`. Mục tiêu: chứng minh app **kết nối thật** tới cổng thanh toán
> VNPay (môi trường SANDBOX/TEST) — đủ để demo cho giáo viên. Sandbox không trừ
> tiền thật, chỉ cần chứng minh luồng kết nối hoạt động.

## TL;DR trạng thái hiện tại
- ✅ **Logic tích hợp ĐÚNG HOÀN TOÀN.** URL thanh toán ký HMAC-SHA512 mở ra
  đúng trang chọn ngân hàng VNPay khi dán vào **Chrome trên PC**.
- ✅ Chữ ký đã được verify độc lập (PowerShell .NET HMACSHA512) → khớp byte.
- ❌ **BLOCKER: WebView trong app hiện trang TRẮNG** trên emulator. Sau khi bấm
  "Thanh toán qua VNPay", màn hình hiện header + dải debug, nhưng vùng webview
  trắng. Dải debug chỉ hiện `watchdog: vẫn loading sau 25s` — tức là **không có
  callback `onPageStarted/onProgress/onPageFinished/onWebResourceError` nào nổ**
  → WebView chưa hề bắt đầu load request.

→ Kết luận: vấn đề nằm ở **WebView platform view trên emulator**, KHÔNG phải ở
URL/chữ ký/tham số. Xem [Bước tiếp theo](#bước-tiếp-theo).

## Thông tin sandbox (môi trường TEST, không phải production)
Đang hardcode trong `lib/core/constants/app_constants.dart` → class `VnpayConfig`:
- `vnp_TmnCode`: `9UFLNCBZ`
- `vnp_HashSecret`: `KY4RBY8YTM8PJO28M13WGJY46OR9U3W7`
- `vnp_Url`: `https://sandbox.vnpayment.vn/paymentv2/vpcpay.html`
- `returnUrl`: `https://return.lkshop.vn/vnpay` (URL giả; webview chỉ cần bắt
  `vnp_ResponseCode` trên đó, không cần host thật)

**Thẻ test (chọn ngân hàng NCB):** `9704198526191432198` · NGUYEN VAN A ·
phát hành `07/15` · OTP `123456`

**Merchant Admin** (xem giao dịch): https://sandbox.vnpayment.vn/merchantv2/ —
login `dovananhkhoa1707@gmail.com` / `Anhkhoa123` (KHÔNG để password vào code).

> ⚠️ Hash secret nằm ở client chỉ chấp nhận cho demo sandbox. Lên production
> phải ký ở server + nhận IPN (server-to-server). Xem comment `ponytail:` trong
> `app_constants.dart` và `vnpay.dart`.

## Đã làm gì (các file)
| File | Thay đổi |
|------|----------|
| `pubspec.yaml` | Thêm `webview_flutter`, `crypto`. **KHÔNG dùng** package `vnpay_flutter` vì nó kéo theo `flutter_webview_plugin_ios_android` cũ → vỡ build AGP 8 (thiếu `namespace`). |
| `lib/core/services/vnpay.dart` | `buildVnpayUrl(...)` — tự ký HMAC-SHA512 (đúng spec VNPay 2.1.0, URL-encode đồng nhất). Có param `bankCode` để vào thẳng QR. |
| `lib/core/constants/app_constants.dart` | `VnpayConfig` (creds sandbox) + payment method `payVnpayQr`. |
| `lib/features/order/screens/vnpay_gateway_screen.dart` | Màn cổng thanh toán: mở VNPay trong `WebViewWidget`, bắt return qua `onNavigationRequest`/`onUrlChange`, có **dải debug log hiện ngay trên màn**, error view, watchdog 25s. |
| `lib/features/order/screens/checkout_screen.dart` | Thêm lựa chọn **"VNPay QR"** (option thứ 3) + sửa routing/label nút. |
| `lib/data/models/order_model.dart` | `copyWith` nhận thêm `paid`. |
| `lib/data/repositories/order_repository.dart` | Thêm `markPaid(id)` (Firestore + Mock). |
| `lib/features/order/providers/order_providers.dart` | `markCurrentPaid()` → set `paid=true, status=confirmed`. |
| `android/app/src/main/AndroidManifest.xml` | Thêm quyền `INTERNET`; tắt Impeller (`EnableImpeller=false`) để thử fix webview trắng (chưa ăn thua). |
| `test/vnpay_test.dart` | Self-check cho hàm ký (deterministic, *100, đổi amount đổi hash). |
| `tool/print_vnpay_url.dart` | In URL đã ký để test bằng trình duyệt thật. |

## Luồng hoạt động
1. Checkout (`checkout_screen.dart`) → chọn **VNPay** hoặc **VNPay QR** → tạo
   order (`status=pending, paid=false`) rồi `context.go('/vnpay')`.
2. `VnpayGatewayScreen` đọc order từ `orderCreationProvider`, gọi `buildVnpayUrl`
   (truyền `bankCode='VNPAYQR'` nếu là QR), load vào WebView.
3. VNPay redirect về `returnUrl?...&vnp_ResponseCode=XX` → webview bắt được →
   `00` ⇒ `markCurrentPaid()` + `go('/success')`; khác ⇒ snackbar + về `/checkout`.

## Đã verify được gì (bằng chứng logic đúng)
- `dart run tool/print_vnpay_url.dart` → copy URL → mở **Chrome PC** → ra đúng
  trang chọn ngân hàng VNPay. ✅
- HMAC-SHA512 của query khớp giữa Dart `crypto` và PowerShell .NET. ✅
- `flutter analyze` sạch; `flutter test test/vnpay_test.dart` pass. ✅
- `flutter build apk --debug` build thành công (với `webview_flutter`). ✅
- WebFetch URL trả về trang lỗi generic — **bỏ qua**, do WebFetch không phải
  trình duyệt thật (Chrome PC mở OK mới là chuẩn).

## BLOCKER chi tiết
Trên emulator: webview vùng nội dung trắng, KHÔNG callback nào nổ ngoài watchdog.
Đã thử (không khỏi): tắt Impeller qua manifest; `setBackgroundColor(white)`;
`Positioned.fill` cho `WebViewWidget`; watchdog ẩn spinner.

## Bước tiếp theo
Theo thứ tự khả năng cao → thấp:

1. **Chạy trên ĐIỆN THOẠI Android thật** (không phải emulator). `webview_flutter`
   hay trắng/không init trên emulator thiếu Android System WebView. Đây là nghi
   can số 1 — thử trước.
2. **Emulator phải có Google Play / Android System WebView** và cập nhật mới
   nhất (Play Store → "Android System WebView" + "Chrome" → Update). Tạo AVD từ
   image **có Play Store**.
3. `flutter clean && flutter run` để chắc chắn đổi manifest (tắt Impeller) đã
   thực sự áp dụng (đổi manifest cần build lại full, không hot-reload được).
4. Đọc dải debug đen dưới màn: nếu thấy `pageFinished` mà vẫn trắng ⇒ lỗi render
   platform view (đổi device); nếu thấy `ERR ...` ⇒ lấy mã lỗi.

### Phương án dự phòng (nếu webview cứ fail) — ROBUST nhất cho demo
Mở URL đã ký bằng **trình duyệt ngoài** qua `url_launcher`
(`launchUrl(Uri.parse(buildVnpayUrl(...)), mode: externalApplication)`). URL đã
chứng minh mở tốt trong trình duyệt thật → giáo viên thấy trang VNPay thật ngay.
- Để bắt kết quả trở lại app: cấu hình **deep link** (package `app_links`) cho
  một scheme của app rồi đặt `returnUrl` = scheme đó + thêm intent-filter trong
  AndroidManifest.
- Hoặc cho demo "chứng minh kết nối" thuần: chỉ cần mở được trang VNPay thật là
  đã đủ chứng minh; phần update order có thể làm thủ công/đơn giản hoá.

## Cách test nhanh
1. `flutter run` (ưu tiên máy thật).
2. Thêm sản phẩm vào giỏ → Checkout → chọn **VNPay** (hoặc **VNPay QR**) →
   "Thanh toán qua VNPay".
3. Mong đợi: trang VNPay hiện trong app → chọn NCB → nhập thẻ test ở trên →
   thành công → về `/success`, order `paid=true, status=confirmed` (xem `/orders`).
4. Debug không cần console: đọc dải đen dưới màn hình (các dòng `[VNPAY] ...`).
5. Test URL độc lập: `dart run tool/print_vnpay_url.dart` → dán vào Chrome PC.

## Dọn dẹp khi xong (optional)
- Bỏ dải debug + watchdog + log trong `vnpay_gateway_screen.dart`.
- Cân nhắc bật lại Impeller (xoá meta-data trong manifest) nếu không cần tắt.
- `tool/print_vnpay_url.dart` chỉ là tool debug, có thể xoá.
