import '../../../data/models/product_model.dart';

/// Thông số kỹ thuật để hiển thị. Sản phẩm mock dùng `specs` (đã thân thiện),
/// sản phẩm thật (nhập từ template part-picker) chỉ có `compatibility` → fallback
/// sang đó để trang chi tiết/so sánh không bị trống.
Map<String, String> displaySpecs(ProductModel p) {
  if (p.specs.isNotEmpty) return p.specs;
  final out = <String, String>{};
  p.compatibility.forEach((k, v) {
    if (_skipKeys.contains(k)) return;
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
  'tags',
  'notes',
};

String formatSpecLabel(String key) {
  final mapped = _labelMap[key];
  if (mapped != null) return mapped;
  final spaced = key
      .replaceAllMapped(RegExp(r'([A-Z])'), (m) => ' ${m.group(0)!}')
      .trim();
  if (spaced.isEmpty) return key;
  return '${spaced[0].toUpperCase()}${spaced.substring(1)}';
}

const _labelMap = {
  // CPU
  'cpuSocket': 'Socket',
  'cpuCores': 'Số nhân',
  'cpuThreads': 'Số luồng',
  'cpuBaseClockGhz': 'Xung cơ bản (GHz)',
  'cpuBoostClockGhz': 'Boost Clock (GHz)',
  'cpuTdpWatts': 'TDP (W)',
  'cpuIntegratedGraphics': 'GPU tích hợp',
  'cpuMemoryType': 'Loại RAM hỗ trợ',
  'cpuMaxMemoryGb': 'RAM tối đa (GB)',
  // Mainboard
  'mbSocket': 'Socket',
  'mbChipset': 'Chipset',
  'mbMemoryType': 'Loại RAM',
  'mbFormFactor': 'Form Factor',
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
  'ramModuleCount': 'Số thanh',
  'ramSpeedMhz': 'Tốc độ (MHz)',
  'ramFormFactor': 'Form Factor',
  // GPU
  'gpuChipset': 'Chipset',
  'gpuVramGb': 'VRAM (GB)',
  'gpuLengthMm': 'Chiều dài (mm)',
  'gpuSlotWidth': 'Độ rộng khe',
  'gpuRecommendedPsuWatts': 'PSU đề xuất (W)',
  'gpuPowerConnectors': 'Nguồn phụ',
  // Storage
  'storageType': 'Loại',
  'storageInterface': 'Giao tiếp',
  'storageFormFactor': 'Form Factor',
  'storageCapacityGb': 'Dung lượng (GB)',
  'storageReadSpeedMbps': 'Tốc độ đọc (MB/s)',
  'storageWriteSpeedMbps': 'Tốc độ ghi (MB/s)',
  // PSU
  'psuWattage': 'Công suất (W)',
  'psuFormFactor': 'Form Factor',
  'psuEfficiency': 'Hiệu suất',
  'psuModular': 'Modular',
  'psuPowerConnectors': 'Đầu cấp nguồn',
  // Case
  'caseSupportedMotherboardFormFactors': 'Mainboard hỗ trợ',
  'caseMaxGpuLengthMm': 'Max GPU (mm)',
  'caseMaxCoolerHeightMm': 'Max tản nhiệt (mm)',
  'casePsuFormFactor': 'PSU hỗ trợ',
  'caseDriveBays': 'Khe ổ cứng',
  'caseFanSupport': 'Hỗ trợ quạt',
  // Cooler
  'coolerType': 'Loại',
  'coolerSupportedSockets': 'Socket hỗ trợ',
  'coolerHeightMm': 'Chiều cao (mm)',
  'coolerRadiatorSizeMm': 'Kích thước radiator (mm)',
  'coolerTdpRatingWatts': 'TDP (W)',
  // Monitor
  'monitorSizeInch': 'Kích thước (inch)',
  'monitorResolution': 'Độ phân giải',
  'monitorRefreshRateHz': 'Tần số quét (Hz)',
  'monitorPanelType': 'Tấm nền',
  // Misc
  'warrantyMonths': 'Bảo hành (tháng)',
  'releaseYear': 'Năm ra mắt',
};
