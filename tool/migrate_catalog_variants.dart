import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

import 'package:linh_kien_shop/core/config/firebase_options.dart';
import 'package:linh_kien_shop/core/constants/app_constants.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: await DefaultFirebaseOptions.currentPlatform,
  );
  runApp(
    const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: CatalogVariantMigrationPage(),
    ),
  );
}

class CatalogVariantMigrationPage extends StatefulWidget {
  const CatalogVariantMigrationPage({super.key});

  @override
  State<CatalogVariantMigrationPage> createState() =>
      _CatalogVariantMigrationPageState();
}

class _CatalogVariantMigrationPageState
    extends State<CatalogVariantMigrationPage> {
  final _logs = <String>[];
  bool _running = false;

  Future<void> _migrate() async {
    setState(() {
      _running = true;
      _logs.clear();
    });

    try {
      final db = FirebaseFirestore.instance;
      final snapshot = await db
          .collection(AppConstants.colProducts)
          .where('categoryId', whereIn: const ['ram', 'storage'])
          .get();
      final legacy = snapshot.docs
          .where((doc) => (doc.data()['variants'] as List? ?? []).isEmpty)
          .toList();

      final groups =
          <String, List<QueryDocumentSnapshot<Map<String, dynamic>>>>{};
      for (final doc in legacy) {
        final baseId = _baseId(
          doc.id,
          doc.data()['categoryId'] as String? ?? '',
        );
        if (baseId == null) {
          throw StateError('Không nhận dạng được tên biến thể: ${doc.id}');
        }
        groups.putIfAbsent(baseId, () => []).add(doc);
      }

      if (groups.isEmpty) {
        _add('Không còn sản phẩm RAM/SSD dạng cũ cần chuyển đổi.');
        return;
      }

      _add(
        'Tìm thấy ${legacy.length} bản ghi cũ trong ${groups.length} dòng sản phẩm.',
      );

      final batch = db.batch();
      for (final entry in groups.entries) {
        final documents = entry.value..sort((a, b) => a.id.compareTo(b.id));
        final categoryId = documents.first.data()['categoryId'] as String;
        final source = _preferredSource(documents);
        final baseData = Map<String, dynamic>.from(source.data());
        final variants =
            documents
                .map((doc) => _variant(doc, categoryId, entry.key))
                .toList()
              ..sort((a, b) {
                final aAttrs = a['attributes'] as Map<String, dynamic>;
                final bAttrs = b['attributes'] as Map<String, dynamic>;
                final capacityKey = categoryId == 'ram'
                    ? 'ramCapacityGb'
                    : 'storageCapacityGb';
                final capacity = (aAttrs[capacityKey] as num).compareTo(
                  bAttrs[capacityKey] as num,
                );
                if (capacity != 0) return capacity;
                return (a['name'] as String).compareTo(b['name'] as String);
              });

        final cheapest = variants.reduce(
          (a, b) => (a['price'] as num) <= (b['price'] as num) ? a : b,
        );
        baseData
          ..['name'] = _baseName(source.data()['name'] as String, categoryId)
          ..['price'] = cheapest['price']
          ..['oldPrice'] = cheapest['oldPrice']
          ..['stock'] = variants.fold<int>(
            0,
            (total, variant) => total + (variant['stock'] as int),
          )
          ..['variants'] = variants
          ..['variantSchemaVersion'] = 1
          ..['legacyProductIds'] = documents.map((doc) => doc.id).toList()
          ..['specs'] = _withoutVariantFields(
            Map<String, dynamic>.from(baseData['specs'] ?? {}),
            categoryId,
          )
          ..['compatibility'] = _withoutVariantFields(
            Map<String, dynamic>.from(baseData['compatibility'] ?? {}),
            categoryId,
          );

        if (baseData['tags'] is List) {
          baseData['tags'] = (baseData['tags'] as List)
              .where((tag) => !_isVariantTag('$tag'))
              .toList();
        }

        final target = db.collection(AppConstants.colProducts).doc(entry.key);
        batch.set(target, baseData);
        for (final document in documents) {
          batch.delete(document.reference);
        }
        _add('${baseData['name']}: ${variants.length} tùy chọn');
      }

      await batch.commit();
      _add(
        'Hoàn tất: ${legacy.length} bản ghi cũ → ${groups.length} sản phẩm có biến thể.',
      );
    } catch (error, stack) {
      _add('LỖI: $error');
      debugPrintStack(stackTrace: stack);
    } finally {
      if (mounted) setState(() => _running = false);
    }
  }

  QueryDocumentSnapshot<Map<String, dynamic>> _preferredSource(
    List<QueryDocumentSnapshot<Map<String, dynamic>>> documents,
  ) {
    return documents.reduce((a, b) {
      final aPrice = (a.data()['price'] as num?) ?? double.infinity;
      final bPrice = (b.data()['price'] as num?) ?? double.infinity;
      return aPrice <= bPrice ? a : b;
    });
  }

  Map<String, dynamic> _variant(
    QueryDocumentSnapshot<Map<String, dynamic>> document,
    String categoryId,
    String baseId,
  ) {
    final data = document.data();
    final compatibility = Map<String, dynamic>.from(
      data['compatibility'] ?? {},
    );
    final attributes = <String, dynamic>{};
    for (final key in _variantKeys(categoryId)) {
      if (compatibility.containsKey(key)) attributes[key] = compatibility[key];
    }

    final name = data['name'] as String;
    return {
      'id': document.id.substring(baseId.length + 1),
      'name': _variantName(name, categoryId, attributes),
      'price': data['price'] ?? 0,
      'oldPrice': data['oldPrice'],
      'stock': data['stock'] ?? 0,
      'attributes': attributes,
    };
  }

  String? _baseId(String id, String categoryId) {
    final pattern = categoryId == 'ram'
        ? RegExp(r'-\d+gb-\d+x\d+gb-\d+mt-s$')
        : RegExp(r'-\d+(?:gb|tb)-ssd$');
    if (!pattern.hasMatch(id)) return null;
    return id.replaceFirst(pattern, '');
  }

  String _baseName(String name, String categoryId) {
    final pattern = categoryId == 'ram'
        ? RegExp(r'\s+\d+GB\s+\(\d+x\d+GB\)\s+\d+MT/s$', caseSensitive: false)
        : RegExp(r'\s+\d+(?:GB|TB)\s+SSD$', caseSensitive: false);
    return name.replaceFirst(pattern, '').trim();
  }

  String _variantName(
    String legacyName,
    String categoryId,
    Map<String, dynamic> attributes,
  ) {
    if (categoryId == 'storage') {
      return RegExp(
            r'(\d+(?:GB|TB))\s+SSD$',
            caseSensitive: false,
          ).firstMatch(legacyName)?.group(1)?.toUpperCase() ??
          '${attributes['storageCapacityGb']}GB';
    }
    final capacity = attributes['ramCapacityGb'];
    final modules = attributes['ramModuleCount'];
    final speed = attributes['ramSpeedMhz'];
    final moduleSize = capacity is num && modules is num && modules > 0
        ? capacity ~/ modules
        : null;
    final layout = moduleSize == null ? '' : ' (${modules}x${moduleSize}GB)';
    return '$capacity'
        'GB$layout'
        ' · ${speed}MT/s';
  }

  Map<String, dynamic> _withoutVariantFields(
    Map<String, dynamic> values,
    String categoryId,
  ) {
    for (final key in _variantKeys(categoryId)) {
      values.remove(key);
    }
    return values;
  }

  List<String> _variantKeys(String categoryId) => categoryId == 'ram'
      ? const ['ramCapacityGb', 'ramModuleCount', 'ramSlotsUsed', 'ramSpeedMhz']
      : const [
          'storageCapacityGb',
          'storageReadSpeedMbps',
          'storageWriteSpeedMbps',
        ];

  bool _isVariantTag(String tag) => RegExp(
    r'^\d+(?:gb|tb)$|^\d+(?:mts|mhz)$',
    caseSensitive: false,
  ).hasMatch(tag);

  void _add(String message) {
    if (mounted) setState(() => _logs.add(message));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Chuẩn hóa RAM và SSD')),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            FilledButton(
              onPressed: _running ? null : _migrate,
              child: Text(_running ? 'Đang chuyển đổi...' : 'Chạy chuyển đổi'),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: ListView(
                children: _logs
                    .map(
                      (log) => Padding(
                        padding: const EdgeInsets.only(bottom: 4),
                        child: Text(log),
                      ),
                    )
                    .toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
