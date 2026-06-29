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
    1500,
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
    final estimatedLoad = estimated(build);
    final steadyHeadroomTarget = (estimatedLoad * 1.35).ceil();
    final gpuRecommendedTarget = _gpuRecommendedTarget(build);
    final target = steadyHeadroomTarget > gpuRecommendedTarget
        ? steadyHeadroomTarget
        : gpuRecommendedTarget;
    for (final watts in standardPsuWattages) {
      if (watts >= target) return watts;
    }
    return target;
  }

  static int _gpuRecommendedTarget(PcBuildModel build) {
    var target = 0;
    for (final gpu in build.items('gpu')) {
      final data = gpu.compatibility;
      final recommended = _int(
        data['gpuRecommendedPsuWatts'] ?? data['recommendedPsuWatts'],
      );
      final power = _int(data['gpuPowerWatts'] ?? data['estimatedPowerWatts']);
      if (recommended > target) target = recommended;

      // RTX 5090-class cards can run on the vendor minimum, but a small
      // practical headroom target avoids recommending a bare-minimum PSU.
      // Do not use GPU transient spikes as nominal PSU wattage: ATX 3.x/PCIe
      // 5.x PSUs are designed to absorb excursions above the card's steady TBP.
      if (power >= 500 && recommended > 0) {
        final highEndTarget = (recommended * 1.10).ceil();
        if (highEndTarget > target) target = highEndTarget;
      }
    }
    return target;
  }

  static int _int(Object? value) => value is num ? value.round() : 0;
}
