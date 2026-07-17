# ⚡ Linh Kiện Shop

App thương mại điện tử bán **linh kiện & thiết bị máy tính, laptop** (CPU, RAM, GPU, SSD, Mainboard, Laptop, Màn hình, phụ kiện…).
Đồ án cuối kỳ môn Lập trình Mobile — **Flutter + Firebase**, nhóm 5 người.

> Đầy đủ luồng: Auth (email-link xác minh) → Duyệt/Tìm/So sánh → Chi tiết (biến thể + đánh giá) → PC Part Picker → Giỏ hàng → Checkout (VNPay sandbox / COD) → Tài khoản/Đơn hàng → Admin console.

---

## 📑 Mục lục
1. [Tech Stack](#-tech-stack)
2. [Bắt đầu nhanh](#-bắt-đầu-nhanh)
3. [Cấu trúc thư mục](#-cấu-trúc-thư-mục)
4. [Kiến trúc & quy ước code](#-kiến-trúc--quy-ước-code)
5. [Design System](#-design-system)
6. [Phân công nhóm](#-phân-công-nhóm)
7. [Quy trình Git](#-quy-trình-git)
8. [Cấu hình Firebase (Lead)](#-cấu-hình-firebase-lead)
9. [🤖 Dành cho AI Agent — đọc kỹ phần này](#-dành-cho-ai-agent)

---

## 🛠 Tech Stack

| Thành phần | Công nghệ |
|---|---|
| Framework | Flutter (Dart, Material 3) |
| State management | `flutter_riverpod` |
| Routing | `go_router` |
| Backend | Firebase (Auth email-link + Cloud Firestore) |
| Upload ảnh | Cloudinary (unsigned) — avatar + ảnh sản phẩm (không dùng Firebase Storage) |
| Bản đồ & geocoding | `flutter_map` (tiles OSM) + `latlong2` + `geocoding` — **không cần API key, không tính phí** (chỉ Android/iOS; web tự xuống chế độ nhập tay) |
| Thanh toán | VNPay **sandbox thật** (webview + tự ký HMAC-SHA512) hoặc COD |

Yêu cầu: Flutter SDK ≥ 3.11, Dart ≥ 3.11. Kiểm tra: `flutter --version`.

---

## 🚀 Bắt đầu nhanh

```bash
# 1. Clone
git clone https://github.com/noobdude17/linh-kien-shop.git
cd linh-kien-shop

# 2. Checkout branch của bạn (xem bảng phân công)
git checkout feature/<của-bạn>      # vd: feature/product

# 3. Cài dependencies
flutter pub get

# 4. Chạy (chọn thiết bị: emulator Android / Chrome)
flutter run
```

For Firebase-backed runs in this public repo, copy the private file you receive
from the lead to:

```bash
assets/config/firebase_config.json
```

Then run normally:

```bash
flutter run
```

`assets/config/firebase_config.json`, `android/app/google-services.json`, and
`ios/Runner/GoogleService-Info.plist` are intentionally ignored. Do not commit
real Firebase keys or native config files to this public repository.

> App **chạy được ngay** kể cả khi chưa cấu hình Firebase — phần khởi tạo Firebase được bọc `try/catch`, dữ liệu lấy từ `lib/data/mock_data.dart`. Khi Lead cấu hình Firebase xong, app tự dùng backend thật.

Kiểm tra code trước khi commit:
```bash
flutter analyze     # phải 0 issues
flutter test
```

---

## 📁 Cấu trúc thư mục

```
lib/
├── main.dart                     # Entry point, khởi tạo Firebase (guarded) + Riverpod
├── firebase_options.dart         # Đọc Firebase config từ assets/config/firebase_config.json
│
├── core/                         # Dùng chung toàn app (KHÔNG chứa logic nghiệp vụ)
│   ├── constants/app_constants.dart   # tên collection, status đơn, role, payment
│   ├── theme/
│   │   ├── app_colors.dart            # Bảng màu (design tokens)
│   │   ├── app_dimens.dart            # Spacing, radius, shadow
│   │   ├── app_text_styles.dart       # Typography
│   │   └── app_theme.dart             # ThemeData tổng
│   ├── utils/formatter.dart           # Format giá VNĐ, ngày
│   └── widgets/                       # Component tái dùng (xem mục Design System)
│       ├── app_buttons.dart           # PrimaryButton, AppOutlinedButton, AccentButton
│       ├── app_bottom_nav.dart        # Thanh nav 4 tab
│       ├── app_chip.dart              # Chip lọc/danh mục
│       ├── product_card.dart          # Card sản phẩm
│       ├── quantity_stepper.dart      # Bộ tăng/giảm số lượng
│       ├── summary_row.dart           # Hàng tổng kết tiền
│       ├── status_badge.dart          # Badge trạng thái đơn
│       ├── section_header.dart        # Tiêu đề section
│       └── image_placeholder.dart     # Placeholder ảnh
│
├── data/                         # Tầng dữ liệu
│   ├── mock_data.dart                 # Dữ liệu mẫu (dùng khi chưa có Firebase)
│   ├── models/                        # Model: product, category, order, cart_item, address, notification, user
│   └── repositories/                  # Repository (abstract + Mock + Firestore)
│       └── product_repository.dart    # ⭐ MẪU CHUẨN để copy cho repo khác
│
├── features/                     # Chia theo tính năng (feature-first)
│   ├── auth/screens/             # splash, onboarding, login, register, forgot_password
│   ├── home/
│   │   ├── screens/              # home, categories, search, search_results, empty_results
│   │   └── widgets/             # category_chip, promo_banner
│   ├── product/
│   │   ├── screens/             # product_list, product_detail, compare
│   │   ├── widgets/             # variant_selector, review_card, filter_sheet, image_gallery
│   │   └── providers/           # ⭐ product_providers (FutureProvider), wishlist, compare, review
│   ├── part_picker/            # PC Part Picker: chọn linh kiện + kiểm tra tương thích + tính watt
│   │   ├── screens/            # part_picker, part_selection
│   │   └── services/           # compatibility_engine, wattage_calculator
│   ├── cart/
│   │   ├── screens/             # cart_screen
│   │   └── providers/cart_provider.dart        # ⭐ MẪU state (Notifier)
│   ├── order/screens/           # checkout, vnpay_gateway, payment_processing,
│   │                            # order_success, order_history, order_detail
│   ├── location/                # Chọn/xác minh vị trí trên bản đồ (dùng chung auth + profile)
│   │   ├── location_picker_screen.dart   # map picker (flutter_map) + LocationResult
│   │   └── geocode.dart                   # seam forward/reverse geocode (điểm nâng cấp web)
│   ├── profile/screens/         # profile, edit_profile, address_list, add_address,
│   │                            # wishlist, wishlist_empty, notifications
│   └── admin/screens/           # admin_dashboard, admin_product_list/edit, admin_order_management/detail,
│                                # admin_user_list, admin_review_list
│
└── routes/
    ├── app_routes.dart           # Hằng số đường dẫn 31 route (KHÔNG gõ chuỗi path tay)
    └── app_router.dart           # Khai báo GoRouter
```

---

## 🏗 Kiến trúc & quy ước code

### Luồng dữ liệu (BẮT BUỘC tuân theo)
```
UI (Screen)  →  Provider (Riverpod)  →  Repository (abstract)  →  Data source (Mock / Firestore)
```

- **Screen** chỉ `ref.watch(provider)` để lấy dữ liệu, `ref.read(provider.notifier)` để gọi hành động. **Không** gọi Firestore trực tiếp trong screen.
- **Provider** điều phối, gọi repository.
- **Repository** là abstract class; có 2 hiện thực: `MockXxxRepository` (dữ liệu mẫu) và `FirestoreXxxRepository` (backend thật). Đổi nguồn chỉ bằng **1 dòng** trong provider.

### File mẫu PHẢI đọc trước khi code
1. [`lib/data/repositories/product_repository.dart`](lib/data/repositories/product_repository.dart) — mẫu repository (abstract + Mock + Firestore).
2. [`lib/features/product/providers/product_providers.dart`](lib/features/product/providers/product_providers.dart) — mẫu `FutureProvider` (dữ liệu async).
3. [`lib/features/cart/providers/cart_provider.dart`](lib/features/cart/providers/cart_provider.dart) — mẫu `Notifier` (state thay đổi được: thêm/xóa/sửa số lượng).
4. [`lib/features/home/screens/home_screen.dart`](lib/features/home/screens/home_screen.dart) — mẫu screen tiêu thụ provider với loading/error/data.

### Quy ước
- Màu/spacing/chữ: **luôn** dùng `AppColors`, `AppDimens`, `AppTextStyles` — không hard-code `Color(0x...)` rời rạc trong widget.
- Điều hướng: dùng hằng số trong `AppRoutes` (vd `context.go(AppRoutes.cart)`), không gõ `'/cart'` tay.
- Format tiền: `Formatter.price(14500000)` → `"14.500.000đ"`.
- Tên file: `snake_case`. Tên class: `PascalCase`. 1 screen = 1 file.
- Trước khi commit: `flutter analyze` phải **0 issues**.

---

## 🎨 Design System

Tokens trích từ bản thiết kế gốc (Claude Design). Tham chiếu file, không tự đặt giá trị mới:

| Token | Giá trị | File |
|---|---|---|
| Primary (xanh) | `#1565C0` | `AppColors.primary` |
| Accent (cam) | `#FF6F00` | `AppColors.accent` |
| Success / Error | `#2E7D32` / `#C62828` | `AppColors.success` / `.error` |
| Radius card / button | 12 / 8 | `AppDimens.radiusCard` / `.radiusButton` |
| Nút chính cao 50px | — | `PrimaryButton` |

**Admin** dùng app bar màu **cam** (`AppColors.accent`) để phân biệt với phần khách hàng.

Component có sẵn trong `core/widgets/` — tái dùng, đừng viết lại: `ProductCard`, `AppChip`, `QuantityStepper`, `SummaryRow`, `StatusBadge`, `PrimaryButton`/`AccentButton`/`AppOutlinedButton`, `AppBottomNav`, `SectionHeader`, `ImagePlaceholder`.

---

## 👥 Phân công nhóm

> Mỗi người làm trên branch riêng. Hiện tại các màn đã có **skeleton UI** (bố cục + điều hướng chạy được); việc của bạn là **thay dữ liệu mẫu/`TODO` bằng logic thật** (repository + provider + validate form + nối Firebase).

| # | Thành viên | Branch | Khu vực sở hữu (thư mục) |
|---|---|---|---|
| 1 | **Khoa (Lead)** | `feature/auth` | `features/auth/`, `firebase_options.dart`, `routes/`, `AuthRepository` |
| 2 | **Trần Quang Huy**  | `feature/product` | `features/product/`, `features/home/`, `data/repositories/product_repository.dart` |
| 3 | _(tên)_ | `feature/cart-order` | `features/cart/`, `features/order/`, `OrderRepository` |
| 4 | _(tên)_ | `feature/admin` | `features/admin/` |
| 5 | **Trần Minh Huy** | `feature/ui-profile` | `features/profile/`, `core/widgets/` (polish), `AddressRepository` |
| 6 | **Trần Minh Huy** | `PartPicker` |  |
| 7 | **Khoa (Lead)** | `feature/map-location-address` | `features/location/` — xác minh vị trí trên bản đồ (auth + CRUD địa chỉ) |

### 1 · Lead — Auth & nền tảng (`feature/auth`)
- **Màn:** Splash, Onboarding, Login, Register, Forgot password.
- **Việc:**
  - Cấu hình Firebase (xem mục dưới), gửi riêng `assets/config/firebase_config.json` thật cho team.
  - Viết `AuthRepository` (đăng ký/đăng nhập/đăng xuất bằng `firebase_auth`) + provider `authStateProvider`.
  - Nối Login/Register vào auth thật, validate form (email, mật khẩu ≥ 6 ký tự, mật khẩu khớp).
  - Redirect theo trạng thái đăng nhập trong `app_router.dart` (chưa login → `/login`).
  - Lưu user (name, email, role) vào collection `users`.
- **Xong khi:** đăng ký tài khoản mới → tự đăng nhập → vào Home; đăng xuất quay về Login.

### 2 · Product & Home (`feature/product`, `feature/home`)
- **Màn:** Home, Categories, Search, Product List, Search Results, Empty, Product Detail.
- **Việc:**
  - Hoàn thiện `FirestoreProductRepository` (đã có khung trong `product_repository.dart`).
  - Backend bật/tắt bằng cờ `AppConfig.useFirebase` (Lead quản lý) — bạn chỉ cần đảm bảo `FirestoreProductRepository` truy vấn đúng.
  - Lọc theo danh mục thật, tìm kiếm thật (lọc theo tên), hiển thị empty state khi không có kết quả.
  - Màn chi tiết: load theo `productId` qua `productDetailProvider`.
- **Xong khi:** Home/List/Detail hiển thị dữ liệu từ Firestore; tìm kiếm & lọc hoạt động.

### 3 · Cart & Order (`feature/cart-order`)
- **Màn:** Cart, Checkout, VNPay gateway (mock), Processing, Success, Order History, Order Detail.
- **Việc:**
  - Cart đã dùng `cart_provider.dart` — giữ nguyên pattern, thêm tính phí/giảm giá nếu cần.
  - Viết `OrderRepository` (tạo đơn vào collection `orders`, lấy đơn theo user, cập nhật trạng thái).
  - Checkout: chọn địa chỉ + phương thức (VNPay/COD) → tạo đơn → mock VNPay → Success.
  - Order History: tab lọc theo trạng thái; Order Detail: timeline trạng thái.
- **Xong khi:** đặt hàng tạo được đơn thật trong Firestore; xem lại được trong "Đơn hàng của tôi".

### 4 · Admin (`feature/admin`)
- **Màn:** Dashboard, Product List, Product Edit, Order Management, Order Detail.
- **Việc:**
  - CRUD sản phẩm (thêm/sửa/xóa vào collection `products`, upload ảnh qua Cloudinary).
  - Quản lý đơn: liệt kê, đổi trạng thái đơn (Chờ xác nhận → Xác nhận → Đang giao → Hoàn thành).
  - Dashboard: thống kê số liệu thật (đếm sản phẩm/đơn/doanh thu).
  - Chỉ user có `role == 'admin'` mới vào được (phối hợp với Lead về phân quyền).
- **Xong khi:** thêm/sửa/xóa sản phẩm phản ánh ngay ở app khách; đổi trạng thái đơn hoạt động.

### 5 · Profile & UI (`feature/ui-profile`)
- **Màn:** Profile, Edit Profile, Address List, Add Address, Wishlist, Wishlist Empty, Notifications.
- **Việc:**
  - Viết `AddressRepository` (CRUD địa chỉ trong subcollection của user).
  - Edit Profile: cập nhật thông tin user lên Firestore.
  - Wishlist: lưu/bỏ sản phẩm yêu thích; hiển thị empty state.
  - Rà soát & polish các `core/widgets/` dùng chung (báo nhóm trước khi sửa widget chung).
- **Xong khi:** sửa profile lưu được; thêm/xóa địa chỉ & wishlist hoạt động.

### 7 · Bản đồ & xác minh vị trí (`feature/map-location-address`)
- **Màn:** Location Picker (dùng chung) — mở từ Register, Hoàn tất hồ sơ, Thêm/Sửa địa chỉ. Mọi địa chỉ lưu kèm toạ độ `(lat, lng)` đã xác nhận, không chỉ chữ.
- **Việc:**
  - Picker `flutter_map` (tiles OSM) + `geocoding` với **hai cách chọn:**
    1. **Chạm/di chuyển bản đồ** → suy ra địa chỉ chữ (reverse geocode toạ độ → chữ).
    2. **Gõ/tìm địa chỉ** → ghim nhảy tới đó (forward geocode chữ → toạ độ). Không tra được = không hợp lệ → bắt nhập lại. *Forward geocode chính là bộ kiểm tra hợp lệ;* ghim giữa màn để xác nhận lần cuối.
  - Ô địa chỉ **chỉ đọc** ở chế độ bản đồ (chỉ nhận text đã geocode, chặn nhập bừa); nút zoom +/- không cần pinch. Ghim mặc định: Đà Nẵng `(16.0333, 108.2114)`.
  - `AddressRepository` ghi `(lat, lng)` vào subcollection `users/{uid}/addresses`; mirror địa chỉ mặc định sang `users/{uid}.defaultAddress` cho reader cũ (checkout/profile).
  - Mọi geocode đi qua **một khe duy nhất** `features/location/geocode.dart` (điểm nâng cấp web → Nominatim).
- **⚠️ Giới hạn:** plugin `geocoding` chỉ chạy **Android/iOS** (không có web). Trên web — hoặc khi tiles/geocode lỗi — màn tự **xuống chế độ nhập tay**: banner "Bản đồ hiện không khả dụng…" kèm lỗi cụ thể, vẫn nhập & lưu được (toạ độ `null`), không chết luồng.
- **Xong khi:** chọn trên bản đồ HOẶC gõ địa chỉ đều ra `(lat, lng, text)` đã xác nhận; CRUD địa chỉ lưu kèm toạ độ; đổi mặc định phản ánh đúng ở checkout; web không kẹt.

---

## 🔀 Quy trình Git

- Branch mặc định: **`develop`** (base để gộp). `master` chỉ nhận bản release.
- **Không** push thẳng vào `develop`/`master`. Mọi thay đổi qua **Pull Request**.

```bash
# Làm trên branch của mình
git add .
git commit -m "feat(product): nối ProductDetail vào Firestore"
git push

# Cập nhật code mới nhất từ develop vào branch mình (làm thường xuyên để tránh conflict)
git fetch origin
git merge origin/develop

# Khi xong 1 tính năng → mở PR vào develop
gh pr create --base develop --fill     # hoặc bấm nút trên github.com
```

**Quy ước commit:** `type(scope): mô tả` — type ∈ `feat | fix | refactor | style | docs | test`.
Ví dụ: `feat(cart): tính tổng tiền có giảm giá`, `fix(auth): validate email rỗng`.

---

## 🔥 Cấu hình Firebase (Lead)

```bash
# Cài CLI một lần
dart pub global activate flutterfire_cli

# Trong thư mục project — tạo project Firebase và lấy các giá trị cấu hình
flutterfire configure
```
Trên [Firebase Console](https://console.firebase.google.com): bật **Authentication** (Email/Password + email link xác minh) và **Cloud Firestore**. Ảnh upload qua Cloudinary nên **không cần Firebase Storage**.

> 🔒 **Repo này PUBLIC** → không commit file config Firebase thật. Gửi riêng
> `assets/config/firebase_config.json` qua kênh an toàn. File
> `lib/firebase_options.dart` đọc JSON này lúc app khởi động; nếu thiếu file,
> app rơi về mock mode qua `try/catch`.

**Bảo mật cơ bản:** vì repo public, phải đặt **Firestore Security Rules** yêu cầu đăng nhập (tránh bot quét endpoint Firebase công khai):
```
rules_version = '2';
service cloud.firestore {
  match /databases/{db}/documents {
    match /{document=**} { allow read, write: if request.auth != null; }
  }
}
```

**Firestore collections:** `users`, `products`, `categories`, `orders` (tên đã định nghĩa trong `AppConstants`).

### Bật backend thật (sau khi configure xong)
1. **Tự động** — không cần đổi cờ tay. Khi có `assets/config/firebase_config.json`, `main.dart`
   khởi tạo Firebase thành công và set `AppConfig.firebaseEnabled = true`; mọi repository tự
   chuyển Mock → Firestore. Thiếu file config → app rơi về mock qua `try/catch`.
2. Seed dữ liệu mẫu lên Firestore (12 danh mục + sản phẩm) để app có data ngay:
   ```bash
   flutter run -t tool/seed_firestore.dart
   ```
   Mở app → bấm **"Seed dữ liệu"** → chờ "Hoàn tất" → tắt.
3. `flutter run` — giờ app dùng Auth + Firestore thật nếu đã có `assets/config/firebase_config.json`.

---

## 🤖 Dành cho AI Agent

> Nếu bạn là AI agent hỗ trợ một thành viên, đọc kỹ và tuân theo:

1. **Đọc trước khi viết:** mở 4 file mẫu ở mục [Kiến trúc](#-kiến-trúc--quy-ước-code) để nắm pattern. Tái dùng component trong `core/widgets/`, đừng viết lại.
2. **Chỉ sửa trong phạm vi của thành viên** (xem cột "Khu vực sở hữu"). **Không** sửa file của feature khác hay `core/widgets/`, `core/theme/`, `routes/` mà chưa được thống nhất — đó là vùng dùng chung dễ gây conflict.
3. **Tuân theo luồng** `Screen → Provider → Repository → Data source`. Không gọi `FirebaseFirestore` trực tiếp trong screen.
4. **Dùng tokens & hằng số:** `AppColors`, `AppDimens`, `AppTextStyles`, `AppRoutes`, `Formatter` — không hard-code.
5. **Backend tự chuyển:** `AppConfig.firebaseEnabled` được `main.dart` set ở runtime (true khi init Firebase thành công). Không đổi cờ tay; mọi repository tự chọn Mock ↔ Firestore.
6. **Trước khi báo hoàn thành:** chạy `flutter analyze` (phải 0 issues) và `flutter test`. Mô tả ngắn gọn đã đổi gì.
7. **Tiếng Việt** cho mọi text hiển thị trên UI. Giá tiền định dạng VNĐ.
8. **Git:** commit theo quy ước `type(scope): mô tả`; không push thẳng `develop`/`master`, mở PR.

**Prompt gợi ý để đưa cho agent:**
> "Đọc README.md mục Kiến trúc và phần phân công của tôi (`feature/<...>`). Tôi phụ trách màn `<tên màn>`. Hãy nối nó vào dữ liệu thật theo pattern repository + Riverpod đã có sẵn, tái dùng component trong core/widgets, và chạy `flutter analyze` trước khi xong."

---

## 📦 Trạng thái hiện tại

| Hạng mục | Trạng thái |
|---|---|
| Cấu trúc project + design system | ✅ Xong |
| Auth (email-link xác minh, Google Sign-In) | ✅ Xong |
| Product / Home / Search / So sánh / Biến thể / Đánh giá | ✅ Xong |
| Cart + Order (Firestore thật) | ✅ Xong |
| Checkout VNPay sandbox + COD | ✅ Xong |
| PC Part Picker (compatibility + wattage) | ✅ Xong |
| Profile / Address (bản đồ) / Wishlist | ✅ Xong |
| Admin console (sản phẩm, đơn, user, đánh giá) | ✅ Xong |
| Cloudinary upload ảnh | ✅ Xong |
| Firebase backend thật (tự bật khi có config) | ✅ Xong |
| `flutter analyze` | ✅ 0 issues |

---

_Đồ án môn Lập trình Mobile — Linh Kiện Shop · Flutter + Firebase_
