import 'package:flutter_test/flutter_test.dart';
import 'package:linh_kien_shop/data/models/address_model.dart';
import 'package:linh_kien_shop/data/repositories/address_repository.dart';

// Step 4 (bản tự động hoá): toạ độ sống sót qua serialize, và "địa chỉ mặc định"
// luôn là 1 và đúng cái được gắn cờ. Việc soi Firestore thật cần emulator.
void main() {
  test('toFirestore/fromMap giữ nguyên lat/lng', () {
    const a = AddressModel(
      id: 'x',
      name: 'An',
      phone: '0900000000',
      detail: 'Đà Nẵng',
      isDefault: true,
      latitude: 16.0333,
      longitude: 108.2114,
    );
    final map = a.toFirestore();
    expect(map['latitude'], 16.0333);
    expect(map['longitude'], 108.2114);

    final back = AddressModel.fromMap('x', map);
    expect(back.latitude, 16.0333);
    expect(back.longitude, 108.2114);
  });

  test('add(default) → đúng 1 mặc định, nằm đầu, mang toạ độ', () async {
    final repo = MockAddressRepository();
    await repo.add(
      'u1',
      const AddressModel(
        id: '',
        name: 'Khoa',
        phone: '0911111111',
        detail: '54 Nguyễn Lương Bằng, Đà Nẵng',
        isDefault: true,
        latitude: 16.07,
        longitude: 108.15,
      ),
    );
    final list = await repo.watch('u1').first;
    expect(list.where((a) => a.isDefault).length, 1);
    expect(list.first.isDefault, isTrue);
    expect(list.first.latitude, 16.07);
  });

  test('setDefault chuyển cờ mặc định sang địa chỉ được chọn', () async {
    final repo = MockAddressRepository();
    final before = await repo
        .watch('u2')
        .first; // seed từ MockData (a1 mặc định)
    final other = before.firstWhere((a) => !a.isDefault);

    await repo.setDefault('u2', other.id);
    final after = await repo.watch('u2').first;

    expect(after.where((a) => a.isDefault).length, 1);
    expect(after.firstWhere((a) => a.id == other.id).isDefault, isTrue);
    expect(after.first.id, other.id); // mặc định lên đầu
  });
}
