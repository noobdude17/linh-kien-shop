import 'package:flutter/material.dart';

import 'models/address_model.dart';
import 'models/cart_item_model.dart';
import 'models/category_model.dart';
import 'models/notification_model.dart';
import 'models/order_model.dart';
import 'models/product_model.dart';
import 'models/product_variant.dart';
import 'models/review_model.dart';

/// Dữ liệu mẫu tĩnh trích từ design handoff. Dùng để dựng skeleton chạy được
/// trước khi nối Firestore. Khi có backend, thay bằng repository thật.
class MockData {
  MockData._();

  // ---- Categories (12) ----
  static const categories = <CategoryModel>[
    CategoryModel(id: 'cpu', name: 'CPU / Vi xử lý', icon: '🧠', colorIndex: 0, imageAsset: 'assets/images/categories/cpu.png'),
    CategoryModel(id: 'ram', name: 'RAM', icon: '🧩', colorIndex: 1, imageAsset: 'assets/images/categories/ram.png'),
    CategoryModel(id: 'gpu', name: 'Card đồ họa', icon: '🖼️', colorIndex: 2, imageAsset: 'assets/images/categories/gpu.png'),
    CategoryModel(
      id: 'storage',
      name: 'SSD / Lưu trữ',
      icon: '💿',
      colorIndex: 3,
      imageAsset: 'assets/images/categories/ssd.png',
    ),
    CategoryModel(
      id: 'mainboard',
      name: 'Mainboard',
      icon: '🔲',
      colorIndex: 4,
      imageAsset: 'assets/images/categories/mainboard.png',
    ),
    CategoryModel(id: 'psu', name: 'Nguồn (PSU)', icon: '⚡', colorIndex: 5, imageAsset: 'assets/images/categories/psu.png'),
    CategoryModel(id: 'cooler', name: 'Tản nhiệt', icon: '❄️', colorIndex: 6, imageAsset: 'assets/images/categories/cooler.png'),
    CategoryModel(id: 'laptop', name: 'Laptop', icon: '💻', colorIndex: 7, imageAsset: 'assets/images/categories/laptop.png'),
    CategoryModel(id: 'monitor', name: 'Màn hình', icon: '🖥️', colorIndex: 8, imageAsset: 'assets/images/categories/monitor.png'),
    CategoryModel(id: 'keyboard', name: 'Bàn phím', icon: '⌨️', colorIndex: 9, imageAsset: 'assets/images/categories/keyboard.png'),
    CategoryModel(id: 'mouse', name: 'Chuột', icon: '🖱️', colorIndex: 10, imageAsset: 'assets/images/categories/mouse.png'),
    CategoryModel(
      id: 'case',
      name: 'Case / Vỏ máy tính',
      icon: '🖥️',
      colorIndex: 11,
      imageAsset: 'assets/images/categories/case.png',
    ),
    CategoryModel(
      id: 'accessory',
      name: 'Phụ kiện',
      icon: '🎧',
      colorIndex: 0,
      imageAsset: 'assets/images/categories/accessory.png',
    ),
  ];

  // ---- Brands (logo slider) — chỉ những hãng có sẵn logo asset ----
  static const brands = <(String name, String logo)>[
    ('AMD', 'assets/images/brands/amd.png'),
    ('ASUS', 'assets/images/brands/asus.png'),
    ('Intel', 'assets/images/brands/intel.png'),
    ('MSI', 'assets/images/brands/msi.png'),
    ('Samsung', 'assets/images/brands/samsung.png'),
    ('Logitech', 'assets/images/brands/logitech.png'),
    ('Microsoft', 'assets/images/brands/microsoft.png'),
    ('Razer', 'assets/images/brands/razer.png'),
    ('Crucial', 'assets/images/brands/crucial.png'),
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
      price: 8500000,
      oldPrice: 10500000,
      rating: 4.9,
      reviewCount: 89,
      imageLabel: 'CORE i7-14700K',
      categoryId: 'cpu',
      categoryName: 'CPU',
      stock: 0,
      specs: {'Socket': 'LGA1700', 'Nhân': '20', 'Xung': '5.6GHz'},
      variants: [
        ProductVariant(
          id: 'p2v1',
          name: 'BOX (Retail)',
          price: 9200000,
          oldPrice: 10500000,
          stock: 8,
        ),
        ProductVariant(
          id: 'p2v2',
          name: 'TRAY (OEM)',
          price: 8500000,
          stock: 12,
        ),
      ],
    ),
    ProductModel(
      id: 'p3',
      name: 'Kingston Fury DDR5',
      brand: 'Kingston',
      price: 1600000,
      oldPrice: 1900000,
      rating: 4.7,
      reviewCount: 56,
      imageLabel: 'FURY DDR5',
      categoryId: 'ram',
      categoryName: 'RAM',
      stock: 0,
      specs: {'Bus': '6000MHz', 'Loại': 'DDR5', 'Chuẩn': 'CL36'},
      variants: [
        ProductVariant(
          id: 'p3v1',
          name: '16GB',
          price: 1600000,
          oldPrice: 1900000,
          stock: 15,
          attributes: {
            'ramCapacityGb': 16,
            'ramModuleCount': 1,
            'ramSlotsUsed': 1,
            'ramSpeedMhz': 6000,
          },
        ),
        ProductVariant(
          id: 'p3v2',
          name: '32GB (2x16)',
          price: 2800000,
          oldPrice: 3200000,
          stock: 3,
          attributes: {
            'ramCapacityGb': 32,
            'ramModuleCount': 2,
            'ramSlotsUsed': 2,
            'ramSpeedMhz': 6000,
          },
        ),
        ProductVariant(
          id: 'p3v3',
          name: '64GB (2x32)',
          price: 5400000,
          stock: 0,
          attributes: {
            'ramCapacityGb': 64,
            'ramModuleCount': 2,
            'ramSlotsUsed': 2,
            'ramSpeedMhz': 6000,
          },
        ),
      ],
    ),
    ProductModel(
      id: 'p4',
      name: 'Samsung 990 Pro NVMe SSD',
      brand: 'Samsung',
      price: 2100000,
      oldPrice: 2500000,
      rating: 4.9,
      reviewCount: 213,
      imageLabel: 'SAMSUNG 990 PRO',
      categoryId: 'storage',
      categoryName: 'SSD',
      stock: 23,
      specs: {'Dung lượng': '1TB', 'Chuẩn': 'NVMe PCIe 4.0', 'Đọc': '7450MB/s'},
      variants: [
        ProductVariant(
          id: 'p4v1',
          name: '1TB',
          price: 2100000,
          oldPrice: 2500000,
          stock: 23,
          attributes: {
            'storageCapacityGb': 1000,
            'storageReadSpeedMbps': 7450,
            'storageWriteSpeedMbps': 6900,
          },
        ),
        ProductVariant(
          id: 'p4v2',
          name: '2TB',
          price: 3900000,
          oldPrice: 4500000,
          stock: 12,
          attributes: {
            'storageCapacityGb': 2000,
            'storageReadSpeedMbps': 7450,
            'storageWriteSpeedMbps': 6900,
          },
        ),
      ],
    ),
    ProductModel(
      id: 'p5',
      name: 'Logitech G Pro X Superlight 2',
      brand: 'Logitech',
      price: 3200000,
      oldPrice: 3700000,
      rating: 4.9,
      reviewCount: 178,
      imageLabel: 'G PRO X SUPERLIGHT',
      categoryId: 'mouse',
      categoryName: 'Chuột',
      stock: 31,
      specs: {'DPI': '32000', 'Trọng lượng': '60g', 'Kết nối': 'Wireless'},
    ),
    ProductModel(
      id: 'p6',
      name: 'Razer BlackWidow V4 Pro RGB',
      brand: 'Razer',
      price: 4500000,
      oldPrice: 5200000,
      rating: 4.7,
      reviewCount: 92,
      imageLabel: 'BLACKWIDOW V4 PRO',
      categoryId: 'keyboard',
      categoryName: 'Bàn phím',
      stock: 18,
      specs: {'Switch': 'Green', 'Kết nối': 'USB-C', 'Đèn': 'Chroma RGB'},
    ),
    ProductModel(
      id: 'p7',
      name: 'Samsung Odyssey G7 27" 240Hz QHD',
      brand: 'Samsung',
      price: 8900000,
      oldPrice: 10500000,
      rating: 4.8,
      reviewCount: 144,
      imageLabel: 'ODYSSEY G7 27"',
      categoryId: 'monitor',
      categoryName: 'Màn hình',
      stock: 9,
      specs: {'Tấm nền': 'VA', 'Tần số': '240Hz', 'Độ phân giải': 'QHD'},
    ),
    ProductModel(
      id: 'p8',
      name: 'ASUS ROG Strix G16 Gaming Laptop',
      brand: 'ASUS',
      price: 32500000,
      oldPrice: 36000000,
      rating: 4.6,
      reviewCount: 67,
      imageLabel: 'ROG STRIX G16',
      categoryId: 'laptop',
      categoryName: 'Laptop',
      stock: 5,
      specs: {'CPU': 'i7-13650HX', 'GPU': 'RTX 4060', 'RAM': '16GB DDR5'},
    ),
  ];

  // ---- GPU list (Product list screen) ----
  static const gpuList = <ProductModel>[
    ProductModel(
      id: 'g1',
      name: 'ASUS TUF RTX 4070 Super 12GB',
      brand: 'ASUS',
      price: 14500000,
      oldPrice: 17000000,
      rating: 4.8,
      imageLabel: 'RTX 4070 SUPER',
      categoryId: 'gpu',
      categoryName: 'Card đồ họa',
      stock: 15,
    ),
    ProductModel(
      id: 'g2',
      name: 'MSI RTX 4060 Ti Gaming 8GB',
      brand: 'MSI',
      price: 9800000,
      oldPrice: 11000000,
      rating: 4.6,
      imageLabel: 'RTX 4060 Ti',
      categoryId: 'gpu',
      categoryName: 'Card đồ họa',
      stock: 10,
    ),
    ProductModel(
      id: 'g3',
      name: 'Gigabyte RTX 4070 Eagle 12GB',
      brand: 'Gigabyte',
      price: 13200000,
      oldPrice: 15000000,
      rating: 4.7,
      imageLabel: 'RTX 4070 EAGLE',
      categoryId: 'gpu',
      categoryName: 'Card đồ họa',
      stock: 6,
    ),
    ProductModel(
      id: 'g4',
      name: 'ASUS Dual RTX 4060 OC 8GB',
      brand: 'ASUS',
      price: 7500000,
      oldPrice: 8500000,
      rating: 4.5,
      imageLabel: 'RTX 4060 DUAL',
      categoryId: 'gpu',
      categoryName: 'Card đồ họa',
      stock: 12,
    ),
    ProductModel(
      id: 'g5',
      name: 'AMD Radeon RX 7800 XT 16GB',
      brand: 'AMD',
      price: 12900000,
      oldPrice: 14500000,
      rating: 4.6,
      imageLabel: 'RX 7800 XT',
      categoryId: 'gpu',
      categoryName: 'Card đồ họa',
      stock: 4,
    ),
    ProductModel(
      id: 'g6',
      name: 'MSI RTX 4080 Super Ventus 16GB',
      brand: 'MSI',
      price: 26500000,
      oldPrice: 29000000,
      rating: 4.9,
      imageLabel: 'RTX 4080 SUPER',
      categoryId: 'gpu',
      categoryName: 'Card đồ họa',
      stock: 3,
    ),
  ];

  // ---- Cart items ----
  static List<CartItemModel> cartItems() => [
    CartItemModel(
      productId: 'p1',
      name: 'ASUS TUF RTX 4070 Super 12GB',
      variant: 'GDDR6X · OC Edition',
      price: 14500000,
      imageLabel: 'RTX 4070 SUPER',
    ),
    CartItemModel(
      productId: 'p2',
      name: 'Intel Core i7-14700K',
      variant: 'Socket LGA1700 · 20 nhân',
      price: 9200000,
      imageLabel: 'CORE i7-14700K',
    ),
    CartItemModel(
      productId: 'm1',
      name: 'Mainboard ASUS ROG Strix Z790-E',
      variant: 'LGA1700 · DDR5 · WiFi 6E',
      price: 8600000,
      imageLabel: 'ROG Z790-E',
    ),
  ];

  // ---- Addresses ----
  static const addresses = <AddressModel>[
    AddressModel(
      id: 'a1',
      name: 'Nguyễn Văn An',
      phone: '0912 345 678',
      detail: '123 Đường Nguyễn Huệ, P. Bến Nghé, Q.1, TP.HCM',
      isDefault: true,
    ),
    AddressModel(
      id: 'a2',
      name: 'Nguyễn Văn An',
      phone: '0987 654 321',
      detail: '45 Đường Lê Lợi, P. Bến Thành, Q.1, TP.HCM',
    ),
  ];

  // ---- Orders (customer) ----
  static List<OrderModel> orders() => [
    OrderModel(
      id: 'o1',
      code: 'LKS-2024061601',
      userId: 'u1',
      customerName: 'Nguyễn Văn An',
      items: cartItems(),
      subtotal: 32300000,
      discount: 2500000,
      totalAmount: 29800000,
      status: 'shipping',
      address: '123 Đường Nguyễn Huệ, P. Bến Nghé, Q.1, TP.HCM',
      paid: true,
      createdAt: DateTime(2024, 6, 16),
    ),
    OrderModel(
      id: 'o2',
      code: 'LKS-2024060902',
      userId: 'u1',
      customerName: 'Nguyễn Văn An',
      items: [
        CartItemModel(
          productId: 'p4',
          name: 'Samsung 990 Pro SSD 1TB',
          price: 2100000,
          imageLabel: 'SAMSUNG 990 PRO',
        ),
      ],
      subtotal: 2100000,
      totalAmount: 2100000,
      status: 'delivered',
      paid: true,
      createdAt: DateTime(2024, 6, 9),
    ),
    OrderModel(
      id: 'o3',
      code: 'LKS-2024052803',
      userId: 'u1',
      customerName: 'Nguyễn Văn An',
      items: [
        CartItemModel(
          productId: 'p3',
          name: 'Kingston Fury 32GB DDR5',
          price: 2800000,
          imageLabel: 'FURY 32GB DDR5',
        ),
      ],
      subtotal: 2800000,
      totalAmount: 2800000,
      status: 'cancelled',
      createdAt: DateTime(2024, 5, 28),
    ),
  ];

  // ---- Admin orders ----
  static List<OrderModel> adminOrders() => [
    OrderModel(
      id: 'ao1',
      code: 'LKS-2024061601',
      userId: 'u1',
      customerName: 'Nguyễn Văn An',
      items: cartItems(),
      totalAmount: 29800000,
      status: 'pending',
      createdAt: DateTime(2024, 6, 16),
    ),
    OrderModel(
      id: 'ao2',
      code: 'LKS-2024061602',
      userId: 'u2',
      customerName: 'Trần Thị Bình',
      items: [
        CartItemModel(
          productId: 'p2',
          name: 'Intel Core i7-14700K',
          price: 9200000,
        ),
      ],
      totalAmount: 9200000,
      status: 'shipping',
      createdAt: DateTime(2024, 6, 16),
    ),
    OrderModel(
      id: 'ao3',
      code: 'LKS-2024061503',
      userId: 'u3',
      customerName: 'Lê Văn Cường',
      items: [],
      totalAmount: 5600000,
      status: 'delivered',
      createdAt: DateTime(2024, 6, 15),
    ),
    OrderModel(
      id: 'ao4',
      code: 'LKS-2024061504',
      userId: 'u4',
      customerName: 'Phạm Thị Dung',
      items: [],
      totalAmount: 2100000,
      status: 'cancelled',
      createdAt: DateTime(2024, 6, 15),
    ),
  ];

  // ---- Notifications ----
  static const notifications = <AppNotification>[
    AppNotification(
      id: 'n1',
      icon: '🚚',
      iconBg: Color(0xFFEFF6FF),
      title: 'Đơn hàng đang được giao',
      message: 'Đơn LKS-2024061601 đang trên đường giao đến bạn',
      timeLabel: '2 giờ trước',
      unread: true,
      group: 'Hôm nay',
    ),
    AppNotification(
      id: 'n2',
      icon: '🔥',
      iconBg: Color(0xFFF3F4F6),
      title: 'Flash Sale RTX giảm 20%',
      message: 'Nhanh tay săn card đồ họa RTX với giá sốc hôm nay',
      timeLabel: '5 giờ trước',
      unread: true,
      group: 'Hôm nay',
    ),
    AppNotification(
      id: 'n3',
      icon: '✓',
      iconBg: Color(0xFFE8F5E9),
      title: 'Đặt hàng thành công',
      message: 'Đơn LKS-2024061601 đã được tạo',
      timeLabel: 'Hôm qua',
      group: 'Trước đó',
    ),
    AppNotification(
      id: 'n4',
      icon: '🎁',
      iconBg: Color(0xFFEDE7F6),
      title: 'Ưu đãi thành viên mới',
      message: 'Bạn nhận được voucher 100.000đ cho đơn đầu tiên',
      timeLabel: '2 ngày trước',
      group: 'Trước đó',
    ),
  ];

  // ---- Onboarding ----
  static const onboarding = <Map<String, String>>[
    {
      'illust': '🧩',
      'title': 'Hàng ngàn linh kiện',
      'desc': 'CPU, RAM, GPU, Laptop chính hãng từ các thương hiệu hàng đầu',
    },
    {
      'illust': '🚚',
      'title': 'Giao hàng nhanh',
      'desc': 'Nhận hàng chỉ trong 2-3 ngày trên toàn quốc',
    },
    {
      'illust': '🔒',
      'title': 'Thanh toán an toàn',
      'desc': 'Hỗ trợ VNPay & COD, bảo mật thông tin tuyệt đối',
    },
  ];

  // ---- Admin dashboard ----
  static const adminStats = <Map<String, dynamic>>[
    {
      'label': 'Doanh thu hôm nay',
      'value': '45.500.000đ',
      'color': Color(0xFF7C3AED),
    },
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

  // ---- Reviews ----
  static final reviews = <ReviewModel>[
    ReviewModel(
      id: 'r1',
      productId: 'p1',
      userId: 'u1',
      userName: 'Nguyễn Văn An',
      rating: 5,
      comment: 'Card chạy cực mượt, nhiệt độ ổn định, hiệu năng vượt kỳ vọng.',
      createdAt: DateTime(2024, 5, 10),
    ),
    ReviewModel(
      id: 'r2',
      productId: 'p1',
      userId: 'u2',
      userName: 'Trần Thị Bình',
      rating: 4,
      comment: 'Hàng đúng mô tả, giao nhanh, đóng gói cẩn thận.',
      createdAt: DateTime(2024, 4, 20),
    ),
    ReviewModel(
      id: 'r3',
      productId: 'p2',
      userId: 'u3',
      userName: 'Lê Minh Cường',
      rating: 5,
      comment: 'CPU i7-14700K mạnh, ép xung lên 5.8GHz ổn định, nhiệt tốt.',
      createdAt: DateTime(2024, 3, 15),
    ),
    ReviewModel(
      id: 'r4',
      productId: 'p2',
      userId: 'u4',
      userName: 'Phạm Thu Hà',
      rating: 4,
      comment: 'Sản phẩm chính hãng, giá tốt so với thị trường.',
      createdAt: DateTime(2024, 2, 8),
    ),
    ReviewModel(
      id: 'r5',
      productId: 'p4',
      userId: 'u5',
      userName: 'Hoàng Đức Nam',
      rating: 5,
      comment: 'SSD 990 Pro tốc độ đọc ghi cực nhanh, boot Windows chỉ 8 giây.',
      createdAt: DateTime(2024, 6, 1),
    ),
  ];
}
