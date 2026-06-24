// Đặt tồn kho = 100 cho TẤT CẢ sản phẩm (và mọi variant nếu có).
//
// Lý do: dữ liệu nhập từ template để trống/bằng 0 cột stock nên app hiển thị
// "Hết hàng" hàng loạt. Script này vá nhanh để demo.
//
// Chạy sau khi đã cấu hình Firebase:
//   flutter run -t tool/patch_stock.dart
// Bấm nút, chờ "Hoàn tất", rồi tắt. An toàn khi chạy nhiều lần (idempotent).

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

import 'package:linh_kien_shop/core/config/firebase_options.dart';
import 'package:linh_kien_shop/core/constants/app_constants.dart';

const _kStock = 100;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: await DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const StockPatchApp());
}

class StockPatchApp extends StatelessWidget {
  const StockPatchApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      home: StockPatchPage(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class StockPatchPage extends StatefulWidget {
  const StockPatchPage({super.key});

  @override
  State<StockPatchPage> createState() => _StockPatchPageState();
}

class _StockPatchPageState extends State<StockPatchPage> {
  final _log = <String>[];
  bool _running = false;

  Future<void> _patch() async {
    setState(() {
      _running = true;
      _log.clear();
    });

    try {
      final db = FirebaseFirestore.instance;
      final snap = await db.collection(AppConstants.colProducts).get();

      // Batch giới hạn 500 ghi → chia khúc.
      for (var i = 0; i < snap.docs.length; i += 500) {
        final batch = db.batch();
        for (final doc in snap.docs.skip(i).take(500)) {
          final updates = <String, dynamic>{'stock': _kStock};
          // Sản phẩm có variant: tồn kho lấy theo từng variant → phải vá luôn.
          final variants = doc.data()['variants'];
          if (variants is List && variants.isNotEmpty) {
            updates['variants'] = variants
                .map((v) =>
                    {...Map<String, dynamic>.from(v as Map), 'stock': _kStock})
                .toList();
          }
          batch.update(doc.reference, updates);
        }
        await batch.commit();
      }
      _add('🎉 Hoàn tất: đặt stock=$_kStock cho ${snap.docs.length} sản phẩm.');
    } catch (e) {
      _add('❌ Lỗi: $e');
    } finally {
      if (mounted) setState(() => _running = false);
    }
  }

  void _add(String s) => setState(() => _log.add(s));

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Patch stock = 100')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ElevatedButton(
              onPressed: _running ? null : _patch,
              child: Text(_running ? 'Đang chạy...' : 'Đặt tồn kho = 100'),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: Container(
                color: const Color(0xFFF5F5F5),
                padding: const EdgeInsets.all(12),
                child: ListView(
                  children: _log
                      .map((l) => Text(l,
                          style: const TextStyle(fontFamily: 'monospace')))
                      .toList(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
