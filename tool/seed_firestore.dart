// SCRIPT SEED DỮ LIỆU FIRESTORE
//
// Mục đích: đẩy 12 danh mục + danh sách sản phẩm mẫu (trong lib/data/mock_data.dart)
// lên Firestore để app có dữ liệu thật ngay.
//
// CÁCH CHẠY (sau khi đã `flutterfire configure` và bật Firestore):
//   flutter run -t tool/seed_firestore.dart
// Mở app, bấm nút "Seed dữ liệu", chờ báo "Hoàn tất", rồi tắt.
//
// Lưu ý: chạy nhiều lần sẽ ghi đè (idempotent) vì dùng id cố định.

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

import 'package:linh_kien_shop/core/constants/app_constants.dart';
import 'package:linh_kien_shop/data/mock_data.dart';
import 'package:linh_kien_shop/core/config/firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: await DefaultFirebaseOptions.currentPlatform);
  runApp(const SeedApp());
}

class SeedApp extends StatelessWidget {
  const SeedApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(home: SeedPage(), debugShowCheckedModeBanner: false);
  }
}

class SeedPage extends StatefulWidget {
  const SeedPage({super.key});

  @override
  State<SeedPage> createState() => _SeedPageState();
}

class _SeedPageState extends State<SeedPage> {
  final _log = <String>[];
  bool _running = false;

  Future<void> _seed() async {
    setState(() {
      _running = true;
      _log.clear();
    });
    final db = FirebaseFirestore.instance;

    try {
      // 1. Categories
      _add('Đang ghi danh mục...');
      for (final c in MockData.categories) {
        await db.collection(AppConstants.colCategories).doc(c.id).set(c.toFirestore());
      }
      _add('✓ ${MockData.categories.length} danh mục');

      // 2. Products (featured + gpuList, loại trùng id)
      final products = {
        for (final p in [...MockData.featured, ...MockData.gpuList]) p.id: p
      }.values.toList();
      _add('Đang ghi sản phẩm...');
      for (final p in products) {
        await db.collection(AppConstants.colProducts).doc(p.id).set(p.toFirestore());
      }
      _add('✓ ${products.length} sản phẩm');

      _add('🎉 Hoàn tất! Có thể tắt app này.');
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
      appBar: AppBar(title: const Text('Seed Firestore — Linh Kiện Shop')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ElevatedButton(
              onPressed: _running ? null : _seed,
              child: Text(_running ? 'Đang chạy...' : 'Seed dữ liệu lên Firestore'),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(12),
                color: const Color(0xFFF5F5F5),
                child: ListView(
                  children: _log.map((l) => Text(l, style: const TextStyle(fontFamily: 'monospace'))).toList(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
