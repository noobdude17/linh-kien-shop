import '../../../data/models/product_model.dart';

/// Thông số kỹ thuật để hiển thị. Sản phẩm mock dùng `specs` (đã thân thiện),
/// sản phẩm thật (nhập từ template part-picker) chỉ có `compatibility` → fallback
/// sang đó để trang chi tiết/so sánh không bị trống.
Map<String, String> displaySpecs(ProductModel p) {
  if (p.specs.isNotEmpty) {
    return Map.fromEntries(
      p.specs.entries.where((e) => !_shouldSkipSpec(e.key)),
    );
  }
  final out = <String, String>{};
  p.compatibility.forEach((k, v) {
    if (_shouldSkipSpec(k)) return;
    final s = _stringify(v);
    if (s.isNotEmpty) out[k] = s;
  });
  return out;
}

String _stringify(dynamic v) {
  if (v == null) return '';
  if (v is bool) return v ? 'Có' : 'Không';
  if (v is Iterable) return v.join(', ');
  return v.toString();
}

// Trường nội bộ/nhiễu — không hiển thị cho người dùng.
const _skipKeys = {
  'sourceUrl',
  'sourceType',
  'inclusionScope',
  'pcppPartNumber',
  'estimatedPowerWatts',
  'powerEstimateQuality',
  'powerEstimateSource',
  'powerIncludedInPsuEstimate',
  'radiatorCompatibilitySource',
  'tags',
  'notes',
};

bool _shouldSkipSpec(String key) {
  if (_skipKeys.contains(key)) return true;
  final normalized = key.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '');
  return normalized.startsWith('ram') &&
      normalized.contains('fan') &&
      normalized.contains('included');
}

String formatSpecLabel(String key) {
  final mapped = _labelMap[key];
  if (mapped != null) return mapped;
  final spaced = _vietnameseFallbackLabel(key);
  if (spaced.isEmpty) return key;
  return '${spaced[0].toUpperCase()}${spaced.substring(1)}';
}

String _vietnameseFallbackLabel(String key) {
  final words = key
      .replaceAllMapped(RegExp(r'([A-Z])'), (m) => ' ${m.group(0)!}')
      .split(RegExp(r'[\s_]+'))
      .where((word) => word.isNotEmpty)
      .map((word) => word.toLowerCase())
      .toList();
  if (words.isEmpty) return key;

  return words
      .map((word) => _fallbackWordMap[word] ?? word.toUpperCase())
      .join(' ');
}

const _fallbackWordMap = {
  'capacity': 'dung lượng',
  'options': 'tùy chọn',
  'range': 'khoảng',
  'read': 'đọc',
  'write': 'ghi',
  'speed': 'tốc độ',
  'storage': 'lưu trữ',
  'ram': 'RAM',
  'module': 'thanh',
  'count': 'số lượng',
  'memory': 'bộ nhớ',
  'type': 'loại',
  'form': 'chuẩn',
  'factor': 'kích thước',
  'interface': 'giao tiếp',
  'architecture': 'kiến trúc',
  'edition': 'phiên bản',
  'family': 'dòng',
  'license': 'bản quyền',
  'layout': 'bố cục',
  'connection': 'kết nối',
  'switch': 'switch',
  'dpi': 'DPI',
  'weight': 'trọng lượng',
  'grams': 'gram',
  'adaptive': 'đồng bộ',
  'sync': 'thích ứng',
  'aspect': 'tỷ lệ',
  'ratio': 'khung hình',
  'brightness': 'độ sáng',
  'contrast': 'độ tương phản',
  'panel': 'tấm nền',
  'ports': 'cổng kết nối',
  'refresh': 'tần số quét',
  'resolution': 'độ phân giải',
  'response': 'phản hồi',
  'time': 'thời gian',
  'noise': 'độ ồn',
  'airflow': 'luồng gió',
  'static': 'tĩnh',
  'pressure': 'áp suất',
  'material': 'vật liệu',
  'color': 'màu sắc',
  'tube': 'ống dẫn',
  'dimensions': 'kích thước',
  'max': 'tối đa',
  'drive': 'ổ đĩa',
  'bays': 'khay',
  'fan': 'quạt',
  'support': 'hỗ trợ',
  'slot': 'khe',
  'slots': 'khe',
  'power': 'nguồn',
  'connectors': 'đầu cấp',
  'connector': 'đầu cấp',
  'recommended': 'đề xuất',
  'wattage': 'công suất',
  'watts': 'W',
  'release': 'ra mắt',
  'year': 'năm',
  'height': 'chiều cao',
  'length': 'chiều dài',
  'radiator': 'radiator',
  'size': 'kích thước',
  'supported': 'hỗ trợ',
  'sockets': 'socket',
  'socket': 'socket',
  'chipset': 'bộ chip',
  'cores': 'nhân',
  'threads': 'luồng',
  'base': 'cơ bản',
  'boost': 'boost',
  'clock': 'xung',
  'ghz': 'GHz',
  'mhz': 'MHz',
  'gb': 'GB',
  'mbps': 'MB/s',
  'pcie': 'PCIe',
  'gpu': 'GPU',
  'cpu': 'CPU',
  'os': 'hệ điều hành',
  'l2': 'L2',
  'l3': 'L3',
  'cache': 'cache',
  'manufacturing': 'tiến trình',
  'tech': 'sản xuất',
  'name': 'tên',
  'psu': 'PSU',
  'tdp': 'TDP',
};

/// Ép giá trị chuỗi admin nhập về kiểu gốc (num/bool/string) mà engine
/// part-picker + wattage calculator mong đợi.
dynamic parseSpecValue(String value, [String? key]) {
  final normalized = normalizeSpecInput(key, value);
  if (key != null && specListKeys.contains(key)) {
    return splitSpecList(normalized, key: key);
  }
  final n = num.tryParse(normalized);
  if (n != null) return n;
  if (normalized.toLowerCase() == 'true') return true;
  if (normalized.toLowerCase() == 'false') return false;
  return normalized;
}

String normalizeSpecInput(String? key, String value) {
  final trimmed = value.trim();
  if (trimmed.isEmpty || key == null) return trimmed;
  if (specListKeys.contains(key)) {
    return splitSpecList(trimmed, key: key).join(', ');
  }
  return _normalizeSingleSpecValue(key, trimmed);
}

List<String> splitSpecList(String value, {String? key}) {
  final source = value.trim();
  if (source.isEmpty) return const [];
  final raw = source
      .split(RegExp(r'[,;/|+]'))
      .map((item) => item.trim())
      .where((item) => item.isNotEmpty)
      .toList();
  final normalized = <String>[];
  for (final item in raw.isEmpty ? [source] : raw) {
    final v = _normalizeSingleSpecValue(key, item);
    if (v.isNotEmpty && !normalized.contains(v)) normalized.add(v);
  }
  return normalized;
}

String _normalizeSingleSpecValue(String? key, String value) {
  final trimmed = value.trim();
  if (trimmed.isEmpty || key == null) return trimmed;
  if (_numberSpecKeys.contains(key)) {
    final number = RegExp(r'-?\d+(\.\d+)?').firstMatch(trimmed)?.group(0);
    return number ?? trimmed;
  }
  return switch (key) {
    'cpuSocket' ||
    'mbSocket' ||
    'coolerSupportedSockets' => _normalizeSocket(trimmed),
    'mbFormFactor' || 'caseSupportedMotherboardFormFactors' =>
      _normalizeMotherboardFormFactor(trimmed),
    'casePsuFormFactor' || 'psuFormFactor' => _normalizePsuFormFactor(trimmed),
    'cpuMemoryType' ||
    'mbMemoryType' ||
    'ramMemoryType' => _normalizeMemoryType(trimmed),
    'coolerType' => _normalizeCoolerType(trimmed),
    'storageType' => _normalizeStorageType(trimmed),
    'storageFormFactor' => _normalizeStorageFormFactor(trimmed),
    'storageInterface' => _normalizeStorageInterface(trimmed),
    'gpuMemoryType' => trimmed.toUpperCase().replaceAll(' ', ''),
    'gpuPcieVersion' || 'mbPcieVersion' => _normalizePcie(trimmed),
    'gpuPowerConnectors' ||
    'psuPowerConnectors' => _normalizePowerConnectors(trimmed),
    'psuEfficiency' => _normalizePsuEfficiency(trimmed),
    'psuModular' => _normalizePsuModular(trimmed),
    'osVersion' => _normalizeOsVersion(trimmed),
    'osSupportStatus' => _normalizeOsSupportStatus(trimmed),
    'osArchitecture' => _normalizeOsArchitecture(trimmed),
    'keyboardConnection' || 'mouseConnection' => _normalizeConnection(trimmed),
    'monitorPanelType' => _normalizeMonitorPanel(trimmed),
    'monitorAspectRatio' => trimmed.replaceAll(' ', ''),
    _ => trimmed,
  };
}

String _compact(String value) =>
    value.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '');

String _normalizeSocket(String value) {
  final compact = _compact(value);
  if (compact.contains('am5')) return 'AM5';
  if (compact.contains('am4')) return 'AM4';
  final lga = RegExp(r'lga?(\d{4})').firstMatch(compact);
  if (lga != null) return 'LGA ${lga.group(1)}';
  final plainLga = RegExp(r'(\d{4})').firstMatch(compact);
  if (plainLga != null && value.toLowerCase().contains('lga')) {
    return 'LGA ${plainLga.group(1)}';
  }
  return value.trim();
}

String _normalizeMotherboardFormFactor(String value) {
  final compact = _compact(value);
  if (compact == 'eatx' || compact.contains('extendedatx')) return 'E-ATX';
  if (compact == 'matx' || compact.contains('microatx')) return 'Micro-ATX';
  if (compact.contains('miniitx')) return 'Mini-ITX';
  if (compact == 'atx') return 'ATX';
  return value.trim();
}

String _normalizePsuFormFactor(String value) {
  final compact = _compact(value);
  if (compact.contains('sfxl')) return 'SFX-L';
  if (compact == 'sfx') return 'SFX';
  if (compact.contains('atx') || compact == 'bottom') return 'ATX';
  return value.trim();
}

String _normalizeMemoryType(String value) {
  final compact = _compact(value);
  final hasDdr4 = compact.contains('ddr4');
  final hasDdr5 = compact.contains('ddr5');
  if (hasDdr4 && hasDdr5) return 'DDR4/DDR5';
  if (hasDdr5) return 'DDR5';
  if (hasDdr4) return 'DDR4';
  return value.trim();
}

String _normalizeCoolerType(String value) {
  final compact = _compact(value);
  if (compact.contains('aio') || compact.contains('liquid')) {
    return 'AIO liquid';
  }
  if (compact.contains('air')) return 'Air';
  return value.trim();
}

String _normalizeStorageType(String value) {
  final compact = _compact(value);
  if (compact.contains('ssd') || compact.contains('nvme')) return 'SSD';
  if (compact.contains('hdd')) return 'HDD';
  return value.trim().toUpperCase();
}

String _normalizeStorageFormFactor(String value) {
  final compact = _compact(value);
  if (compact.contains('m22280')) return 'M.2 2280';
  if (compact.contains('m2')) return 'M.2 2280';
  if (compact.contains('25')) return '2.5-inch';
  if (compact.contains('35')) return '3.5-inch';
  return value.trim();
}

String _normalizeStorageInterface(String value) {
  final lower = value.toLowerCase();
  if (lower.contains('sata')) return 'SATA';
  if (!lower.contains('pcie') && !lower.contains('nvme')) return value.trim();
  final gen = RegExp(r'([345])(?:\.0)?').firstMatch(lower)?.group(1);
  final lanes = RegExp(r'x\s*([1248])').firstMatch(lower)?.group(1) ?? '4';
  if (gen == null) return value.trim();
  return 'PCIe $gen.0 x$lanes NVMe';
}

String _normalizePcie(String value) {
  final lower = value.toLowerCase();
  final gen = RegExp(r'([345])(?:\.0)?').firstMatch(lower)?.group(1);
  if (gen == null) return value.trim();
  final lanes = RegExp(r'x\s*([0-9]+)').firstMatch(lower)?.group(1);
  return lanes == null ? 'PCIe $gen.0' : 'PCIe $gen.0 x$lanes';
}

String _normalizePowerConnectors(String value) {
  final compact = value.toLowerCase().replaceAll(RegExp(r'\s+'), '');
  final pattern = RegExp(
    r'(?:(\d+)x?)?(12vhpwr|12v-2x6|16-?pin|8-?pin|6\+2-?pin|6-?pin)',
    caseSensitive: false,
  );
  final parts = <String>[];
  for (final match in pattern.allMatches(compact)) {
    final count = int.tryParse(match.group(1) ?? '') ?? 1;
    final raw = (match.group(2) ?? '').toLowerCase();
    final type = raw.contains('12v') || raw.contains('16')
        ? '16-pin'
        : raw.contains('8') || raw.contains('6+2')
        ? '8-pin'
        : '6-pin';
    final normalized = '${count}x $type';
    if (!parts.contains(normalized)) parts.add(normalized);
  }
  return parts.isEmpty ? value.trim() : parts.join(', ');
}

String _normalizePsuEfficiency(String value) {
  final lower = value.toLowerCase();
  if (lower.contains('titanium')) return '80 Plus Titanium';
  if (lower.contains('platinum')) return '80 Plus Platinum';
  if (lower.contains('gold')) return '80 Plus Gold';
  if (lower.contains('bronze')) return '80 Plus Bronze';
  return value.trim();
}

String _normalizePsuModular(String value) {
  final lower = value.toLowerCase();
  if (lower == 'full' || lower.contains('fully')) return 'Fully modular';
  if (lower.contains('semi')) return 'Semi-modular';
  if (lower.contains('non')) return 'Non-modular';
  return value.trim();
}

String _normalizeOsVersion(String value) {
  final match = RegExp(r'\d+').firstMatch(value);
  return match?.group(0) ?? value.trim();
}

String _normalizeOsSupportStatus(String value) {
  final lower = value.toLowerCase();
  if (lower.contains('legacy') || lower.contains('old')) return 'legacy';
  if (lower.contains('support')) return 'supported';
  return value.trim();
}

String _normalizeOsArchitecture(String value) {
  final lower = value.toLowerCase();
  if (lower.contains('32') && lower.contains('64')) return '32/64-bit';
  if (lower.contains('64')) return '64-bit';
  if (lower.contains('32')) return '32-bit';
  return value.trim();
}

String _normalizeConnection(String value) {
  final lower = value.toLowerCase();
  final wired = lower.contains('wired') || lower.contains('cable');
  final wireless =
      lower.contains('wireless') ||
      lower.contains('bluetooth') ||
      lower.contains('2.4') ||
      lower.contains('lightspeed');
  if (wired && wireless) return 'Wired/Wireless';
  if (wireless) return 'Wireless';
  if (wired) return 'Wired';
  return value.trim();
}

String _normalizeMonitorPanel(String value) {
  final upper = value.toUpperCase().replaceAll(' ', '-');
  if (upper.contains('QD-OLED')) return 'QD-OLED';
  if (upper.contains('OLED')) return 'OLED';
  if (upper.contains('IPS')) {
    return value.toLowerCase().contains('mini') ? 'Mini LED IPS' : 'IPS';
  }
  if (upper.contains('VA')) {
    return value.toLowerCase().contains('mini') ? 'Mini LED VA' : 'VA';
  }
  if (upper.contains('TN')) return 'TN';
  return value.trim();
}

/// Từ các field cứng theo danh mục, tạo cùng lúc:
/// - `specs` (String, để hiển thị bảng thông số)
/// - `compatibility` (kiểu gốc, để engine part-picker chạy)
/// [original] là compatibility cũ của sản phẩm: giữ lại các key engine tự sinh
/// (estimatedPowerWatts, ramSlotsUsed…) không nằm trong schema, không bị xoá.
({Map<String, String> specs, Map<String, dynamic> compatibility}) buildSpecMaps(
  String? categoryId,
  Map<String, String> values,
  Map<String, dynamic> original,
) {
  final schema = categoryId == null ? null : specSchema[categoryId];
  if (schema == null) {
    // Danh mục không có field cứng → giữ compatibility gốc, specs từ values.
    return (
      specs: {
        for (final e in values.entries)
          if (e.value.trim().isNotEmpty) e.key: e.value.trim(),
      },
      compatibility: {...original},
    );
  }
  final specs = <String, String>{};
  final compatibility = {...original};
  for (final key in schema) {
    final v = values[key]?.trim() ?? '';
    if (v.isEmpty) {
      compatibility.remove(key);
      continue;
    }
    final normalized = normalizeSpecInput(key, v);
    final parsed = parseSpecValue(normalized, key);
    compatibility[key] = parsed;
    specs[key] = parsed is bool ? (parsed ? 'Có' : 'Không') : normalized;
  }
  return (specs: specs, compatibility: compatibility);
}

/// Kiểu dữ liệu của field thông số, để form admin render đúng widget
/// (switch cho bool, bàn phím số cho number).
enum SpecFieldType { text, number, boolean }

const _boolSpecKeys = {
  'cpuIntegratedGraphics',
  'mbWifi',
  'mbBluetooth',
  'osRequiresSecureBoot',
  'osRequiresTpm2',
};

const specListKeys = {
  'caseSupportedMotherboardFormFactors',
  'casePsuFormFactor',
  'coolerSupportedSockets',
};

const _numberSpecKeys = {
  'cpuCores',
  'cpuThreads',
  'cpuBaseClockGhz',
  'cpuBoostClockGhz',
  'cpuTdpWatts',
  'cpuMaxMemoryGb',
  'mbRamSlots',
  'mbMaxRamGb',
  'mbM2Slots',
  'mbSataPorts',
  'ramCapacityGb',
  'ramModuleCount',
  'ramSpeedMhz',
  'gpuVramGb',
  'gpuCoreClockMhz',
  'gpuBoostClockMhz',
  'gpuLengthMm',
  'gpuSlotWidth',
  'gpuRecommendedPsuWatts',
  'gpuPowerWatts',
  'gpuDisplayPorts',
  'gpuHdmiPorts',
  'storageCapacityGb',
  'storageReadSpeedMbps',
  'storageWriteSpeedMbps',
  'psuWattage',
  'caseMaxGpuLengthMm',
  'caseMaxCoolerHeightMm',
  'caseMaxRadiatorSizeMm',
  'coolerHeightMm',
  'coolerRadiatorSizeMm',
  'coolerFanSlots',
  'coolerFanSizeMm',
  'coolerTdpRatingWatts',
  'monitorSizeInch',
  'monitorRefreshRateHz',
  'mouseDpi',
  'mouseWeightGrams',
  'osMaxMemoryGb',
};

/// Field thông số dạng enum → form admin render dropdown thay vì nhập tay.
/// Giá trị cũ ngoài danh sách vẫn được giữ (form tự thêm vào items khi sửa).
const specEnumOptions = <String, List<String>>{
  'cpuSocket': ['AM4', 'AM5', 'LGA 1200', 'LGA 1700', 'LGA 1851'],
  'cpuMemoryType': ['DDR4', 'DDR5', 'DDR4/DDR5'],
  'mbSocket': ['AM4', 'AM5', 'LGA 1200', 'LGA 1700', 'LGA 1851'],
  'mbMemoryType': ['DDR4', 'DDR5', 'DDR4/DDR5'],
  'mbFormFactor': ['ATX', 'E-ATX', 'Micro-ATX', 'Mini-ITX'],
  'mbPcieVersion': ['PCIe 3.0', 'PCIe 4.0', 'PCIe 5.0'],
  'ramMemoryType': ['DDR4', 'DDR5'],
  'ramFormFactor': ['UDIMM', 'SODIMM'],
  'gpuMemoryType': ['GDDR6', 'GDDR6X', 'GDDR7'],
  'gpuPcieVersion': ['PCIe 3.0 x16', 'PCIe 4.0 x16', 'PCIe 5.0 x16'],
  'gpuPowerConnectors': [
    'None',
    '1x 6-pin',
    '1x 8-pin',
    '2x 8-pin',
    '1x 16-pin',
    '1x 8-pin, 1x 6-pin',
    '3x 8-pin, 1x 16-pin',
  ],
  'storageType': ['SSD', 'HDD'],
  'storageInterface': [
    'SATA',
    'PCIe 3.0 x4 NVMe',
    'PCIe 4.0 x4 NVMe',
    'PCIe 5.0 x4 NVMe',
  ],
  'storageFormFactor': ['M.2 2280', '2.5-inch', '3.5-inch'],
  'caseSupportedMotherboardFormFactors': [
    'ATX',
    'E-ATX',
    'Micro-ATX',
    'Mini-ITX',
  ],
  'casePsuFormFactor': ['ATX', 'SFX', 'SFX-L'],
  'psuEfficiency': [
    '80 Plus Bronze',
    '80 Plus Gold',
    '80 Plus Platinum',
    '80 Plus Titanium',
  ],
  'psuModular': ['Fully modular', 'Semi-modular', 'Non-modular'],
  'psuFormFactor': ['ATX', 'SFX', 'SFX-L'],
  'psuPowerConnectors': [
    '2x 8-pin',
    '3x 8-pin, 1x 16-pin',
    '4x 8-pin',
    '4x 8-pin, 1x 16-pin',
  ],
  'coolerType': ['Air', 'AIO liquid'],
  'coolerSupportedSockets': ['AM4', 'AM5', 'LGA 1200', 'LGA 1700', 'LGA 1851'],
  'monitorPanelType': [
    'IPS',
    'VA',
    'TN',
    'OLED',
    'QD-OLED',
    'Mini LED IPS',
    'Mini LED VA',
  ],
  'monitorAspectRatio': ['16:9', '21:9', '32:9'],
  'keyboardConnection': ['Wired', 'Wireless', 'Wired/Wireless'],
  'keyboardLayout': ['60%', '75%', 'TKL', 'Full-size'],
  'keyboardSwitchType': [
    'Mechanical',
    'Hot-swappable mechanical',
    'Low-profile mechanical',
    'Optical',
    'Analog Optical',
    'Mecha-membrane',
    'Scissor',
  ],
  'mouseConnection': ['Wired', 'Wireless', 'Wired/Wireless'],
  'osVersion': ['10', '11'],
  'osEdition': ['Home', 'Pro'],
  'osArchitecture': ['64-bit', '32/64-bit'],
  'osFamily': ['Windows 10', 'Windows 11'],
  'osLicenseType': ['OEM', 'Retail', 'Retail USB'],
  'osSupportStatus': ['supported', 'legacy'],
};

SpecFieldType specFieldType(String key) {
  if (_boolSpecKeys.contains(key)) return SpecFieldType.boolean;
  if (_numberSpecKeys.contains(key)) return SpecFieldType.number;
  return SpecFieldType.text;
}

/// 'true'/'Có'/'1'/'yes' → true (chấp nhận cả dữ liệu cũ).
bool isTruthySpec(String value) {
  final v = value.trim().toLowerCase();
  return v == 'true' || v == 'có' || v == 'co' || v == '1' || v == 'yes';
}

/// Thuộc tính variant cố định theo danh mục (ram/storage). Khớp key mà
/// product_listing_adapter đọc để tạo card variant.
const variantSchema = <String, List<String>>{
  'ram': ['ramMemoryType', 'ramCapacityGb', 'ramModuleCount', 'ramSpeedMhz'],
  'storage': [
    'storageCapacityGb',
    'storageReadSpeedMbps',
    'storageWriteSpeedMbps',
  ],
};

/// Trường thông số cố định theo danh mục (admin chỉ điền giá trị vào từng mục).
/// Nhãn lấy từ [formatSpecLabel]. Danh mục không có trong đây (laptop, accessory…)
/// dùng nhập tự do key/value.
const specSchema = <String, List<String>>{
  'cpu': [
    'cpuSocket',
    'cpuCores',
    'cpuThreads',
    'cpuBaseClockGhz',
    'cpuBoostClockGhz',
    'cpuTdpWatts',
    'cpuIntegratedGraphics',
    'cpuMemoryType',
    'cpuMaxMemoryGb',
    'cpuL2Cache',
    'cpuL3Cache',
    'cpuManufacturingTech',
  ],
  'mainboard': [
    'mbSocket',
    'mbChipset',
    'mbMemoryType',
    'mbFormFactor',
    'mbRamSlots',
    'mbMaxRamGb',
    'mbM2Slots',
    'mbSataPorts',
    'mbPcieVersion',
    'mbWifi',
    'mbBluetooth',
  ],
  'ram': [
    'ramMemoryType',
    'ramCapacityGb',
    'ramModuleCount',
    'ramSpeedMhz',
    'ramFormFactor',
  ],
  'gpu': [
    'gpuChipset',
    'gpuVramGb',
    'gpuMemoryType',
    'gpuCoreClockMhz',
    'gpuBoostClockMhz',
    'gpuLengthMm',
    'gpuSlotWidth',
    'gpuRecommendedPsuWatts',
    'gpuPowerConnectors',
    'gpuPowerWatts',
    'gpuPcieVersion',
    'gpuDisplayPorts',
    'gpuHdmiPorts',
  ],
  'storage': [
    'storageType',
    'storageInterface',
    'storageFormFactor',
    'storageCapacityGb',
    'storageReadSpeedMbps',
    'storageWriteSpeedMbps',
  ],
  'psu': [
    'psuWattage',
    'psuFormFactor',
    'psuEfficiency',
    'psuModular',
    'psuPowerConnectors',
  ],
  'case': [
    'caseSupportedMotherboardFormFactors',
    'caseMaxGpuLengthMm',
    'caseMaxCoolerHeightMm',
    'caseMaxRadiatorSizeMm',
    'casePsuFormFactor',
    'caseDriveBays',
    'caseFanSupport',
  ],
  'cooler': [
    'coolerType',
    'coolerSupportedSockets',
    'coolerHeightMm',
    'coolerRadiatorSizeMm',
    'coolerFanSlots',
    'coolerFanSizeMm',
    'coolerTdpRatingWatts',
    'coolerNoise',
  ],
  'monitor': [
    'monitorSizeInch',
    'monitorResolution',
    'monitorRefreshRateHz',
    'monitorPanelType',
    'monitorAdaptiveSync',
    'monitorAspectRatio',
    'monitorBrightness',
    'monitorContrastRatio',
    'monitorResponseTime',
    'monitorPorts',
  ],
  'keyboard': ['keyboardConnection', 'keyboardLayout', 'keyboardSwitchType'],
  'mouse': ['mouseConnection', 'mouseDpi', 'mouseWeightGrams'],
  'os': [
    'osVersion',
    'osEdition',
    'osFamily',
    'osArchitecture',
    'osLicenseType',
    'osSupportStatus',
    'osMaxMemoryGb',
    'osRequiresSecureBoot',
    'osRequiresTpm2',
  ],
};

const _labelMap = {
  // CPU
  'cpuSocket': 'Socket',
  'cpuCores': 'Số nhân',
  'cpuThreads': 'Số luồng',
  'cpuCoreName': 'Tên nhân',
  'cpuBaseClockGhz': 'Xung cơ bản (GHz)',
  'cpuBoostClockGhz': 'Xung boost (GHz)',
  'cpuTdpWatts': 'TDP (W)',
  'cpuIntegratedGraphics': 'GPU tích hợp',
  'cpuMemoryType': 'Loại RAM hỗ trợ',
  'cpuMaxMemoryGb': 'RAM tối đa (GB)',
  'cpuL2Cache': 'Cache L2',
  'cpuL3Cache': 'Cache L3',
  'cpuManufacturingTech': 'Tiến trình sản xuất',
  // Mainboard
  'mbSocket': 'Socket',
  'mbChipset': 'Bộ chip',
  'mbMemoryType': 'Loại RAM',
  'mbFormFactor': 'Chuẩn kích thước',
  'mbRamSlots': 'Khe RAM',
  'mbMaxRamGb': 'RAM tối đa (GB)',
  'mbM2Slots': 'Khe M.2',
  'mbSataPorts': 'Cổng SATA',
  'mbPcieVersion': 'PCIe',
  'mbWifi': 'WiFi',
  'mbBluetooth': 'Bluetooth',
  // RAM
  'ramMemoryType': 'Loại RAM',
  'ramCapacityGb': 'Dung lượng (GB)',
  'ramCapacityOptionsGb': 'Tùy chọn dung lượng RAM (GB)',
  'ramCapacityRange': 'Khoảng dung lượng RAM',
  'ramModuleCount': 'Số thanh',
  'ramModuleCountOptions': 'Tùy chọn số thanh RAM',
  'ramSlotsUsed': 'Số khe RAM dùng',
  'ramSpeedMhz': 'Tốc độ (MHz)',
  'ramSpeedOptionsMhz': 'Tùy chọn tốc độ RAM (MHz)',
  'ramSpeedRange': 'Khoảng tốc độ RAM',
  'ramFormFactor': 'Chuẩn kích thước',
  // GPU
  'gpuChipset': 'Bộ chip',
  'gpuVramGb': 'VRAM (GB)',
  'gpuLengthMm': 'Chiều dài (mm)',
  'gpuSlotWidth': 'Độ rộng khe',
  'gpuRecommendedPsuWatts': 'PSU đề xuất (W)',
  'gpuPowerConnectors': 'Nguồn phụ',
  'gpuPowerWatts': 'Công suất GPU (W)',
  'gpuPcieVersion': 'PCIe',
  'gpuPcieInterface': 'Giao tiếp PCIe',
  'gpuMemoryType': 'Loại bộ nhớ',
  'gpuBoostClockMhz': 'Xung boost (MHz)',
  'gpuCoreClockMhz': 'Xung nhân (MHz)',
  'gpuDisplayPorts': 'Cổng DisplayPort',
  'gpuHdmiPorts': 'Cổng HDMI',
  'gpuCooling': 'Tản nhiệt GPU',
  'gpuMaxResolution': 'Độ phân giải tối đa',
  'gpuDimensions': 'Kích thước',
  // Storage
  'storageType': 'Loại',
  'storageInterface': 'Giao tiếp',
  'storageFormFactor': 'Chuẩn kích thước',
  'storageCapacityGb': 'Dung lượng (GB)',
  'storageCapacityOptionsGb': 'Tùy chọn dung lượng (GB)',
  'storageReadSpeedMbps': 'Tốc độ đọc (MB/s)',
  'storageReadSpeedRangeMbps': 'Tốc độ đọc',
  'storageWriteSpeedMbps': 'Tốc độ ghi (MB/s)',
  'storageWriteSpeedRangeMbps': 'Tốc độ ghi',
  'storageSlotType': 'Loại khe',
  // PSU
  'psuWattage': 'Công suất (W)',
  'psuFormFactor': 'Chuẩn kích thước',
  'psuEfficiency': 'Hiệu suất',
  'psuModular': 'Dạng dây',
  'psuPowerConnectors': 'Đầu cấp nguồn',
  'psuConnectors': 'Đầu cấp nguồn',
  // Case
  'caseSupportedMotherboardFormFactors': 'Mainboard hỗ trợ',
  'caseMaxGpuLengthMm': 'Chiều dài GPU tối đa (mm)',
  'caseMaxCoolerHeightMm': 'Max tản nhiệt (mm)',
  'caseMaxRadiatorSizeMm': 'Radiator tối đa (mm)',
  'casePsuFormFactor': 'PSU hỗ trợ',
  'caseDriveBays': 'Khe ổ cứng',
  'caseFanSupport': 'Hỗ trợ quạt',
  // Cooler
  'coolerType': 'Loại',
  'coolerSupportedSockets': 'Socket hỗ trợ',
  'coolerHeightMm': 'Chiều cao (mm)',
  'coolerRadiatorSizeMm': 'Kích thước radiator (mm)',
  'coolerRadiatorDimensionsMm': 'Kích thước radiator (mm)',
  'coolerRadiatorMaterial': 'Vật liệu radiator',
  'coolerBlockMaterial': 'Vật liệu block',
  'coolerTubeLengthMm': 'Chiều dài ống dẫn (mm)',
  'coolerFanSlots': 'Số quạt',
  'coolerFanSizeMm': 'Kích thước quạt (mm)',
  'coolerFanSpeedRpm': 'Tốc độ quạt (RPM)',
  'coolerFanRpm': 'Tốc độ quạt (RPM)',
  'coolerFanAirflow': 'Luồng gió quạt',
  'coolerFanAirflowCfm': 'Luồng gió quạt (CFM)',
  'coolerFanNoiseDba': 'Độ ồn quạt (dBA)',
  'coolerFanStaticPressureMmH2O': 'Áp suất tĩnh quạt (mmH2O)',
  'coolerNoise': 'Độ ồn',
  'coolerTdpRatingWatts': 'TDP (W)',
  'color': 'Màu sắc',
  // Monitor
  'monitorSizeInch': 'Kích thước (inch)',
  'monitorResolution': 'Độ phân giải',
  'monitorRefreshRateHz': 'Tần số quét (Hz)',
  'monitorPanelType': 'Tấm nền',
  'monitorAdaptiveSync': 'Đồng bộ thích ứng',
  'monitorAspectRatio': 'Tỷ lệ khung hình',
  'monitorBrightness': 'Độ sáng',
  'monitorContrastRatio': 'Độ tương phản',
  'monitorPorts': 'Cổng kết nối',
  'monitorResponseTime': 'Thời gian phản hồi',
  // Keyboard
  'keyboardConnection': 'Kết nối',
  'keyboardLayout': 'Bố cục bàn phím',
  'keyboardSwitchType': 'Loại switch',
  // Mouse
  'mouseConnection': 'Kết nối',
  'mouseDpi': 'DPI',
  'mouseWeightGrams': 'Trọng lượng (g)',
  // OS
  'osArchitecture': 'Kiến trúc',
  'osEdition': 'Phiên bản',
  'osFamily': 'Dòng hệ điều hành',
  'osLicenseType': 'Loại bản quyền',
  'osMaxMemoryGb': 'RAM tối đa (GB)',
  'osRequiresSecureBoot': 'Yêu cầu Secure Boot',
  'osRequiresTpm2': 'Yêu cầu TPM 2.0',
  'osSupportStatus': 'Trạng thái hỗ trợ',
  'osVersion': 'Phiên bản Windows',
  // Misc
  'warrantyMonths': 'Bảo hành (tháng)',
  'releaseYear': 'Năm ra mắt',
};
