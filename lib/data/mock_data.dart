import 'package:flutter/material.dart';

import 'models/address_model.dart';
import 'models/cart_item_model.dart';
import 'models/category_model.dart';
import 'models/notification_model.dart';
import 'models/order_model.dart';
import 'models/product_model.dart';

/// Dữ liệu mẫu tĩnh trích từ design handoff. Dùng để dựng skeleton chạy được
/// trước khi nối Firestore. Khi có backend, thay bằng repository thật.
class MockData {
  MockData._();

  // ---- Categories (12) ----
  static const categories = <CategoryModel>[
    CategoryModel(id: 'cpu', name: 'CPU / Vi xử lý', icon: '🧠', colorIndex: 0),
    CategoryModel(id: 'ram', name: 'RAM', icon: '🧩', colorIndex: 1),
    CategoryModel(id: 'gpu', name: 'Card đồ họa', icon: '🎮', colorIndex: 2),
    CategoryModel(id: 'ssd', name: 'Ổ cứng SSD/HDD', icon: '💾', colorIndex: 3),
    CategoryModel(id: 'mainboard', name: 'Mainboard', icon: '🔌', colorIndex: 4),
    CategoryModel(id: 'psu', name: 'Nguồn (PSU)', icon: '⚡', colorIndex: 5),
    CategoryModel(id: 'cooler', name: 'Tản nhiệt', icon: '❄️', colorIndex: 6),
    CategoryModel(id: 'laptop', name: 'Laptop', icon: '💻', colorIndex: 7),
    CategoryModel(id: 'monitor', name: 'Màn hình', icon: '🖥️', colorIndex: 8),
    CategoryModel(id: 'keyboard', name: 'Bàn phím', icon: '⌨️', colorIndex: 9),
    CategoryModel(id: 'mouse', name: 'Chuột', icon: '🖱️', colorIndex: 10),
    CategoryModel(id: 'accessory', name: 'Phụ kiện', icon: '🎧', colorIndex: 11),
  ];

  // ---- Featured products (Home) ----
  static const featured = <ProductModel>[
    ProductModel(
      id: 'p1',
      name: 'ASUS TUF Gaming RTX 4070 Super 12GB GDDR6X OC Edition',
      brand: 'ASUS',
      price: 14500000,
      oldPrice: 17000000,
      rating: 4.8,
      reviewCount: 124,
      imageLabel: 'RTX 4070 SUPER',
      categoryId: 'gpu',
      categoryName: 'Card đồ họa',
      stock: 15,
      specs: {
        'GPU': 'RTX 4070 Super',
        'VRAM': '12GB GDDR6X',
        'Bus': '192-bit',
        'TDP': '220W',
      },
    ),
    ProductModel(
      id: 'p2',
      name: 'Intel Core i7-14700K',
      brand: 'Intel',
      price: 9200000,
      oldPrice: 10500000,
      rating: 4.9,
      reviewCount: 89,
      imageLabel: 'CORE i7-14700K',
      categoryId: 'cpu',
      categoryName: 'CPU',
      stock: 8,
      specs: {'Socket': 'LGA1700', 'Nhân': '20', 'Xung': '5.6GHz'},
    ),
    ProductModel(
      id: 'p3',
      name: 'Kingston Fury 32GB DDR5 6000MHz',
      brand: 'Kingston',
      price: 2800000,
      oldPrice: 3200000,
      rating: 4.7,
      reviewCount: 56,
      imageLabel: 'FURY 32GB DDR5',
      categoryId: 'ram',
      categoryName: 'RAM',
      stock: 0,
      specs: {'Dung lượng': '32GB (2x16)', 'Bus': '6000MHz', 'Loại': 'DDR5'},
    ),
    ProductModel(
      id: 'p4',
      name: 'Samsung 990 Pro SSD 1TB NVMe',
      brand: 'Samsung',
      price: 2100000,
      oldPrice: 2500000,
      rating: 4.9,
      reviewCount: 213,
      imageLabel: 'SAMSUNG 990 PRO',
      categoryId: 'ssd',
      categoryName: 'SSD',
      stock: 23,
      specs: {'Dung lượng': '1TB', 'Chuẩn': 'NVMe PCIe 4.0', 'Đọc': '7450MB/s'},
    ),
  ];

  // ---- GPU list (Product list screen) ----
  static const gpuList = <ProductModel>[
    ProductModel(id: 'g1', name: 'ASUS TUF RTX 4070 Super 12GB', brand: 'ASUS', price: 14500000, oldPrice: 17000000, rating: 4.8, imageLabel: 'RTX 4070 SUPER', categoryId: 'gpu', categoryName: 'Card đồ họa', stock: 15),
    ProductModel(id: 'g2', name: 'MSI RTX 4060 Ti Gaming 8GB', brand: 'MSI', price: 9800000, oldPrice: 11000000, rating: 4.6, imageLabel: 'RTX 4060 Ti', categoryId: 'gpu', categoryName: 'Card đồ họa', stock: 10),
    ProductModel(id: 'g3', name: 'Gigabyte RTX 4070 Eagle 12GB', brand: 'Gigabyte', price: 13200000, oldPrice: 15000000, rating: 4.7, imageLabel: 'RTX 4070 EAGLE', categoryId: 'gpu', categoryName: 'Card đồ họa', stock: 6),
    ProductModel(id: 'g4', name: 'ASUS Dual RTX 4060 OC 8GB', brand: 'ASUS', price: 7500000, oldPrice: 8500000, rating: 4.5, imageLabel: 'RTX 4060 DUAL', categoryId: 'gpu', categoryName: 'Card đồ họa', stock: 12),
    ProductModel(id: 'g5', name: 'AMD Radeon RX 7800 XT 16GB', brand: 'AMD', price: 12900000, oldPrice: 14500000, rating: 4.6, imageLabel: 'RX 7800 XT', categoryId: 'gpu', categoryName: 'Card đồ họa', stock: 4),
    ProductModel(id: 'g6', name: 'MSI RTX 4080 Super Ventus 16GB', brand: 'MSI', price: 26500000, oldPrice: 29000000, rating: 4.9, imageLabel: 'RTX 4080 SUPER', categoryId: 'gpu', categoryName: 'Card đồ họa', stock: 3),
  ];

  // ---- Cart items ----
  static List<CartItemModel> cartItems() => [
        CartItemModel(productId: 'p1', name: 'ASUS TUF RTX 4070 Super 12GB', variant: 'GDDR6X · OC Edition', price: 14500000, imageLabel: 'RTX 4070 SUPER'),
        CartItemModel(productId: 'p2', name: 'Intel Core i7-14700K', variant: 'Socket LGA1700 · 20 nhân', price: 9200000, imageLabel: 'CORE i7-14700K'),
        CartItemModel(productId: 'm1', name: 'Mainboard ASUS ROG Strix Z790-E', variant: 'LGA1700 · DDR5 · WiFi 6E', price: 8600000, imageLabel: 'ROG Z790-E'),
      ];

  // ---- Addresses ----
  static const addresses = <AddressModel>[
    AddressModel(id: 'a1', name: 'Nguyễn Văn An', phone: '0912 345 678', detail: '123 Đường Nguyễn Huệ, P. Bến Nghé, Q.1, TP.HCM', isDefault: true),
    AddressModel(id: 'a2', name: 'Nguyễn Văn An', phone: '0987 654 321', detail: '45 Đường Lê Lợi, P. Bến Thành, Q.1, TP.HCM'),
  ];

  // ---- Orders (customer) ----
  static List<OrderModel> orders() => [
        OrderModel(id: 'o1', code: 'LKS-2024061601', userId: 'u1', customerName: 'Nguyễn Văn An', items: cartItems(), subtotal: 32300000, discount: 2500000, totalAmount: 29800000, status: 'shipping', address: '123 Đường Nguyễn Huệ, P. Bến Nghé, Q.1, TP.HCM', paid: true, createdAt: DateTime(2024, 6, 16)),
        OrderModel(id: 'o2', code: 'LKS-2024060902', userId: 'u1', customerName: 'Nguyễn Văn An', items: [CartItemModel(productId: 'p4', name: 'Samsung 990 Pro SSD 1TB', price: 2100000, imageLabel: 'SAMSUNG 990 PRO')], subtotal: 2100000, totalAmount: 2100000, status: 'delivered', paid: true, createdAt: DateTime(2024, 6, 9)),
        OrderModel(id: 'o3', code: 'LKS-2024052803', userId: 'u1', customerName: 'Nguyễn Văn An', items: [CartItemModel(productId: 'p3', name: 'Kingston Fury 32GB DDR5', price: 2800000, imageLabel: 'FURY 32GB DDR5')], subtotal: 2800000, totalAmount: 2800000, status: 'cancelled', createdAt: DateTime(2024, 5, 28)),
      ];

  // ---- Admin orders ----
  static List<OrderModel> adminOrders() => [
        OrderModel(id: 'ao1', code: 'LKS-2024061601', userId: 'u1', customerName: 'Nguyễn Văn An', items: cartItems(), totalAmount: 29800000, status: 'pending', createdAt: DateTime(2024, 6, 16)),
        OrderModel(id: 'ao2', code: 'LKS-2024061602', userId: 'u2', customerName: 'Trần Thị Bình', items: [CartItemModel(productId: 'p2', name: 'Intel Core i7-14700K', price: 9200000)], totalAmount: 9200000, status: 'shipping', createdAt: DateTime(2024, 6, 16)),
        OrderModel(id: 'ao3', code: 'LKS-2024061503', userId: 'u3', customerName: 'Lê Văn Cường', items: [], totalAmount: 5600000, status: 'delivered', createdAt: DateTime(2024, 6, 15)),
        OrderModel(id: 'ao4', code: 'LKS-2024061504', userId: 'u4', customerName: 'Phạm Thị Dung', items: [], totalAmount: 2100000, status: 'cancelled', createdAt: DateTime(2024, 6, 15)),
      ];

  // ---- Notifications ----
  static const notifications = <AppNotification>[
    AppNotification(id: 'n1', icon: '🚚', iconBg: Color(0xFFEFF6FF), title: 'Đơn hàng đang được giao', message: 'Đơn LKS-2024061601 đang trên đường giao đến bạn', timeLabel: '2 giờ trước', unread: true, group: 'Hôm nay'),
    AppNotification(id: 'n2', icon: '🔥', iconBg: Color(0xFFF3F4F6), title: 'Flash Sale RTX giảm 20%', message: 'Nhanh tay săn card đồ họa RTX với giá sốc hôm nay', timeLabel: '5 giờ trước', unread: true, group: 'Hôm nay'),
    AppNotification(id: 'n3', icon: '✓', iconBg: Color(0xFFE8F5E9), title: 'Đặt hàng thành công', message: 'Đơn LKS-2024061601 đã được tạo', timeLabel: 'Hôm qua', group: 'Trước đó'),
    AppNotification(id: 'n4', icon: '🎁', iconBg: Color(0xFFEDE7F6), title: 'Ưu đãi thành viên mới', message: 'Bạn nhận được voucher 100.000đ cho đơn đầu tiên', timeLabel: '2 ngày trước', group: 'Trước đó'),
  ];

  // ---- Onboarding ----
  static const onboarding = <Map<String, String>>[
    {'illust': '🧩', 'title': 'Hàng ngàn linh kiện', 'desc': 'CPU, RAM, GPU, Laptop chính hãng từ các thương hiệu hàng đầu'},
    {'illust': '🚚', 'title': 'Giao hàng nhanh', 'desc': 'Nhận hàng chỉ trong 2-3 ngày trên toàn quốc'},
    {'illust': '🔒', 'title': 'Thanh toán an toàn', 'desc': 'Hỗ trợ VNPay & COD, bảo mật thông tin tuyệt đối'},
  ];

  // ---- Admin dashboard ----
  static const adminStats = <Map<String, dynamic>>[
    {'label': 'Doanh thu hôm nay', 'value': '45.500.000đ', 'color': Color(0xFF7C3AED)},
    {'label': 'Đơn hàng mới', 'value': '12', 'color': Color(0xFF7C3AED)},
    {'label': 'Sản phẩm', 'value': '248', 'color': Color(0xFF7C3AED)},
    {'label': 'Khách hàng', 'value': '1.024', 'color': Color(0xFF7C3AED)},
  ];

  /// Chiều cao 7 cột biểu đồ doanh thu (T2–CN), %.
  static const revenue7d = <double>[55, 70, 45, 85, 65, 95, 78];
  static const revenueDays = <String>['T2', 'T3', 'T4', 'T5', 'T6', 'T7', 'CN'];

  // ---- Search ----
  static const recentSearches = ['RTX 4070', 'SSD Samsung', 'Laptop Gaming'];
  static const trendingSearches = ['RTX 4080 Super', 'i9-14900K', 'DDR5 32GB'];
}
