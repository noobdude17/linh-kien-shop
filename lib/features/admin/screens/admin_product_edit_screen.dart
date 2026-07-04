import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/services/cloudinary.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/app_buttons.dart';
import '../../../core/widgets/image_placeholder.dart';
import '../../../data/models/category_model.dart';
import '../../../data/repositories/brand_repository.dart';
import '../../../data/models/product_model.dart';
import '../../../data/models/product_variant.dart';
import '../../../routes/app_routes.dart';
import '../../product/providers/product_providers.dart';
import '../../product/utils/spec_display.dart';
import '../providers/admin_providers.dart';

class AdminProductEditScreen extends ConsumerStatefulWidget {
  final String? productId;
  const AdminProductEditScreen({super.key, this.productId});

  @override
  ConsumerState<AdminProductEditScreen> createState() =>
      _AdminProductEditScreenState();
}

class _AdminProductEditScreenState
    extends ConsumerState<AdminProductEditScreen> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _brand = TextEditingController();
  final _description = TextEditingController();
  final _price = TextEditingController();
  final _oldPrice = TextEditingController();
  final _stock = TextEditingController();
  final _imageLabel = TextEditingController();
  final _imageUrl = TextEditingController();
  final _specs = <_Pair>[]; // dùng khi danh mục không có schema cố định
  final _specValues =
      <String, String>{}; // giá trị ban đầu để đổ vào field cứng
  final _specControllers = <String, TextEditingController>{};
  // compatibility gốc: giữ key engine tự sinh không nằm trong schema (không xoá).
  final _originalCompatibility = <String, dynamic>{};
  final _gallery = <TextEditingController>[];
  final _variants = <_VariantDraft>[];

  String? _categoryId;
  String _categoryName = '';
  bool _active = true;
  bool _saving = false;
  bool _loaded = false;
  double _rating = 0;
  int _reviewCount = 0;

  bool get _editing => widget.productId != null;

  @override
  void dispose() {
    for (final c in [
      _name,
      _brand,
      _description,
      _price,
      _oldPrice,
      _stock,
      _imageLabel,
      _imageUrl,
      ..._gallery,
    ]) {
      c.dispose();
    }
    for (final p in _specs) {
      p.dispose();
    }
    for (final c in _specControllers.values) {
      c.dispose();
    }
    for (final v in _variants) {
      v.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final productAsync = _editing
        ? ref.watch(adminProductProvider(widget.productId!))
        : const AsyncValue<ProductModel?>.data(null);
    final categories = ref.watch(categoriesProvider);

    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.adminAccent,
        foregroundColor: Colors.white,
        leading: BackButton(
          onPressed: () => context.go(AppRoutes.adminProducts),
        ),
        title: Text(_editing ? 'Sửa sản phẩm' : 'Thêm sản phẩm'),
      ),
      body: productAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => _error('Không tải được sản phẩm'),
        data: (product) {
          if (_editing && product == null) {
            return _error('Không tìm thấy sản phẩm');
          }
          if (!_loaded) {
            _loaded = true;
            if (product != null) _hydrate(product);
          }
          return categories.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => _error('Không tải được danh mục'),
            data: (cats) => _form(cats),
          );
        },
      ),
    );
  }

  void _hydrate(ProductModel p) {
    _name.text = p.name;
    _brand.text = p.brand;
    _description.text = p.description;
    _price.text = p.price.toStringAsFixed(0);
    _oldPrice.text = p.oldPrice?.toStringAsFixed(0) ?? '';
    _stock.text = '${p.stock}';
    _imageLabel.text = p.imageLabel;
    _imageUrl.text = p.imageUrl;
    _categoryId = p.categoryId;
    _categoryName = p.categoryName;
    _active = p.isActive;
    _rating = p.rating;
    _reviewCount = p.reviewCount;
    _specs.addAll(p.specs.entries.map((e) => _Pair(e.key, e.value)));
    // Field cứng lấy giá trị từ compatibility (sản phẩm thật) rồi specs ghi đè.
    p.compatibility.forEach((k, v) {
      final s = '$v'.trim();
      if (s.isNotEmpty) _specValues[k] = s;
    });
    _specValues.addAll(p.specs);
    _originalCompatibility.addAll(p.compatibility);
    _gallery.addAll(p.images.map((url) => TextEditingController(text: url)));
    _variants.addAll(p.variants.map(_VariantDraft.fromVariant));
  }

  Widget _form(List<CategoryModel> categories) {
    // Sản phẩm mới: mặc định danh mục CPU để field thông số tự hiện.
    if (!_editing && _categoryId == null && categories.isNotEmpty) {
      final def = categories.firstWhere(
        (c) => c.id == 'cpu',
        orElse: () => categories.first,
      );
      _categoryId = def.id;
      _categoryName = def.name;
    }
    return Form(
      key: _formKey,
      child: ListView(
        padding: const EdgeInsets.all(18),
        children: [
          _imageSection(),
          const SizedBox(height: 20),
          _field('Tên sản phẩm', _name, isRequired: true),
          _brandField(),
          DropdownButtonFormField<String>(
            initialValue: categories.any((c) => c.id == _categoryId)
                ? _categoryId
                : null,
            decoration: InputDecoration(label: _requiredLabel('Danh mục')),
            items: categories
                .map((c) => DropdownMenuItem(value: c.id, child: Text(c.name)))
                .toList(),
            validator: (v) => v == null ? 'Vui lòng chọn danh mục' : null,
            onChanged: (id) {
              final cat = categories.firstWhere((c) => c.id == id);
              setState(() {
                _categoryId = cat.id;
                _categoryName = cat.name;
              });
            },
          ),
          const SizedBox(height: 14),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: SizedBox(
              width: 560,
              child: Row(
                children: [
                  Expanded(
                    child: _field(
                      'Giá',
                      _price,
                      number: true,
                      isRequired: true,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(child: _field('Giá KM', _oldPrice, number: true)),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _field(
                      'Tồn kho',
                      _stock,
                      number: true,
                      isRequired: true,
                    ),
                  ),
                ],
              ),
            ),
          ),
          _field('Mô tả', _description, maxLines: 3),
          _field('Nhãn ảnh fallback', _imageLabel),
          _specSection(),
          _variantSection(),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Đang bán', style: TextStyle(fontSize: 14)),
            value: _active,
            activeThumbColor: AppColors.success,
            onChanged: (v) => setState(() => _active = v),
          ),
          const SizedBox(height: 8),
          _saving
              ? const Center(child: CircularProgressIndicator())
              : PrimaryButton(label: 'Lưu sản phẩm', onPressed: _save),
        ],
      ),
    );
  }

  Widget _imageSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            InkWell(
              onTap: () => _pickImage(primary: true),
              child: Container(
                width: 88,
                height: 88,
                decoration: BoxDecoration(
                  border: Border.all(color: AppColors.adminAccent, width: 1.5),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.add_a_photo_outlined,
                      color: AppColors.adminAccent,
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Ảnh chính',
                      style: TextStyle(
                        fontSize: 11,
                        color: AppColors.adminAccent,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: GestureDetector(
                onTap: () => _showImagePreview(_imageUrl.text),
                child: ImagePlaceholder(
                  label: _imageLabel.text.isEmpty ? 'IMG' : _imageLabel.text,
                  imageUrl: _imageUrl.text,
                  height: 88,
                  radius: 8,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        _field('URL ảnh chính', _imageUrl),
        Row(
          children: [
            const Text(
              'Gallery',
              style: TextStyle(fontWeight: FontWeight.w700),
            ),
            const Spacer(),
            TextButton.icon(
              onPressed: () => _pickImage(primary: false),
              icon: const Icon(Icons.upload, size: 18),
              label: const Text('Upload ảnh phụ'),
            ),
            IconButton(
              onPressed: () =>
                  setState(() => _gallery.add(TextEditingController())),
              icon: const Icon(Icons.add),
            ),
          ],
        ),
        for (var i = 0; i < _gallery.length; i++)
          Row(
            children: [
              GestureDetector(
                onTap: () => _showImagePreview(_gallery[i].text),
                child: ImagePlaceholder(
                  label: 'IMG',
                  imageUrl: _gallery[i].text,
                  width: 48,
                  height: 48,
                  radius: 6,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(child: _field('URL ảnh phụ ${i + 1}', _gallery[i])),
              IconButton(
                onPressed: () => setState(() => _gallery.removeAt(i).dispose()),
                icon: const Icon(Icons.close, color: AppColors.error),
              ),
            ],
          ),
      ],
    );
  }

  /// Hãng: dropdown từ collection brands + nút mở CRUD hãng bên cạnh.
  Widget _brandField() {
    final brands =
        ref.watch(brandsProvider).asData?.value ?? const <BrandModel>[];
    final current = _brand.text.trim();
    final names = [for (final b in brands) b.name];
    // Hãng của sản phẩm cũ chưa có trong collection vẫn chọn được.
    final items = [
      ...names,
      if (current.isNotEmpty && !names.contains(current)) current,
    ];
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        children: [
          Expanded(
            child: DropdownButtonFormField<String>(
              // Danh sách hãng đổi (thêm/sửa/xóa) → dựng lại dropdown.
              key: ValueKey(items.join('|')),
              initialValue: items.contains(current) ? current : null,
              isExpanded: true,
              decoration: const InputDecoration(labelText: 'Thương hiệu'),
              items: [
                for (final name in items)
                  DropdownMenuItem(value: name, child: Text(name)),
              ],
              onChanged: (v) => _brand.text = v ?? '',
            ),
          ),
          IconButton(
            tooltip: 'Thêm / quản lý hãng',
            onPressed: _showBrandManager,
            icon: const Icon(
              Icons.add_business_outlined,
              color: AppColors.adminAccent,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _showBrandManager() async {
    final input = TextEditingController();
    final repo = ref.read(brandRepositoryProvider);
    await showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Quản lý hãng'),
        content: SizedBox(
          width: double.maxFinite,
          child: Consumer(
            builder: (ctx, ref, _) {
              final brands =
                  ref.watch(brandsProvider).asData?.value ??
                  const <BrandModel>[];
              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: input,
                          decoration: const InputDecoration(
                            hintText: 'Tên hãng mới',
                          ),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(
                          Icons.add_circle,
                          color: AppColors.adminAccent,
                        ),
                        onPressed: () async {
                          final name = input.text.trim();
                          if (name.isEmpty) return;
                          await repo.add(name);
                          input.clear();
                          // Hãng vừa tạo được chọn luôn cho sản phẩm đang sửa.
                          _brand.text = name;
                          ref.invalidate(brandsProvider);
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Flexible(
                    child: ListView(
                      shrinkWrap: true,
                      children: [
                        for (final b in brands)
                          ListTile(
                            contentPadding: EdgeInsets.zero,
                            dense: true,
                            title: Text(b.name),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  icon: const Icon(
                                    Icons.edit_outlined,
                                    size: 18,
                                  ),
                                  onPressed: () => _renameBrand(b),
                                ),
                                IconButton(
                                  icon: const Icon(
                                    Icons.delete_outline,
                                    size: 18,
                                    color: AppColors.error,
                                  ),
                                  onPressed: () async {
                                    await repo.delete(b.id);
                                    ref.invalidate(brandsProvider);
                                  },
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Đóng'),
          ),
        ],
      ),
    );
    input.dispose();
    if (mounted) setState(() {}); // dropdown đọc lại danh sách + hãng đã chọn
  }

  Future<void> _renameBrand(BrandModel brand) async {
    final input = TextEditingController(text: brand.name);
    final newName = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Đổi tên hãng'),
        content: TextField(controller: input, autofocus: true),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Hủy'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, input.text.trim()),
            child: const Text('Lưu'),
          ),
        ],
      ),
    );
    input.dispose();
    if (newName == null || newName.isEmpty || newName == brand.name) return;
    // Đổi tên lan sang mọi sản phẩm đang mang tên cũ (danh mục/search khớp theo).
    await ref.read(brandRepositoryProvider).rename(brand.id, newName);
    if (_brand.text.trim() == brand.name) _brand.text = newName;
    ref.invalidate(brandsProvider);
    invalidateAdminData(ref);
  }

  Widget _field(
    String label,
    TextEditingController controller, {
    bool isRequired = false,
    bool number = false,
    int maxLines = 1,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: TextFormField(
        controller: controller,
        maxLines: maxLines,
        keyboardType: number ? TextInputType.number : TextInputType.text,
        decoration: InputDecoration(
          label: isRequired ? _requiredLabel(label) : null,
          labelText: isRequired ? null : label,
        ),
        validator: (value) {
          final text = value?.trim() ?? '';
          if (isRequired && text.isEmpty) return 'Bắt buộc';
          if (number && text.isNotEmpty && num.tryParse(text) == null) {
            return 'Sai số';
          }
          return null;
        },
      ),
    );
  }

  // Nhãn có dấu * đỏ cho trường bắt buộc.
  Widget _requiredLabel(String label) => Text.rich(
    TextSpan(
      text: label,
      children: const [
        TextSpan(
          text: ' *',
          style: TextStyle(color: AppColors.error),
        ),
      ],
    ),
  );

  Widget _pairSection(String title, List<_Pair> pairs) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
            const Spacer(),
            TextButton.icon(
              onPressed: () => setState(() => pairs.add(_Pair('', ''))),
              icon: const Icon(Icons.add, size: 18),
              label: const Text('Thêm'),
            ),
          ],
        ),
        for (var i = 0; i < pairs.length; i++)
          Row(
            children: [
              Expanded(child: _field('Khóa', pairs[i].key)),
              const SizedBox(width: 8),
              Expanded(child: _field('Giá trị', pairs[i].value)),
              IconButton(
                onPressed: () => setState(() => pairs.removeAt(i).dispose()),
                icon: const Icon(Icons.close, color: AppColors.error),
              ),
            ],
          ),
      ],
    );
  }

  Widget _specSection() {
    final schema = _categoryId == null ? null : specSchema[_categoryId];
    if (schema == null) {
      // Danh mục chưa có field cứng → nhập tự do.
      return _pairSection('Thông số kỹ thuật', _specs);
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.only(top: 4, bottom: 10),
          child: Text(
            'Thông số kỹ thuật',
            style: TextStyle(fontWeight: FontWeight.w700),
          ),
        ),
        for (final key in schema) _specField(key),
      ],
    );
  }

  Widget _specField(String key) {
    final label = formatSpecLabel(key);
    final options = specEnumOptions[key];
    if (options != null) {
      final ctrl = _specCtrl(key);
      final current = ctrl.text.trim();
      // Giá trị cũ ngoài danh sách chuẩn (dữ liệu import) vẫn chọn được.
      final items = [
        ...options,
        if (current.isNotEmpty && !options.contains(current)) current,
      ];
      return Padding(
        padding: const EdgeInsets.only(bottom: 14),
        child: DropdownButtonFormField<String>(
          initialValue: current.isEmpty ? null : current,
          isExpanded: true,
          decoration: InputDecoration(labelText: label),
          items: [
            for (final o in items)
              DropdownMenuItem(
                value: o,
                child: Text(o, maxLines: 1, overflow: TextOverflow.ellipsis),
              ),
          ],
          onChanged: (v) => ctrl.text = v ?? '',
        ),
      );
    }
    switch (specFieldType(key)) {
      case SpecFieldType.boolean:
        final ctrl = _specCtrl(key);
        // Chuẩn hoá về 'true'/'false' để lưu đúng kiểu bool.
        final on = isTruthySpec(ctrl.text);
        if (ctrl.text != 'true' && ctrl.text != 'false') {
          ctrl.text = on ? 'true' : 'false';
        }
        return SwitchListTile(
          contentPadding: EdgeInsets.zero,
          title: Text(label, style: const TextStyle(fontSize: 14)),
          value: on,
          activeThumbColor: AppColors.adminAccent,
          onChanged: (v) => setState(() => ctrl.text = v ? 'true' : 'false'),
        );
      case SpecFieldType.number:
        return _field(label, _specCtrl(key), number: true);
      case SpecFieldType.text:
        return _field(label, _specCtrl(key));
    }
  }

  TextEditingController _specCtrl(String key) => _specControllers.putIfAbsent(
    key,
    () => TextEditingController(text: _specValues[key] ?? ''),
  );

  Widget _variantSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Text(
              'Phiên bản',
              style: TextStyle(fontWeight: FontWeight.w700),
            ),
            const Spacer(),
            TextButton.icon(
              onPressed: () =>
                  setState(() => _variants.add(_newVariantDraft())),
              icon: const Icon(Icons.add, size: 18),
              label: const Text('Thêm'),
            ),
          ],
        ),
        for (var i = 0; i < _variants.length; i++)
          _VariantCard(
            draft: _variants[i],
            categoryId: _categoryId,
            onRemove: () => setState(() => _variants.removeAt(i).dispose()),
            field: _field,
            pairSection: _pairSection,
          ),
      ],
    );
  }

  // Variant mới lấy sẵn thuộc tính từ thông số sản phẩm đang tạo; user chỉnh lại.
  _VariantDraft _newVariantDraft() {
    final schema = _categoryId == null ? null : variantSchema[_categoryId];
    if (schema == null) return _VariantDraft();
    final vals = _currentSpecValues();
    return _VariantDraft(
      seedAttrs: {
        for (final k in schema)
          if ((vals[k] ?? '').isNotEmpty) k: vals[k]!,
      },
    );
  }

  Future<void> _pickImage({required bool primary}) async {
    final picked = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (picked == null) return;
    setState(() => _saving = true);
    try {
      final url = await Cloudinary.uploadImage(
        File(picked.path),
        folder: 'products',
      );
      setState(() {
        if (primary) {
          _imageUrl.text = url;
        } else {
          _gallery.add(TextEditingController(text: url));
        }
      });
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Upload ảnh thất bại')));
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  void _showImagePreview(String url) {
    if (url.trim().isEmpty) return;
    showDialog<void>(
      context: context,
      builder: (_) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.all(16),
        child: InteractiveViewer(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Image.network(url, fit: BoxFit.contain),
          ),
        ),
      ),
    );
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    final id =
        widget.productId ??
        'p_${DateTime.now().millisecondsSinceEpoch.toString()}';
    // Field cứng ghi cả specs (hiển thị) lẫn compatibility (part-picker).
    final maps = buildSpecMaps(
      _categoryId,
      _currentSpecValues(),
      _originalCompatibility,
    );
    final product = ProductModel(
      id: id,
      name: _name.text.trim(),
      brand: _brand.text.trim(),
      description: _description.text.trim(),
      price: double.parse(_price.text.trim()),
      oldPrice: _oldPrice.text.trim().isEmpty
          ? null
          : double.parse(_oldPrice.text.trim()),
      rating: _rating,
      reviewCount: _reviewCount,
      imageLabel: _imageLabel.text.trim(),
      imageUrl: _imageUrl.text.trim(),
      images: _gallery
          .map((c) => c.text.trim())
          .where((url) => url.isNotEmpty)
          .toList(),
      categoryId: _categoryId!,
      categoryName: _categoryName,
      stock: int.parse(_stock.text.trim()),
      isActive: _active,
      specs: maps.specs,
      variants: _variants.map((v) => v.toVariant(_categoryId)).toList(),
      compatibility: maps.compatibility,
    );
    try {
      await ref.read(adminRepositoryProvider).saveProduct(product);
      invalidateAdminData(ref);
      if (mounted) context.go(AppRoutes.adminProducts);
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Lưu sản phẩm thất bại')));
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  /// Giá trị các field thông số hiện tại: schema → theo key cố định; danh mục
  /// không có schema → từ các cặp key/value tự do.
  Map<String, String> _currentSpecValues() {
    final schema = _categoryId == null ? null : specSchema[_categoryId];
    if (schema == null) return _pairsToStringMap(_specs);
    return {
      for (final key in schema) key: _specControllers[key]?.text.trim() ?? '',
    };
  }

  Map<String, String> _pairsToStringMap(List<_Pair> pairs) => {
    for (final p in pairs)
      if (p.key.text.trim().isNotEmpty) p.key.text.trim(): p.value.text.trim(),
  };

  Widget _error(String message) => Center(
    child: Text(
      message,
      style: const TextStyle(color: AppColors.textSecondary),
    ),
  );
}

class _VariantCard extends StatelessWidget {
  const _VariantCard({
    required this.draft,
    required this.categoryId,
    required this.onRemove,
    required this.field,
    required this.pairSection,
  });

  final _VariantDraft draft;
  final String? categoryId;
  final VoidCallback onRemove;
  final Widget Function(
    String,
    TextEditingController, {
    bool isRequired,
    bool number,
    int maxLines,
  })
  field;
  final Widget Function(String, List<_Pair>) pairSection;

  @override
  Widget build(BuildContext context) {
    final attrSchema = categoryId == null ? null : variantSchema[categoryId];
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border.all(color: AppColors.border),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              // ID tự sinh, ổn định để giữ link card listing — không cho sửa tay.
              Expanded(
                child: Text(
                  'Variant · ${draft.id}',
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
              IconButton(
                onPressed: onRemove,
                icon: const Icon(Icons.delete_outline, color: AppColors.error),
              ),
            ],
          ),
          field('Tên', draft.name, isRequired: true),
          Row(
            children: [
              Expanded(
                child: field(
                  'Giá',
                  draft.price,
                  number: true,
                  isRequired: true,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(child: field('Giá KM', draft.oldPrice, number: true)),
              const SizedBox(width: 8),
              Expanded(
                child: field(
                  'Kho',
                  draft.stock,
                  number: true,
                  isRequired: true,
                ),
              ),
            ],
          ),
          if (attrSchema != null)
            for (final key in attrSchema)
              field(
                formatSpecLabel(key),
                draft.attrCtrl(key),
                number: specFieldType(key) == SpecFieldType.number,
              )
          else
            pairSection('Thuộc tính variant', draft.attributes),
        ],
      ),
    );
  }
}

class _Pair {
  final TextEditingController key;
  final TextEditingController value;

  _Pair(String key, String value)
    : key = TextEditingController(text: key),
      value = TextEditingController(text: value);

  void dispose() {
    key.dispose();
    value.dispose();
  }
}

class _VariantDraft {
  final String id; // tự sinh, ổn định
  final TextEditingController name;
  final TextEditingController price;
  final TextEditingController oldPrice;
  final TextEditingController stock;
  final Map<String, String> _initialAttrs; // giá trị attribute ban đầu
  final Map<String, TextEditingController> _attrCtrls = {};
  final List<_Pair> attributes; // freeform, dùng khi danh mục không có schema

  static int _seq = 0;

  _VariantDraft({Map<String, String>? seedAttrs})
    : id = 'v${DateTime.now().millisecondsSinceEpoch}_${_seq++}',
      name = TextEditingController(),
      price = TextEditingController(),
      oldPrice = TextEditingController(),
      stock = TextEditingController(),
      _initialAttrs = {...?seedAttrs},
      attributes = [];

  _VariantDraft.fromVariant(ProductVariant variant)
    : id = variant.id,
      name = TextEditingController(text: variant.name),
      price = TextEditingController(text: variant.price.toStringAsFixed(0)),
      oldPrice = TextEditingController(
        text: variant.oldPrice?.toStringAsFixed(0) ?? '',
      ),
      stock = TextEditingController(text: '${variant.stock}'),
      _initialAttrs = {
        for (final e in variant.attributes.entries) e.key: '${e.value}',
      },
      attributes = variant.attributes.entries
          .map((e) => _Pair(e.key, '${e.value}'))
          .toList();

  TextEditingController attrCtrl(String key) => _attrCtrls.putIfAbsent(
    key,
    () => TextEditingController(text: _initialAttrs[key] ?? ''),
  );

  ProductVariant toVariant(String? categoryId) {
    final schema = categoryId == null ? null : variantSchema[categoryId];
    final attrs = <String, dynamic>{};
    if (schema != null) {
      // Giữ key cũ ngoài schema (vd label cho selector RAM grouped) khỏi mất.
      _initialAttrs.forEach((k, v) {
        if (!schema.contains(k) && v.trim().isNotEmpty) attrs[k] = v;
      });
      for (final key in schema) {
        final t = _attrCtrls[key]?.text.trim() ?? _initialAttrs[key] ?? '';
        if (t.isNotEmpty) attrs[key] = parseSpecValue(t);
      }
    } else {
      for (final p in attributes) {
        if (p.key.text.trim().isNotEmpty) {
          attrs[p.key.text.trim()] = parseSpecValue(p.value.text.trim());
        }
      }
    }
    return ProductVariant(
      id: id,
      name: name.text.trim(),
      price: double.parse(price.text.trim()),
      oldPrice: oldPrice.text.trim().isEmpty
          ? null
          : double.parse(oldPrice.text.trim()),
      stock: int.parse(stock.text.trim()),
      attributes: attrs,
    );
  }

  void dispose() {
    name.dispose();
    price.dispose();
    oldPrice.dispose();
    stock.dispose();
    for (final c in _attrCtrls.values) {
      c.dispose();
    }
    for (final p in attributes) {
      p.dispose();
    }
  }
}
