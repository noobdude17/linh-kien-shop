import 'package:flutter_test/flutter_test.dart';
import 'package:linh_kien_shop/data/models/product_model.dart';
import 'package:linh_kien_shop/features/part_picker/models/compatibility_result.dart';
import 'package:linh_kien_shop/features/part_picker/models/pc_build_model.dart';
import 'package:linh_kien_shop/features/part_picker/services/compatibility_engine.dart';
import 'package:linh_kien_shop/features/part_picker/services/wattage_calculator.dart';

void main() {
  const engine = CompatibilityEngine();

  test('detects CPU and motherboard socket mismatch', () {
    final build = const PcBuildModel()
        .select('cpu', _product('cpu', {'cpuSocket': 'AM5'}), multiple: false)
        .select(
          'mainboard',
          _product('mainboard', {'mbSocket': 'LGA1700'}),
          multiple: false,
        );

    final summary = engine.evaluate(build);

    expect(summary.severity, CompatibilitySeverity.incompatible);
    expect(summary.issues.any((issue) => issue.code == 'cpu_socket'), true);
  });

  test('counts slots and capacity across multiple RAM kits', () {
    var build = const PcBuildModel().select(
      'mainboard',
      _product('mainboard', {
        'mbMemoryType': 'DDR5',
        'mbRamSlots': 4,
        'mbMaxRamGb': 64,
      }),
      multiple: false,
    );
    for (var i = 0; i < 3; i++) {
      build = build.select(
        'ram',
        _product('ram', {
          'ramMemoryType': 'DDR5',
          'ramSlotsUsed': 2,
          'ramCapacityGb': 32,
          'ramSpeedMhz': 6000,
        }, id: 'ram-$i'),
        multiple: true,
      );
    }

    final codes = engine.evaluate(build).issues.map((issue) => issue.code);

    expect(codes, contains('ram_slots'));
    expect(codes, contains('ram_capacity'));
  });

  test('counts M.2 and SATA storage separately', () {
    var build = const PcBuildModel().select(
      'mainboard',
      _product('mainboard', {'mbM2Slots': 1, 'mbSataPorts': 2}),
      multiple: false,
    );
    build = build
        .select(
          'storage',
          _product('storage', {'storageSlotType': 'm2'}, id: 'm2-1'),
          multiple: true,
        )
        .select(
          'storage',
          _product('storage', {'storageSlotType': 'm2'}, id: 'm2-2'),
          multiple: true,
        );

    expect(
      engine.evaluate(build).issues.any((issue) => issue.code == 'm2_slots'),
      true,
    );
  });

  test('calculates total wattage and warns about PSU headroom', () {
    final build = const PcBuildModel()
        .select('cpu', _powered('cpu', 120), multiple: false)
        .select('gpu', _powered('gpu', 300), multiple: true)
        .select('psu', _product('psu', {'psuWattage': 550}), multiple: false);

    expect(WattageCalculator.estimated(build), 420);
    expect(WattageCalculator.recommended(build), 650);
    expect(
      engine
          .evaluate(build)
          .issues
          .any((issue) => issue.code == 'psu_headroom'),
      true,
    );
  });

  test('detects missing GPU power connector on PSU', () {
    final build = const PcBuildModel()
        .select(
          'gpu',
          _product('gpu', {'gpuPowerConnectors': '1x 16-pin'}, id: 'rtx-5090'),
          multiple: true,
        )
        .select(
          'psu',
          _product('psu', {'psuPowerConnectors': '2x 8-pin'}),
          multiple: false,
        );

    final summary = engine.evaluate(build);

    expect(summary.severity, CompatibilitySeverity.incompatible);
    expect(
      summary.issues.map((issue) => issue.code),
      contains('gpu_power_connectors_16-pin'),
    );
  });

  test('treats 6+2-pin PSU connectors as 8-pin GPU connectors', () {
    final build = const PcBuildModel()
        .select(
          'gpu',
          _product('gpu', {'gpuPowerConnectors': '2x 8-pin'}, id: 'gpu-8-pin'),
          multiple: true,
        )
        .select(
          'psu',
          _product('psu', {'psuPowerConnectors': '2x 6+2-pin'}),
          multiple: false,
        );

    final codes = engine.evaluate(build).issues.map((issue) => issue.code);

    expect(codes, isNot(contains('gpu_power_connectors_8-pin')));
  });

  test('adds GPU connector requirements across multiple GPUs', () {
    final build = const PcBuildModel()
        .select(
          'gpu',
          _product('gpu', {'gpuPowerConnectors': '1x 8-pin'}, id: 'gpu-a'),
          multiple: true,
        )
        .select(
          'gpu',
          _product('gpu', {'gpuPowerConnectors': '1x 8-pin'}, id: 'gpu-b'),
          multiple: true,
        )
        .select(
          'psu',
          _product('psu', {'psuPowerConnectors': '1x 8-pin'}),
          multiple: false,
        );

    final codes = engine.evaluate(build).issues.map((issue) => issue.code);

    expect(codes, contains('gpu_power_connectors_8-pin'));
  });

  test('skips GPU connector rule when connector data is missing', () {
    final build = const PcBuildModel()
        .select('gpu', _product('gpu', {}, id: 'gpu-no-data'), multiple: true)
        .select(
          'psu',
          _product('psu', {'psuPowerConnectors': '1x 8-pin'}),
          multiple: false,
        );

    final codes = engine.evaluate(build).issues.map((issue) => issue.code);

    expect(
      codes.where((code) => code.startsWith('gpu_power_connectors_')),
      isEmpty,
    );
  });

  test('explicit PSU connector value None means zero available connectors', () {
    final build = const PcBuildModel()
        .select(
          'gpu',
          _product('gpu', {'gpuPowerConnectors': '1x 8-pin'}, id: 'gpu-a'),
          multiple: true,
        )
        .select(
          'psu',
          _product('psu', {'psuPowerConnectors': 'None'}),
          multiple: false,
        );

    final codes = engine.evaluate(build).issues.map((issue) => issue.code);

    expect(codes, contains('gpu_power_connectors_8-pin'));
  });

  test('multiple GPU and monitor selections create warnings', () {
    var build = const PcBuildModel();
    for (var i = 0; i < 2; i++) {
      build = build
          .select('gpu', _powered('gpu', 200, id: 'gpu-$i'), multiple: true)
          .select(
            'monitor',
            _product('monitor', {}, id: 'monitor-$i'),
            multiple: true,
          );
    }

    final codes = engine.evaluate(build).issues.map((issue) => issue.code);
    expect(codes, contains('multiple_gpu'));
    expect(codes, contains('multiple_monitor'));
  });

  test('windows 11 does not create an OS warning', () {
    final build = const PcBuildModel().select(
      'os',
      _product('os', {'osVersion': '11'}),
      multiple: false,
    );

    final codes = engine.evaluate(build).issues.map((issue) => issue.code);

    expect(codes, isNot(contains('legacy_os')));
  });

  test('older Windows creates an update warning', () {
    final build = const PcBuildModel().select(
      'os',
      _product('os', {'osVersion': '10'}),
      multiple: false,
    );

    final summary = engine.evaluate(build);

    expect(summary.issues.map((issue) => issue.code), contains('legacy_os'));
    expect(
      summary.issues.firstWhere((issue) => issue.code == 'legacy_os').message,
      contains('không còn nhận bản cập nhật mới'),
    );
  });
}

ProductModel _powered(String category, int watts, {String? id}) {
  return _product(category, {
    'estimatedPowerWatts': watts,
    'powerIncludedInPsuEstimate': true,
  }, id: id);
}

ProductModel _product(
  String category,
  Map<String, dynamic> compatibility, {
  String? id,
}) {
  return ProductModel(
    id: id ?? '$category-id',
    name: '$category product',
    price: 10000,
    categoryId: category,
    compatibility: compatibility,
  );
}
