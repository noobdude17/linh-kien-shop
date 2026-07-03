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
}
