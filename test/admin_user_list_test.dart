import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:linh_kien_shop/data/repositories/admin_repository.dart';
import 'package:linh_kien_shop/features/admin/providers/admin_providers.dart';
import 'package:linh_kien_shop/features/admin/screens/admin_user_list_screen.dart';

void main() {
  // Guards against the row overflowing at phone width (badges + lock button).
  testWidgets('user list renders without overflow at phone width', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(360, 690);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          adminRepositoryProvider.overrideWithValue(MockAdminRepository()),
        ],
        child: const MaterialApp(home: AdminUserListScreen()),
      ),
    );
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pump(const Duration(milliseconds: 300));
    expect(tester.takeException(), isNull);
    expect(find.text('Quản lý người dùng'), findsOneWidget);
  });
}
