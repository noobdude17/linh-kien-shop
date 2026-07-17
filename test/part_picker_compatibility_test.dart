import 'package:flutter_test/flutter_test.dart';
import 'package:linh_kien_shop/data/models/product_model.dart';
import 'package:linh_kien_shop/features/part_picker/models/compatibility_result.dart';
import 'package:linh_kien_shop/features/part_picker/models/pc_build_model.dart';
import 'package:linh_kien_shop/features/part_picker/services/compatibility_engine.dart';
import 'package:linh_kien_shop/features/part_picker/services/wattage_calculator.dart';
import 'package:linh_kien_shop/features/product/utils/spec_display.dart';

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

  test('normalized admin spec maps avoid alias compatibility mismatches', () {
    final cpuMaps = buildSpecMaps('cpu', {'cpuSocket': 'LGA1700'}, {});
    final boardMaps = buildSpecMaps('mainboard', {
      'mbSocket': 'LGA 1700',
      'mbMemoryType': 'Supports JEDEC standard DDR5 5600+ MHz',
      'mbRamSlots': '4 slots',
      'mbMaxRamGb': '128GB',
      'mbFormFactor': 'Micro ATX',
    }, {});
    final caseMaps = buildSpecMaps('case', {
      'caseSupportedMotherboardFormFactors': 'ATX / Micro ATX / Mini ITX',
    }, {});
    final build = const PcBuildModel()
        .select('cpu', _product('cpu', cpuMaps.compatibility), multiple: false)
        .select(
          'mainboard',
          _product('mainboard', boardMaps.compatibility),
          multiple: false,
        )
        .select(
          'case',
          _product('case', caseMaps.compatibility),
          multiple: false,
        );

    final codes = engine.evaluate(build).issues.map((issue) => issue.code);

    expect(codes, isNot(contains('cpu_socket')));
    expect(codes, isNot(contains('case_mainboard')));
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

  test('recognizes common M.2/NVMe storage labels', () {
    var build = const PcBuildModel().select(
      'mainboard',
      _product('mainboard', {'mbM2Slots': 1, 'mbSataPorts': 10}),
      multiple: false,
    );
    build = build
        .select(
          'storage',
          _product('storage', {'storageSlotType': 'M.2'}, id: 'm2-dot'),
          multiple: true,
        )
        .select(
          'storage',
          _product('storage', {
            'storageInterface': 'PCIe 4.0 x4 NVMe',
          }, id: 'nvme'),
          multiple: true,
        );

    final codes = engine.evaluate(build).issues.map((issue) => issue.code);

    expect(codes, contains('m2_slots'));
    expect(codes, isNot(contains('sata_ports')));
  });

  test('parses socket lists separated by slash', () {
    final build = const PcBuildModel()
        .select('cpu', _product('cpu', {'cpuSocket': 'AM5'}), multiple: false)
        .select(
          'cooler',
          _product('cooler', {'coolerSupportedSockets': 'AM4 / AM5'}),
          multiple: false,
        );

    final codes = engine.evaluate(build).issues.map((issue) => issue.code);

    expect(codes, isNot(contains('cooler_socket')));
  });

  test('parses numeric strings with units for clearance checks', () {
    final build = const PcBuildModel()
        .select(
          'case',
          _product('case', {'caseMaxGpuLengthMm': '300mm'}),
          multiple: false,
        )
        .select(
          'gpu',
          _product('gpu', {'gpuLengthMm': '330 mm'}, id: 'long-gpu'),
          multiple: true,
        );

    final codes = engine.evaluate(build).issues.map((issue) => issue.code);

    expect(codes, contains('gpu_length_long-gpu'));
  });

  test('does not treat missing RAM speed as a mixed-speed warning', () {
    final build = const PcBuildModel()
        .select(
          'mainboard',
          _product('mainboard', {
            'mbMemoryType': 'DDR5',
            'mbRamSlots': 4,
            'mbMaxRamGb': 128,
          }),
          multiple: false,
        )
        .select(
          'ram',
          _product('ram', {'ramMemoryType': 'DDR5'}, id: 'ram-no-speed'),
          multiple: true,
        )
        .select(
          'ram',
          _product('ram', {
            'ramMemoryType': 'DDR5',
            'ramSpeedMhz': 6000,
          }, id: 'ram-6000'),
          multiple: true,
        );

    final codes = engine.evaluate(build).issues.map((issue) => issue.code);

    expect(codes, isNot(contains('mixed_ram_speed')));
  });

  test('accepts cases that support multiple PSU form factors', () {
    final build = const PcBuildModel()
        .select(
          'case',
          _product('case', {'casePsuFormFactor': 'ATX, SFX'}),
          multiple: false,
        )
        .select(
          'psu',
          _product('psu', {'psuFormFactor': 'ATX'}),
          multiple: false,
        );

    final codes = engine.evaluate(build).issues.map((issue) => issue.code);

    expect(codes, isNot(contains('psu_form_factor')));
  });

  test('accepts SFX-L power supplies in ATX cases', () {
    final build = const PcBuildModel()
        .select(
          'case',
          _product('case', {'casePsuFormFactor': 'ATX'}),
          multiple: false,
        )
        .select(
          'psu',
          _product('psu', {'psuFormFactor': 'SFX-L'}),
          multiple: false,
        );

    final codes = engine.evaluate(build).issues.map((issue) => issue.code);

    expect(codes, isNot(contains('psu_form_factor')));
  });

  test('does not accept ATX power supplies in SFX-only cases', () {
    final build = const PcBuildModel()
        .select(
          'case',
          _product('case', {'casePsuFormFactor': 'SFX'}),
          multiple: false,
        )
        .select(
          'psu',
          _product('psu', {'psuFormFactor': 'ATX'}),
          multiple: false,
        );

    final codes = engine.evaluate(build).issues.map((issue) => issue.code);

    expect(codes, contains('psu_form_factor'));
  });

  test('does not warn when PCIe 4.0 GPU uses PCIe 3.0/4.0 motherboard', () {
    final build = const PcBuildModel()
        .select(
          'mainboard',
          _product('mainboard', {'mbPcieVersion': 'PCIe 3.0/4.0'}),
          multiple: false,
        )
        .select(
          'gpu',
          _product('gpu', {'gpuPcieVersion': 'PCIe 4.0 x16'}, id: 'rtx-3050'),
          multiple: true,
        );

    final codes = engine.evaluate(build).issues.map((issue) => issue.code);

    expect(codes, isNot(contains('gpu_pcie_rtx-3050')));
  });

  test(
    'explains PCIe generation downgrade without marking it incompatible',
    () {
      final build = const PcBuildModel()
          .select(
            'mainboard',
            _product('mainboard', {'mbPcieVersion': 'PCIe 4.0 x16'}),
            multiple: false,
          )
          .select(
            'gpu',
            _product('gpu', {'gpuPcieVersion': 'PCIe 5.0 x16'}, id: 'rtx-5090'),
            multiple: true,
          );

      final issue = engine
          .evaluate(build)
          .issues
          .singleWhere((issue) => issue.code == 'gpu_pcie_rtx-5090');

      expect(issue.severity, CompatibilitySeverity.warning);
      expect(issue.message, contains('hoạt động bình thường'));
    },
  );

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

  test('recommends practical headroom for RTX 5090 class GPU', () {
    final build = const PcBuildModel()
        .select('cpu', _powered('cpu', 95), multiple: false)
        .select(
          'gpu',
          _product('gpu', {
            'estimatedPowerWatts': 575,
            'gpuPowerWatts': 575,
            'gpuRecommendedPsuWatts': 1000,
            'powerIncludedInPsuEstimate': true,
          }, id: 'rtx-5090'),
          multiple: true,
        );

    expect(WattageCalculator.estimated(build), 670);
    expect(WattageCalculator.recommended(build), 1200);
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

  test(
    'multiple GPU selections create warnings but monitor selections do not',
    () {
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
      expect(codes, isNot(contains('multiple_monitor')));
    },
  );

  test('mouse keyboard and monitor selections do not create warnings', () {
    final build = const PcBuildModel()
        .select('mouse', _product('mouse', {}, id: 'mouse'), multiple: false)
        .select(
          'keyboard',
          _product('keyboard', {}, id: 'keyboard'),
          multiple: false,
        )
        .select(
          'monitor',
          _product('monitor', {}, id: 'monitor'),
          multiple: true,
        );

    expect(engine.evaluate(build).issues, isEmpty);
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
      contains('không còn nhận các bản cập nhật mới trong tương lai'),
    );
  });

  test('windows 10 text value creates a future update warning', () {
    final build = const PcBuildModel().select(
      'os',
      _product('os', {'osVersion': 'Windows 10'}),
      multiple: false,
    );

    final summary = engine.evaluate(build);

    expect(summary.issues.map((issue) => issue.code), contains('legacy_os'));
    expect(
      summary.issues.firstWhere((issue) => issue.code == 'legacy_os').message,
      contains('không còn nhận các bản cập nhật mới trong tương lai'),
    );
  });

  test('windows 10 product name creates a future update warning', () {
    final build = const PcBuildModel().select(
      'os',
      _product('os', {}, name: 'Microsoft Windows 10 Home OEM - DVD 64-bit'),
      multiple: false,
    );

    final summary = engine.evaluate(build);

    expect(summary.issues.map((issue) => issue.code), contains('legacy_os'));
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
  String? name,
}) {
  return ProductModel(
    id: id ?? '$category-id',
    name: name ?? '$category product',
    price: 10000,
    categoryId: category,
    compatibility: compatibility,
  );
}
