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
import '../../../data/models/product_model.dart';
import '../../../data/models/product_variant.dart';
import '../../../routes/app_routes.dart';
import '../../product/providers/product_providers.dart';
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
  final _specs = <_Pair>[];
  final _compatibility = <_Pair>[];
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
    for (final p in [..._specs, ..._compatibility]) {
      p.dispose();
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
    _compatibility.addAll(
      p.compatibility.entries.map((e) => _Pair(e.key, '${e.value}')),
    );
    _gallery.addAll(p.images.map((url) => TextEditingController(text: url)));
    _variants.addAll(p.variants.map(_VariantDraft.fromVariant));
  }

  Widget _form(List<CategoryModel> categories) {
    return Form(
      key: _formKey,
      child: ListView(
        padding: const EdgeInsets.all(18),
        children: [
          _imageSection(),
          const SizedBox(height: 20),
          _field('Tên sản phẩm', _name, isRequired: true),
          _field('Thương hiệu', _brand),
          DropdownButtonFormField<String>(
            initialValue: categories.any((c) => c.id == _categoryId)
                ? _categoryId
                : null,
            decoration: const InputDecoration(labelText: 'Danh mục'),
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
          Row(
            children: [
              Expanded(
                child: _field('Giá', _price, number: true, isRequired: true),
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
          _field('Mô tả', _description, maxLines: 3),
          _field('Nhãn ảnh fallback', _imageLabel),
          _pairSection('Thông số kỹ thuật', _specs),
          _pairSection('Compatibility', _compatibility),
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
              child: ImagePlaceholder(
                label: _imageLabel.text.isEmpty ? 'IMG' : _imageLabel.text,
                imageUrl: _imageUrl.text,
                height: 88,
                radius: 8,
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
        decoration: InputDecoration(labelText: label),
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
              onPressed: () => setState(() => _variants.add(_VariantDraft())),
              icon: const Icon(Icons.add, size: 18),
              label: const Text('Thêm'),
            ),
          ],
        ),
        for (var i = 0; i < _variants.length; i++)
          _VariantCard(
            draft: _variants[i],
            onRemove: () => setState(() => _variants.removeAt(i).dispose()),
            field: _field,
            pairSection: _pairSection,
          ),
      ],
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

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    final id =
        widget.productId ??
        'p_${DateTime.now().millisecondsSinceEpoch.toString()}';
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
      specs: _pairsToStringMap(_specs),
      variants: _variants.map((v) => v.toVariant()).toList(),
      compatibility: _pairsToDynamicMap(_compatibility),
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

  Map<String, String> _pairsToStringMap(List<_Pair> pairs) => {
    for (final p in pairs)
      if (p.key.text.trim().isNotEmpty) p.key.text.trim(): p.value.text.trim(),
  };

  Map<String, dynamic> _pairsToDynamicMap(List<_Pair> pairs) => {
    for (final p in pairs)
      if (p.key.text.trim().isNotEmpty)
        p.key.text.trim(): _parseDynamic(p.value.text.trim()),
  };

  dynamic _parseDynamic(String value) {
    final n = num.tryParse(value);
    if (n != null) return n;
    if (value.toLowerCase() == 'true') return true;
    if (value.toLowerCase() == 'false') return false;
    return value;
  }

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
    required this.onRemove,
    required this.field,
    required this.pairSection,
  });

  final _VariantDraft draft;
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
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border.all(color: AppColors.border),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        children: [
          Row(
            children: [
              const Text(
                'Variant',
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
              const Spacer(),
              IconButton(
                onPressed: onRemove,
                icon: const Icon(Icons.delete_outline, color: AppColors.error),
              ),
            ],
          ),
          field('ID', draft.id, isRequired: true),
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
  final TextEditingController id;
  final TextEditingController name;
  final TextEditingController price;
  final TextEditingController oldPrice;
  final TextEditingController stock;
  final List<_Pair> attributes;

  _VariantDraft()
    : id = TextEditingController(),
      name = TextEditingController(),
      price = TextEditingController(),
      oldPrice = TextEditingController(),
      stock = TextEditingController(),
      attributes = [];

  _VariantDraft.fromVariant(ProductVariant variant)
    : id = TextEditingController(text: variant.id),
      name = TextEditingController(text: variant.name),
      price = TextEditingController(text: variant.price.toStringAsFixed(0)),
      oldPrice = TextEditingController(
        text: variant.oldPrice?.toStringAsFixed(0) ?? '',
      ),
      stock = TextEditingController(text: '${variant.stock}'),
      attributes = variant.attributes.entries
          .map((e) => _Pair(e.key, '${e.value}'))
          .toList();

  ProductVariant toVariant() => ProductVariant(
    id: id.text.trim(),
    name: name.text.trim(),
    price: double.parse(price.text.trim()),
    oldPrice: oldPrice.text.trim().isEmpty
        ? null
        : double.parse(oldPrice.text.trim()),
    stock: int.parse(stock.text.trim()),
    attributes: {
      for (final p in attributes)
        if (p.key.text.trim().isNotEmpty)
          p.key.text.trim(): _parseDynamic(p.value.text.trim()),
    },
  );

  dynamic _parseDynamic(String value) {
    final n = num.tryParse(value);
    if (n != null) return n;
    if (value.toLowerCase() == 'true') return true;
    if (value.toLowerCase() == 'false') return false;
    return value;
  }

  void dispose() {
    id.dispose();
    name.dispose();
    price.dispose();
    oldPrice.dispose();
    stock.dispose();
    for (final p in attributes) {
      p.dispose();
    }
  }
}
