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
  // Misc
  'warrantyMonths': 'Bảo hành (tháng)',
  'releaseYear': 'Năm ra mắt',
};
