// Patch GPU/PSU connector fields for the Part Picker compatibility engine.
//
// Run after Firebase is configured:
//   flutter run -t tool/patch_part_picker_connectors.dart
//
// This script only writes:
//   compatibility.gpuPowerConnectors
//   compatibility.psuPowerConnectors
//
// Missing/unknown products are skipped so it is safe to run more than once.

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
  runApp(const ConnectorPatchApp());
}

class ConnectorPatchApp extends StatelessWidget {
  const ConnectorPatchApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      home: ConnectorPatchPage(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class ConnectorPatchPage extends StatefulWidget {
  const ConnectorPatchPage({super.key});

  @override
  State<ConnectorPatchPage> createState() => _ConnectorPatchPageState();
}

class _ConnectorPatchPageState extends State<ConnectorPatchPage> {
  final _log = <String>[];
  bool _running = false;

  Future<void> _patch() async {
    setState(() {
      _running = true;
      _log.clear();
    });

    try {
      final db = FirebaseFirestore.instance;
      final products = db.collection(AppConstants.colProducts);
      final snap = await products.get();
      final batch = db.batch();
      var patched = 0;
      var skipped = 0;

      for (final doc in snap.docs) {
        final data = doc.data();
        final categoryId = data['categoryId']?.toString() ?? '';
        final name = data['name']?.toString() ?? doc.id;
        final compatibility = Map<String, dynamic>.from(
          data['compatibility'] as Map? ?? {},
        );

        final updates = <String, dynamic>{};
        if (categoryId == 'gpu') {
          final connectors = _gpuConnectors(name);
          if (connectors == null) {
            skipped++;
            _add('Bỏ qua GPU chưa nhận diện: $name');
            continue;
          }
          updates['compatibility.gpuPowerConnectors'] = connectors;
        } else if (categoryId == 'psu') {
          final watts = _number(compatibility['psuWattage']) ?? _watts(name);
          final connectors = _psuConnectors(name, watts);
          if (connectors == null) {
            skipped++;
            _add('Bỏ qua PSU chưa nhận diện: $name');
            continue;
          }
          updates['compatibility.psuPowerConnectors'] = connectors;
        } else {
          continue;
        }

        batch.update(doc.reference, updates);
        patched++;
        _add('Cập nhật $name -> ${updates.values.join(' | ')}');
      }

      if (patched > 0) await batch.commit();
      _add('Hoàn tất: cập nhật $patched sản phẩm, bỏ qua $skipped sản phẩm.');
    } catch (e) {
      _add('Lỗi: $e');
    } finally {
      if (mounted) setState(() => _running = false);
    }
  }

  void _add(String message) => setState(() => _log.add(message));

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Patch connector fields')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ElevatedButton(
              onPressed: _running ? null : _patch,
              child: Text(_running ? 'Đang chạy...' : 'Patch connector data'),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: Container(
                color: const Color(0xFFF5F5F5),
                padding: const EdgeInsets.all(12),
                child: ListView(
                  children: _log
                      .map(
                        (line) => Text(
                          line,
                          style: const TextStyle(fontFamily: 'monospace'),
                        ),
                      )
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

String? _gpuConnectors(String name) {
  final text = name.toLowerCase();
  if (text.contains('rtx 5090') ||
      text.contains('rtx 4090') ||
      text.contains('rtx 4080') ||
      text.contains('rtx 4070')) {
    return '1x 16-pin';
  }
  if (text.contains('rtx 3090') ||
      text.contains('rtx 3080') ||
      text.contains('rx 7900') ||
      text.contains('rx 7800')) {
    return '2x 8-pin';
  }
  if (text.contains('rtx 3070') ||
      text.contains('rtx 3060') ||
      text.contains('rtx 4060') ||
      text.contains('rx 7700') ||
      text.contains('rx 6800') ||
      text.contains('rx 6700') ||
      text.contains('rx 6600')) {
    return '1x 8-pin';
  }
  if (text.contains('gtx 1650') ||
      text.contains('gt 1030') ||
      text.contains('rx 6400')) {
    return 'None';
  }
  return null;
}

String? _psuConnectors(String name, int? watts) {
  final text = name.toLowerCase();
  if (text.contains('asus prime gold')) return '3x 8-pin, 1x 16-pin';
  if (text.contains('rog loki')) return '3x 8-pin, 1x 16-pin';
  if (text.contains('rog strix gold aura')) {
    return watts != null && watts >= 1000
        ? '4x 8-pin, 1x 16-pin'
        : '3x 8-pin, 1x 16-pin';
  }
  if (text.contains('rog thor platinum ii')) {
    return watts != null && watts >= 1000
        ? '8x 8-pin, 1x 16-pin'
        : '3x 8-pin, 1x 16-pin';
  }
  if (text.contains('tuf gaming bronze')) {
    return watts != null && watts >= 750 ? '4x 8-pin' : '2x 8-pin';
  }
  if (text.contains('tuf gaming gold')) {
    return watts != null && watts >= 1000
        ? '4x 8-pin, 1x 16-pin'
        : '3x 8-pin, 1x 16-pin';
  }
  if (text.contains('mag a-bn')) return '2x 8-pin';
  if (text.contains('mag a-gl pcie5')) {
    if (watts != null && watts >= 1000) return '4x 8-pin, 1x 16-pin';
    if (watts != null && watts >= 750) return '3x 8-pin, 1x 16-pin';
    return '2x 8-pin, 1x 16-pin';
  }
  if (text.contains('mag a-pls pcie5')) return '4x 8-pin, 1x 16-pin';
  if (text.contains('meg ai pcie5')) {
    return watts != null && watts >= 1300
        ? '8x 8-pin, 1x 16-pin'
        : '6x 8-pin, 1x 16-pin';
  }
  if (text.contains('mpg a-g pcie5')) {
    return watts != null && watts >= 1000
        ? '4x 8-pin, 1x 16-pin'
        : '3x 8-pin, 1x 16-pin';
  }
  return null;
}

int? _watts(String text) {
  final match = RegExp(r'(\d{3,4})\s*w', caseSensitive: false).firstMatch(text);
  return int.tryParse(match?.group(1) ?? '');
}

int? _number(Object? value) {
  if (value is num) return value.round();
  return int.tryParse(value?.toString() ?? '');
}
