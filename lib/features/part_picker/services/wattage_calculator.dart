import '../models/pc_build_model.dart';

class WattageCalculator {
  static const standardPsuWattages = <int>[
    450,
    550,
    650,
    750,
    850,
    1000,
    1200,
    1600,
  ];

  static int estimated(PcBuildModel build) {
    return build.allProducts.fold(0, (total, product) {
      final data = product.compatibility;
      if (data['powerIncludedInPsuEstimate'] != true) return total;
      return total + _int(data['estimatedPowerWatts']);
    });
  }

  static int recommended(PcBuildModel build) {
    final target = (estimated(build) * 1.35).ceil();
    for (final watts in standardPsuWattages) {
      if (watts >= target) return watts;
    }
    return target;
  }

  static int _int(Object? value) => value is num ? value.round() : 0;
}
