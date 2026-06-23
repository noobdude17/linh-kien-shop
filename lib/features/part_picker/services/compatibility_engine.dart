import '../../../data/models/product_model.dart';
import '../models/compatibility_result.dart';
import '../models/pc_build_model.dart';
import 'wattage_calculator.dart';

class CompatibilityEngine {
  const CompatibilityEngine();

  CompatibilitySummary evaluate(PcBuildModel build) {
    final issues = <CompatibilityIssue>[];
    final cpu = build.single('cpu');
    final mainboard = build.single('mainboard');
    final cooler = build.single('cooler');
    final pcCase = build.single('case');
    final psu = build.single('psu');
    final ram = build.items('ram');
    final storage = build.items('storage');
    final gpus = build.items('gpu');
    final monitors = build.items('monitor');
    final os = build.single('os');

    if (cpu != null && mainboard != null) {
      final cpuSocket = _string(cpu, 'cpuSocket');
      final boardSocket = _string(mainboard, 'mbSocket');
      _same(
        issues,
        code: 'cpu_socket',
        left: cpuSocket,
        right: boardSocket,
        message:
            '${cpu.name} dùng socket $cpuSocket, nhưng ${mainboard.name} dùng socket $boardSocket.',
      );
    }

    if (cpu != null && cooler != null) {
      final socket = _string(cpu, 'cpuSocket');
      final supported = _strings(cooler, 'coolerSupportedSockets');
      if (socket.isNotEmpty &&
          supported.isNotEmpty &&
          !supported.map(_norm).contains(_norm(socket))) {
        issues.add(
          CompatibilityIssue(
            code: 'cooler_socket',
            severity: CompatibilitySeverity.incompatible,
            message:
                '${cooler.name} không hỗ trợ socket $socket của ${cpu.name}.',
          ),
        );
      }
    }

    if (mainboard != null && ram.isNotEmpty) {
      final boardType = _string(mainboard, 'mbMemoryType');
      final types = ram.map((item) => _string(item, 'ramMemoryType')).toSet();
      final wrongTypes = types
          .where((type) => _norm(type) != _norm(boardType))
          .toList();
      if (wrongTypes.isNotEmpty) {
        issues.add(
          CompatibilityIssue(
            code: 'ram_type',
            severity: CompatibilitySeverity.incompatible,
            message:
                '${mainboard.name} dùng RAM $boardType, nhưng cấu hình có RAM ${wrongTypes.join(', ')}.',
          ),
        );
      }
      final usedSlots = ram.fold(
        0,
        (sum, item) =>
            sum + _number(item, 'ramSlotsUsed', fallback: 'ramModuleCount'),
      );
      final availableSlots = _number(mainboard, 'mbRamSlots');
      if (availableSlots > 0 && usedSlots > availableSlots) {
        issues.add(
          CompatibilityIssue(
            code: 'ram_slots',
            severity: CompatibilitySeverity.incompatible,
            message:
                'Cấu hình cần $usedSlots khe RAM nhưng ${mainboard.name} chỉ có $availableSlots khe.',
          ),
        );
      }
      final capacity = ram.fold(
        0,
        (sum, item) => sum + _number(item, 'ramCapacityGb'),
      );
      final maxCapacity = _number(mainboard, 'mbMaxRamGb');
      if (maxCapacity > 0 && capacity > maxCapacity) {
        issues.add(
          CompatibilityIssue(
            code: 'ram_capacity',
            severity: CompatibilitySeverity.incompatible,
            message:
                'Tổng RAM ${capacity}GB vượt mức ${maxCapacity}GB của ${mainboard.name}.',
          ),
        );
      }
      final speeds = ram.map((item) => _number(item, 'ramSpeedMhz')).toSet();
      if (ram.length > 1 && speeds.length > 1) {
        issues.add(
          CompatibilityIssue(
            code: 'mixed_ram_speed',
            severity: CompatibilitySeverity.warning,
            message:
                'Các bộ RAM khác tốc độ (${speeds.join(', ')} MHz) có thể chạy ở tốc độ thấp nhất.',
          ),
        );
      }
    }

    if (mainboard != null && storage.isNotEmpty) {
      final m2Used = storage
          .where(
            (item) => _string(item, 'storageSlotType').toLowerCase() == 'm2',
          )
          .length;
      final sataUsed = storage.length - m2Used;
      final m2Available = _number(mainboard, 'mbM2Slots');
      final sataAvailable = _number(mainboard, 'mbSataPorts');
      if (m2Available > 0 && m2Used > m2Available) {
        issues.add(
          CompatibilityIssue(
            code: 'm2_slots',
            severity: CompatibilitySeverity.incompatible,
            message:
                'Cấu hình cần $m2Used khe M.2 nhưng ${mainboard.name} chỉ có $m2Available khe.',
          ),
        );
      }
      if (sataAvailable > 0 && sataUsed > sataAvailable) {
        issues.add(
          CompatibilityIssue(
            code: 'sata_ports',
            severity: CompatibilitySeverity.incompatible,
            message:
                'Cấu hình cần $sataUsed cổng SATA nhưng ${mainboard.name} chỉ có $sataAvailable cổng.',
          ),
        );
      }
    }

    if (mainboard != null && pcCase != null) {
      final boardFormRaw = _string(mainboard, 'mbFormFactor');
      final boardForm = _norm(boardFormRaw);
      final supported = _strings(pcCase, 'caseSupportedMotherboardFormFactors');
      if (boardForm.isNotEmpty &&
          supported.isNotEmpty &&
          !supported.map(_norm).contains(boardForm)) {
        issues.add(
          CompatibilityIssue(
            code: 'case_mainboard',
            severity: CompatibilitySeverity.incompatible,
            message:
                '${mainboard.name} là chuẩn $boardFormRaw nhưng ${pcCase.name} chỉ hỗ trợ ${supported.join(', ')}.',
          ),
        );
      }
    }

    if (mainboard != null && gpus.isNotEmpty) {
      final boardPcie = _string(mainboard, 'mbPcieVersion');
      final boardPcieNumber = _pcieNumber(boardPcie);
      for (final gpu in gpus) {
        final gpuPcie = _firstString(gpu, [
          'gpuPcieVersion',
          'gpuPcieInterface',
        ]);
        final gpuPcieNumber = _pcieNumber(gpuPcie);
        if (boardPcieNumber > 0 &&
            gpuPcieNumber > 0 &&
            gpuPcieNumber > boardPcieNumber) {
          issues.add(
            CompatibilityIssue(
              code: 'gpu_pcie_${gpu.id}',
              severity: CompatibilitySeverity.warning,
              message:
                  '${gpu.name} dùng $gpuPcie, còn ${mainboard.name} hỗ trợ $boardPcie. Card vẫn có thể chạy nhưng không tối ưu băng thông.',
            ),
          );
        }
      }
    }

    if (pcCase != null) {
      final maxGpu = _number(pcCase, 'caseMaxGpuLengthMm');
      for (final gpu in gpus) {
        final length = _number(gpu, 'gpuLengthMm');
        if (maxGpu > 0 && length > maxGpu) {
          issues.add(
            CompatibilityIssue(
              code: 'gpu_length_${gpu.id}',
              severity: CompatibilitySeverity.incompatible,
              message:
                  '${gpu.name} dài ${length}mm, vượt giới hạn ${maxGpu}mm của ${pcCase.name}.',
            ),
          );
        }
      }
      if (cooler != null) {
        final maxCooler = _number(pcCase, 'caseMaxCoolerHeightMm');
        final height = _number(cooler, 'coolerHeightMm');
        if (maxCooler > 0 && height > maxCooler) {
          issues.add(
            CompatibilityIssue(
              code: 'cooler_height',
              severity: CompatibilitySeverity.incompatible,
              message:
                  '${cooler.name} cao ${height}mm, vượt giới hạn ${maxCooler}mm của ${pcCase.name}.',
            ),
          );
        }
      }
      if (psu != null) {
        final psuForm = _string(psu, 'psuFormFactor');
        final casePsuForm = _string(pcCase, 'casePsuFormFactor');
        _same(
          issues,
          code: 'psu_form_factor',
          left: psuForm,
          right: casePsuForm,
          message:
              '${psu.name} là chuẩn $psuForm, nhưng ${pcCase.name} hỗ trợ nguồn chuẩn $casePsuForm.',
        );
      }
    }

    if (psu != null) {
      final capacity = _number(psu, 'psuWattage');
      final estimated = WattageCalculator.estimated(build);
      final recommended = WattageCalculator.recommended(build);
      if (capacity > 0 && capacity < estimated) {
        issues.add(
          CompatibilityIssue(
            code: 'psu_insufficient',
            severity: CompatibilitySeverity.incompatible,
            message:
                '${psu.name} có ${capacity}W, thấp hơn mức tải ước tính ${estimated}W của cấu hình.',
          ),
        );
      } else if (capacity > 0 && capacity < recommended) {
        issues.add(
          CompatibilityIssue(
            code: 'psu_headroom',
            severity: CompatibilitySeverity.warning,
            message:
                '${psu.name} có ${capacity}W. Nên dùng nguồn ít nhất ${recommended}W để có công suất dự phòng.',
          ),
        );
      }
      _checkGpuPowerConnectors(issues, psu, gpus);
    }

    if (gpus.length > 1) {
      issues.add(
        const CompatibilityIssue(
          code: 'multiple_gpu',
          severity: CompatibilitySeverity.warning,
          message:
              'Cấu hình có nhiều card đồ họa. Vui lòng kiểm tra số khe PCIe, khoảng trống trong case và công suất nguồn.',
        ),
      );
    }
    if (monitors.length > 1) {
      issues.add(
        const CompatibilityIssue(
          code: 'multiple_monitor',
          severity: CompatibilitySeverity.warning,
          message:
              'Vui lòng kiểm tra số lượng cổng xuất hình trên card đồ họa.',
        ),
      );
    }
    if (os != null) {
      final version = _string(os, 'osVersion');
      final majorVersion = int.tryParse(version);
      if ((majorVersion != null && majorVersion < 11) ||
          _string(os, 'osSupportStatus') == 'legacy') {
        issues.add(
          const CompatibilityIssue(
            code: 'legacy_os',
            severity: CompatibilitySeverity.warning,
            message: 'Phiên bản Windows này không còn nhận bản cập nhật mới.',
          ),
        );
      }
    }

    return CompatibilitySummary(issues);
  }

  void _same(
    List<CompatibilityIssue> issues, {
    required String code,
    required String left,
    required String right,
    required String message,
  }) {
    if (left.isNotEmpty && right.isNotEmpty && _norm(left) != _norm(right)) {
      issues.add(
        CompatibilityIssue(
          code: code,
          severity: CompatibilitySeverity.incompatible,
          message: message,
        ),
      );
    }
  }

  void _checkGpuPowerConnectors(
    List<CompatibilityIssue> issues,
    ProductModel psu,
    List<ProductModel> gpus,
  ) {
    if (!_hasCompatibilityValue(psu, 'psuPowerConnectors')) return;
    final available = _connectorCounts(psu, 'psuPowerConnectors');

    final required = <String, int>{};
    final requiringGpus = <String, List<String>>{};
    for (final gpu in gpus) {
      final gpuRequired = _connectorCounts(gpu, 'gpuPowerConnectors');
      for (final entry in gpuRequired.entries) {
        required[entry.key] = (required[entry.key] ?? 0) + entry.value;
        requiringGpus.putIfAbsent(entry.key, () => []).add(gpu.name);
      }
    }
    if (required.isEmpty) return;

    for (final entry in required.entries) {
      final connector = entry.key;
      final needed = entry.value;
      final has = available[connector] ?? 0;
      if (has < needed) {
        final gpuNames = requiringGpus[connector]?.join(', ') ?? 'Card đồ họa';
        issues.add(
          CompatibilityIssue(
            code: 'gpu_power_connectors_$connector',
            severity: CompatibilitySeverity.incompatible,
            message:
                '$gpuNames cần tổng cộng ${_formatConnectorCount(needed, connector)} nhưng ${psu.name} chỉ có ${_formatConnectorCount(has, connector)}.',
          ),
        );
      }
    }
  }

  static String _string(ProductModel product, String key) {
    return product.compatibility[key]?.toString() ?? '';
  }

  static String _firstString(ProductModel product, List<String> keys) {
    for (final key in keys) {
      final value = _string(product, key);
      if (value.isNotEmpty) return value;
    }
    return '';
  }

  static List<String> _strings(ProductModel product, String key) {
    final value = product.compatibility[key];
    if (value is Iterable) return value.map((item) => item.toString()).toList();
    if (value is String) {
      return value
          .split(',')
          .map((item) => item.trim())
          .where((e) => e.isNotEmpty)
          .toList();
    }
    return const [];
  }

  static int _number(ProductModel product, String key, {String? fallback}) {
    final value =
        product.compatibility[key] ??
        (fallback == null ? null : product.compatibility[fallback]);
    return value is num
        ? value.round()
        : int.tryParse(value?.toString() ?? '') ?? 0;
  }

  static Map<String, int> _connectorCounts(ProductModel product, String key) {
    final value = product.compatibility[key];
    final parts = value is Iterable
        ? value.map((item) => item.toString()).toList()
        : value
              ?.toString()
              .split(',')
              .map((item) => item.trim())
              .where((item) => item.isNotEmpty)
              .toList();
    if (parts == null || parts.isEmpty) return const {};

    final counts = <String, int>{};
    for (final part in parts) {
      final connector = _normalizeConnector(part);
      if (connector.isEmpty) continue;
      final countMatch = RegExp(
        r'^\s*(\d+)\s*x',
      ).firstMatch(part.toLowerCase());
      final count = int.tryParse(countMatch?.group(1) ?? '') ?? 1;
      counts[connector] = (counts[connector] ?? 0) + count;
    }
    return counts;
  }

  static bool _hasCompatibilityValue(ProductModel product, String key) {
    final value = product.compatibility[key];
    if (value == null) return false;
    if (value is Iterable) return value.isNotEmpty;
    return value.toString().trim().isNotEmpty;
  }

  static String _normalizeConnector(String value) {
    final normalized = value.toLowerCase().replaceAll(RegExp(r'\s+'), ' ');
    if (normalized.contains('12vhpwr') ||
        normalized.contains('12v-2x6') ||
        normalized.contains('16-pin') ||
        normalized.contains('16 pin')) {
      return '16-pin';
    }
    if (normalized.contains('6+2') ||
        normalized.contains('8-pin') ||
        normalized.contains('8 pin')) {
      return '8-pin';
    }
    if (normalized.contains('6-pin') || normalized.contains('6 pin')) {
      return '6-pin';
    }
    return '';
  }

  static String _formatConnectorCount(int count, String connector) {
    return '${count}x $connector';
  }

  static double _pcieNumber(String value) {
    final match = RegExp(r'(\d+(\.\d+)?)').firstMatch(value);
    return double.tryParse(match?.group(1) ?? '') ?? 0;
  }

  static String _norm(String value) =>
      value.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '');
}
