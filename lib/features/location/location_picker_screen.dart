import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../../core/theme/app_colors.dart';
import '../../core/widgets/app_buttons.dart';
import 'geocode.dart';

/// Kết quả trả về cho màn gọi. Toạ độ null khi nhập tay (bản đồ lỗi/web).
class LocationResult {
  final double? lat;
  final double? lng;
  final String address;
  const LocationResult({this.lat, this.lng, required this.address});
}

/// Mặc định: Đà Nẵng.
const _danang = LatLng(16.033303367644592, 108.21139137020279);

/// Màn chọn vị trí dùng chung (đăng ký + CRUD địa chỉ). Mở bằng
/// `Navigator.push<LocationResult>(...)`, người dùng pin trên bản đồ HOẶC gõ địa
/// chỉ → tự dời pin. Bản đồ lỗi/web → tự chuyển sang nhập tay (vẫn xác nhận được).
class LocationPickerScreen extends StatefulWidget {
  final LatLng? initial;
  final String? initialText;
  const LocationPickerScreen({super.key, this.initial, this.initialText});

  @override
  State<LocationPickerScreen> createState() => _LocationPickerScreenState();
}

class _LocationPickerScreenState extends State<LocationPickerScreen> {
  final _map = MapController();
  final _search = TextEditingController();
  final _address = TextEditingController();
  Timer? _debounce;
  late LatLng _picked;
  bool _resolving = false;
  // != null → chế độ nhập tay (banner + chỉ ô text). Set lúc web hoặc tile lỗi.
  String? _mapError;

  @override
  void initState() {
    super.initState();
    _picked = widget.initial ?? _danang;
    _address.text = widget.initialText ?? '';
    if (!geocodingSupported) {
      _mapError = 'Bản đồ chưa hỗ trợ trên nền web.';
    }
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _search.dispose();
    _address.dispose();
    super.dispose();
  }

  /// Gõ địa chỉ → forward geocode → dời pin. Không tra được thì bắt nhập lại.
  Future<void> _searchAddress() async {
    final q = _search.text.trim();
    if (q.isEmpty) return;
    FocusScope.of(context).unfocus();
    setState(() => _resolving = true);
    try {
      final p = await forwardGeocode(q);
      _map.move(p, 16);
      _picked = p;
      await _resolveCenter(p);
    } on GeocodeException catch (e) {
      _snack('${e.message}, vui lòng nhập lại');
    } catch (_) {
      _snack('Không kiểm tra được địa chỉ, vui lòng nhập lại');
    } finally {
      if (mounted) setState(() => _resolving = false);
    }
  }

  void _onPositionChanged(MapCamera camera, bool hasGesture) {
    _picked = camera.center;
    if (!hasGesture) return;
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 600), () => _resolveCenter(camera.center));
  }

  /// Reverse geocode tâm bản đồ → điền ô địa chỉ (giữ nguyên nếu lỗi).
  Future<void> _resolveCenter(LatLng p) async {
    try {
      final text = await reverseGeocode(p);
      if (text.isNotEmpty && mounted) _address.text = text;
    } catch (_) {/* giữ text hiện tại */}
  }

  void _confirm() {
    final text = _address.text.trim();
    if (text.isEmpty) {
      _snack('Vui lòng nhập/chọn địa chỉ');
      return;
    }
    Navigator.pop(
      context,
      _mapError != null
          ? LocationResult(address: text)
          : LocationResult(lat: _picked.latitude, lng: _picked.longitude, address: text),
    );
  }

  void _snack(String msg) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Chọn vị trí')),
      body: Column(
        children: [
          if (_mapError == null) _searchBar(),
          Expanded(child: _mapError == null ? _mapArea() : _degradedArea()),
          _bottomBar(),
        ],
      ),
    );
  }

  Widget _searchBar() => Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
        child: TextField(
          controller: _search,
          textInputAction: TextInputAction.search,
          onSubmitted: (_) => _searchAddress(),
          decoration: InputDecoration(
            hintText: 'Nhập địa chỉ để tìm…',
            prefixIcon: const Icon(Icons.search),
            suffixIcon: _resolving
                ? const Padding(
                    padding: EdgeInsets.all(12),
                    child: SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2)),
                  )
                : IconButton(icon: const Icon(Icons.arrow_forward), onPressed: _searchAddress),
          ),
        ),
      );

  Widget _mapArea() => Stack(
        alignment: Alignment.center,
        children: [
          FlutterMap(
            mapController: _map,
            options: MapOptions(
              initialCenter: _picked,
              initialZoom: 16,
              onPositionChanged: _onPositionChanged,
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.nhom.lks.linh_kien_shop',
                // ponytail: 1 tile lỗi → chuyển nhập tay (thô nhưng an toàn, ô
                // text vẫn dùng được). Nâng cấp: chỉ chuyển khi N lỗi & 0 thành công.
                errorTileCallback: (tile, error, stack) {
                  if (_mapError == null && mounted) {
                    setState(() => _mapError = 'Không tải được bản đồ ($error).');
                  }
                },
              ),
            ],
          ),
          // Pin cố định ở tâm — tâm bản đồ chính là điểm được chọn.
          const IgnorePointer(
            child: Padding(
              padding: EdgeInsets.only(bottom: 36),
              child: Icon(Icons.location_on, size: 44, color: AppColors.primary),
            ),
          ),
          // Nút zoom — chạy được trên emulator/web/máy thật dù không pinch được.
          Positioned(
            right: 12,
            bottom: 12,
            child: Column(
              children: [
                _zoomButton(Icons.add, 'zoomIn', () => _zoom(1)),
                const SizedBox(height: 8),
                _zoomButton(Icons.remove, 'zoomOut', () => _zoom(-1)),
              ],
            ),
          ),
        ],
      );

  Widget _zoomButton(IconData icon, String tag, VoidCallback onTap) =>
      FloatingActionButton.small(
        heroTag: tag,
        backgroundColor: AppColors.surface,
        foregroundColor: AppColors.textPrimary,
        onPressed: onTap,
        child: Icon(icon),
      );

  void _zoom(double delta) {
    final c = _map.camera;
    _map.move(c.center, (c.zoom + delta).clamp(3, 19));
  }

  Widget _degradedArea() => Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.map_outlined, size: 56, color: AppColors.textSecondary),
            const SizedBox(height: 12),
            const Text(
              'Bản đồ hiện không khả dụng, vui lòng nhập địa chỉ thủ công.',
              textAlign: TextAlign.center,
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 6),
            Text(
              _mapError ?? '',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
            ),
          ],
        ),
      );

  Widget _bottomBar() => SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _mapError == null ? 'Địa chỉ (tự điền từ bản đồ)' : 'Địa chỉ',
                style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
              ),
              const SizedBox(height: 6),
              TextField(
                controller: _address,
                maxLines: 2,
                minLines: 1,
                // Chế độ bản đồ: chỉ đọc — địa chỉ phải đến từ pin/ô tìm kiếm (đã
                // geocode), không cho gõ tay để tránh nhập bừa. Chế độ nhập tay
                // (web/bản đồ lỗi) mới cho gõ trực tiếp.
                readOnly: _mapError == null,
                decoration: InputDecoration(
                  hintText: _mapError == null
                      ? 'Tìm địa chỉ hoặc di chuyển bản đồ'
                      : 'Địa chỉ giao hàng',
                ),
              ),
              const SizedBox(height: 12),
              PrimaryButton(label: 'Xác nhận vị trí', onPressed: _confirm),
            ],
          ),
        ),
      );
}
