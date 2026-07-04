import 'package:flutter_test/flutter_test.dart';
import 'package:linh_kien_shop/features/product/utils/spec_display.dart';

void main() {
  test('buildSpecMaps writes typed compatibility + string specs', () {
    final r = buildSpecMaps('cpu', {'cpuSocket': 'AM5', 'cpuCores': '6'}, {});
    expect(r.specs['cpuSocket'], 'AM5');
    expect(r.specs['cpuCores'], '6');
    expect(r.compatibility['cpuSocket'], 'AM5');
    expect(r.compatibility['cpuCores'], 6); // num, not "6"
  });

  test('buildSpecMaps preserves engine-only keys not in schema', () {
    final r = buildSpecMaps(
      'cpu',
      {'cpuSocket': 'AM5'},
      {'estimatedPowerWatts': 65, 'cpuSocket': 'OLD'},
    );
    expect(r.compatibility['estimatedPowerWatts'], 65);
    expect(r.compatibility['cpuSocket'], 'AM5'); // schema value overrides
  });

  test('buildSpecMaps stores bool typed + friendly display', () {
    final r = buildSpecMaps('cpu', {'cpuIntegratedGraphics': 'true'}, {});
    expect(r.compatibility['cpuIntegratedGraphics'], true); // real bool
    expect(r.specs['cpuIntegratedGraphics'], 'Có'); // friendly display
    expect(specFieldType('cpuIntegratedGraphics'), SpecFieldType.boolean);
    expect(specFieldType('cpuCores'), SpecFieldType.number);
    expect(specFieldType('cpuSocket'), SpecFieldType.text);
  });

  test('buildSpecMaps drops cleared schema keys from compatibility', () {
    final r = buildSpecMaps('cpu', {'cpuSocket': ''}, {'cpuSocket': 'AM5'});
    expect(r.compatibility.containsKey('cpuSocket'), false);
    expect(r.specs.containsKey('cpuSocket'), false);
  });

  test('normalizes compatibility-critical aliases on save', () {
    final cpu = buildSpecMaps('cpu', {
      'cpuSocket': 'Socket AM5',
      'cpuMemoryType': 'DDR5 5600',
    }, {});
    final board = buildSpecMaps('mainboard', {
      'mbSocket': 'LGA1700',
      'mbFormFactor': 'Micro ATX',
      'mbMemoryType': 'Supports JEDEC standard DDR5 5600+ MHz',
    }, {});
    final psu = buildSpecMaps('psu', {
      'psuFormFactor': 'ATX12V',
      'psuModular': 'Full',
      'psuPowerConnectors': '3x8-pin, 1x16-pin 12VHPWR',
    }, {});

    expect(cpu.compatibility['cpuSocket'], 'AM5');
    expect(cpu.compatibility['cpuMemoryType'], 'DDR5');
    expect(board.compatibility['mbSocket'], 'LGA 1700');
    expect(board.compatibility['mbFormFactor'], 'Micro-ATX');
    expect(board.compatibility['mbMemoryType'], 'DDR5');
    expect(psu.compatibility['psuFormFactor'], 'ATX');
    expect(psu.compatibility['psuModular'], 'Fully modular');
    expect(psu.compatibility['psuPowerConnectors'], '3x 8-pin, 1x 16-pin');
  });

  test('list specs save as normalized arrays for compatibility engine', () {
    final r = buildSpecMaps('case', {
      'caseSupportedMotherboardFormFactors': 'ATX / Micro ATX / Mini ITX',
      'casePsuFormFactor': 'ATX/SFX-L',
    }, {});

    expect(r.compatibility['caseSupportedMotherboardFormFactors'], [
      'ATX',
      'Micro-ATX',
      'Mini-ITX',
    ]);
    expect(r.compatibility['casePsuFormFactor'], ['ATX', 'SFX-L']);
    expect(
      r.specs['caseSupportedMotherboardFormFactors'],
      'ATX, Micro-ATX, Mini-ITX',
    );
  });

  test('os schema writes guided compatibility fields', () {
    final r = buildSpecMaps('os', {
      'osVersion': 'Windows 11 Pro',
      'osArchitecture': '64 bit',
      'osSupportStatus': 'Supported',
      'osRequiresTpm2': 'true',
    }, {});

    expect(r.compatibility['osVersion'], 11);
    expect(r.compatibility['osArchitecture'], '64-bit');
    expect(r.compatibility['osSupportStatus'], 'supported');
    expect(r.compatibility['osRequiresTpm2'], true);
  });
}
