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
            suggestion:
                'Gợi ý: chọn tản nhiệt có hỗ trợ socket $socket hoặc đổi CPU/mainboard sang socket mà tản nhiệt hỗ trợ.',
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
            suggestion:
                'Gợi ý: chọn RAM $boardType cho mainboard này, hoặc đổi mainboard sang loại RAM đang chọn.',
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
            suggestion:
                'Gợi ý: chọn kit RAM ít thanh hơn hoặc đổi sang mainboard có nhiều khe RAM hơn.',
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
            suggestion:
                'Gợi ý: giảm dung lượng RAM hoặc đổi sang mainboard hỗ trợ dung lượng RAM cao hơn.',
          ),
        );
      }
      final speeds = ram
          .map((item) => _number(item, 'ramSpeedMhz'))
          .where((speed) => speed > 0)
          .toSet();
      if (ram.length > 1 && speeds.length > 1) {
        issues.add(
          CompatibilityIssue(
            code: 'mixed_ram_speed',
            severity: CompatibilitySeverity.warning,
            message:
                'Các bộ RAM khác tốc độ (${speeds.join(', ')} MHz) có thể chạy ở tốc độ thấp nhất.',
            suggestion:
                'Gợi ý: dùng các thanh RAM cùng tốc độ để cấu hình ổn định và dễ bật XMP/EXPO hơn.',
          ),
        );
      }
    }

    if (mainboard != null && storage.isNotEmpty) {
      final m2Used = storage.where(_isM2Storage).length;
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
            suggestion:
                'Gợi ý: giảm số SSD M.2, chọn thêm SSD SATA, hoặc đổi sang mainboard có nhiều khe M.2 hơn.',
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
            suggestion:
                'Gợi ý: giảm số ổ SATA, chọn ổ M.2 nếu còn khe, hoặc đổi sang mainboard có nhiều cổng SATA hơn.',
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
            suggestion:
                'Gợi ý: chọn case hỗ trợ chuẩn $boardFormRaw hoặc đổi sang mainboard có form factor phù hợp với case.',
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
                  '${gpu.name} dùng $gpuPcie, còn ${mainboard.name} hỗ trợ $boardPcie. Card vẫn hoạt động bình thường; nếu khe PCIe thấp hơn, băng thông tối đa sẽ bị giới hạn theo mainboard và mức ảnh hưởng thực tế thường phụ thuộc vào GPU/tác vụ.',
              suggestion:
                  'Gợi ý: để tối ưu cho ${gpu.name}, chọn mainboard/nền tảng có khe GPU PCIe 5.0 x16 như AM5, LGA1700 cao cấp hoặc LGA1851. Nếu muốn giữ mainboard này, chọn GPU PCIe 4.0 hoặc chấp nhận card chạy ở băng thông thấp hơn.',
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
              suggestion:
                  'Gợi ý: chọn case hỗ trợ GPU dài hơn ${length}mm hoặc đổi sang phiên bản card ngắn hơn.',
            ),
          );
        }
      }
      if (cooler != null) {
        final coolerType = _string(cooler, 'coolerType').toLowerCase();
        final radiatorSize = _number(cooler, 'coolerRadiatorSizeMm');
        final maxRadiator = _caseMaxRadiatorSize(pcCase);
        if (coolerType.contains('aio') &&
            radiatorSize > 0 &&
            maxRadiator > 0 &&
            radiatorSize > maxRadiator) {
          issues.add(
            CompatibilityIssue(
              code: 'cooler_radiator',
              severity: CompatibilitySeverity.incompatible,
              message:
                  '${cooler.name} dùng radiator ${radiatorSize}mm, vượt giới hạn ${maxRadiator}mm của ${pcCase.name}.',
              suggestion:
                  'Gợi ý: chọn case hỗ trợ radiator ${radiatorSize}mm hoặc đổi sang tản AIO/radiator nhỏ hơn.',
            ),
          );
        }

        final maxCooler = _number(pcCase, 'caseMaxCoolerHeightMm');
        final height = _number(cooler, 'coolerHeightMm');
        if (!coolerType.contains('aio') &&
            maxCooler > 0 &&
            height > maxCooler) {
          issues.add(
            CompatibilityIssue(
              code: 'cooler_height',
              severity: CompatibilitySeverity.incompatible,
              message:
                  '${cooler.name} cao ${height}mm, vượt giới hạn ${maxCooler}mm của ${pcCase.name}.',
              suggestion:
                  'Gợi ý: chọn case có clearance tản CPU cao hơn ${height}mm hoặc đổi sang tản thấp hơn/AIO.',
            ),
          );
        }
      }
      if (psu != null) {
        final psuForm = _string(psu, 'psuFormFactor');
        final casePsuForm = _string(pcCase, 'casePsuFormFactor');
        final supported = _strings(pcCase, 'casePsuFormFactor');
        if (psuForm.isNotEmpty &&
            supported.isNotEmpty &&
            !_caseSupportsPsuFormFactor(supported, psuForm)) {
          issues.add(
            CompatibilityIssue(
              code: 'psu_form_factor',
              severity: CompatibilitySeverity.incompatible,
              message:
                  '${psu.name} là chuẩn $psuForm, nhưng ${pcCase.name} hỗ trợ nguồn chuẩn $casePsuForm.',
              suggestion:
                  'Gợi ý: chọn nguồn chuẩn ${supported.join(', ')} cho case này hoặc đổi sang case hỗ trợ nguồn $psuForm.',
            ),
          );
        }
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
            suggestion:
                'Gợi ý: chọn nguồn công suất cao hơn, tối thiểu khoảng ${recommended}W cho cấu hình này.',
          ),
        );
      } else if (capacity > 0 && capacity < recommended) {
        issues.add(
          CompatibilityIssue(
            code: 'psu_headroom',
            severity: CompatibilitySeverity.warning,
            message:
                '${psu.name} có ${capacity}W. Nên dùng nguồn ít nhất ${recommended}W để có công suất dự phòng.',
            suggestion:
                'Gợi ý: nâng lên nguồn ${recommended}W hoặc cao hơn để có headroom cho GPU/CPU boost và nâng cấp sau này.',
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
          suggestion:
              'Gợi ý: hầu hết cấu hình gaming/workstation hiện nay nên dùng một GPU mạnh thay vì nhiều GPU.',
        ),
      );
    }
    if (os != null) {
      final majorVersion = _osMajorVersion(os);
      if ((majorVersion != null && majorVersion < 11) ||
          _string(os, 'osSupportStatus') == 'legacy') {
        issues.add(
          const CompatibilityIssue(
            code: 'legacy_os',
            severity: CompatibilitySeverity.warning,
            message:
                'Windows 10 sẽ không còn nhận các bản cập nhật mới trong tương lai.',
            suggestion:
                'Gợi ý: chọn Windows 11 nếu phần cứng hỗ trợ để nhận cập nhật lâu dài hơn.',
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
          suggestion: switch (code) {
            'cpu_socket' =>
              'Gợi ý: đổi CPU hoặc mainboard để cả hai dùng cùng socket.',
            _ => null,
          },
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
            suggestion:
                'Gợi ý: chọn nguồn có đủ ${_formatConnectorCount(needed, connector)} cho GPU, hoặc đổi sang GPU dùng ít đầu nguồn hơn.',
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
          .split(RegExp(r'[,;/|]'))
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
    if (value is num) return value.round();
    final text = value?.toString() ?? '';
    final match = RegExp(r'-?\d+(\.\d+)?').firstMatch(text);
    final parsed = num.tryParse(match?.group(0) ?? '');
    return parsed?.round() ?? 0;
  }

  static int? _firstInteger(String value) {
    final match = RegExp(r'\d+').firstMatch(value);
    return int.tryParse(match?.group(0) ?? '');
  }

  static int? _osMajorVersion(ProductModel os) {
    for (final value in [
      _string(os, 'osVersion'),
      os.name,
      os.description,
      os.imageLabel,
    ]) {
      final parsed = _firstInteger(value);
      if (parsed != null) return parsed;
    }
    return null;
  }

  static bool _isM2Storage(ProductModel product) {
    final slotType = _string(product, 'storageSlotType');
    final formFactor = _string(product, 'storageFormFactor');
    final interface = _string(product, 'storageInterface');
    final combined = '$slotType $formFactor $interface'.toLowerCase();
    final compact = combined.replaceAll(RegExp(r'[^a-z0-9]'), '');
    return compact.contains('m2') || compact.contains('nvme');
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

  static bool _caseSupportsPsuFormFactor(List<String> supported, String psuForm) {
    final normalizedSupported = supported.map(_norm).toSet();
    final normalizedPsu = _norm(psuForm);
    if (normalizedPsu.isEmpty) return true;
    if (normalizedSupported.contains(normalizedPsu)) return true;

    // SFX/SFX-L PSUs are physically smaller than ATX. Most ATX cases can use
    // them with a bracket/adapter, so do not mark them incompatible.
    final caseSupportsAtx = normalizedSupported.contains('atx');
    final psuIsSfxFamily = normalizedPsu == 'sfx' || normalizedPsu == 'sfxl';
    if (caseSupportsAtx && psuIsSfxFamily) return true;

    return false;
  }

  static String _formatConnectorCount(int count, String connector) {
    return '${count}x $connector';
  }

  static double _pcieNumber(String value) {
    final cleaned = value.replaceAll(
      RegExp(r'x\s*\d+', caseSensitive: false),
      '',
    );
    final matches = RegExp(r'(\d+(\.\d+)?)').allMatches(cleaned);
    var max = 0.0;
    for (final match in matches) {
      final number = double.tryParse(match.group(1) ?? '') ?? 0;
      if (number > max) max = number;
    }
    return max;
  }

  static int _caseMaxRadiatorSize(ProductModel pcCase) {
    final explicit = _number(pcCase, 'caseMaxRadiatorSizeMm');
    if (explicit > 0) return explicit;

    final support = _string(pcCase, 'caseFanSupport');
    final matches = RegExp(
      r'(\d{3})\s*mm\s*radiator',
      caseSensitive: false,
    ).allMatches(support);
    var max = 0;
    for (final match in matches) {
      final size = int.tryParse(match.group(1) ?? '') ?? 0;
      if (size > max) max = size;
    }
    return max;
  }

  static String _norm(String value) =>
      value.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '');
}
