import 'models/product_model.dart';
import 'models/product_variant.dart';

const productListingVariantSeparator = '__card__';

String realProductId(String id) {
  final marker = id.indexOf(productListingVariantSeparator);
  return marker < 0 ? id : id.substring(0, marker);
}

List<ProductModel> expandProductsForListing(Iterable<ProductModel> products) {
  return products.expand(expandProductForListing).toList();
}

List<ProductModel> expandProductForListing(ProductModel product) {
  if (product.variants.isEmpty) {
    return [formatProductForListing(product)];
  }

  if (product.categoryId == 'ram' || product.categoryId == 'storage') {
    return product.variants.map((variant) {
      return _variantCard(product, variant);
    }).toList();
  }

  return [formatProductForListing(product)];
}

ProductModel formatProductForListing(ProductModel product) {
  if (product.categoryId == 'gpu') {
    return product.copyWith(name: _gpuName(product));
  }
  return product;
}

ProductModel formatProductForRouteId(ProductModel product, String routeId) {
  final expanded = expandProductForListing(product);
  for (final item in expanded) {
    if (item.id == routeId) return item;
  }
  return formatProductForListing(product);
}

ProductModel _variantCard(ProductModel product, ProductVariant variant) {
  final mergedCompatibility = {...product.compatibility, ...variant.attributes};
  return product.copyWith(
    id: '${product.id}$productListingVariantSeparator${variant.id}',
    name: switch (product.categoryId) {
      'ram' => _ramVariantName(product, variant),
      'storage' => _storageVariantName(product, variant),
      _ => product.name,
    },
    price: variant.price,
    oldPrice: variant.oldPrice,
    stock: variant.stock,
    compatibility: mergedCompatibility,
  );
}

String _ramVariantName(ProductModel product, ProductVariant variant) {
  final attrs = variant.attributes;
  final series = _ramSeries(product);
  final capacity = _string(attrs['ramCapacityLabel']).isNotEmpty
      ? _string(attrs['ramCapacityLabel'])
      : _ramCapacityLabel(attrs);
  final speed = _string(attrs['ramSpeedLabel']).isNotEmpty
      ? _string(attrs['ramSpeedLabel'])
      : _ramSpeedLabel(product, attrs);
  return [
    product.brand,
    series,
    capacity,
    speed,
  ].where((part) => part.trim().isNotEmpty).join(' ');
}

String _storageVariantName(ProductModel product, ProductVariant variant) {
  final attrs = variant.attributes;
  final data = {...product.compatibility, ...product.specs};
  final type = _string(data['storageType']).isNotEmpty
      ? _string(data['storageType'])
      : 'SSD';
  final interface = _storageInterfaceName(_string(data['storageInterface']));
  final read =
      _number(attrs['storageReadSpeedMbps']) ??
      _firstNumber(data['storageReadSpeedRangeMbps']);
  final write =
      _number(attrs['storageWriteSpeedMbps']) ??
      _firstNumber(data['storageWriteSpeedRangeMbps']);
  final speed = read == null || write == null
      ? ''
      : '(R ${_formatNumber(read)}/W ${_formatNumber(write)})';
  return [
    'Ổ cứng',
    type,
    product.name,
    interface,
    speed,
    _storageCapacity(attrs['storageCapacityGb']),
  ].where((part) => part.trim().isNotEmpty).join(' ');
}

String _gpuName(ProductModel product) {
  final data = {...product.compatibility, ...product.specs};
  var chipset = _string(
    data['gpuChipset'],
  ).replaceFirst(RegExp(r'^GeForce\s+', caseSensitive: false), 'GeForce ');
  if (RegExp(r'^RTX\b', caseSensitive: false).hasMatch(chipset)) {
    chipset = 'GeForce $chipset';
  }
  final vram = _number(data['gpuVramGb']);
  final suffixes = <String>[];
  if (vram != null) suffixes.add('${_formatNumber(vram)}GB');
  final hasOc = RegExp(r'\bOC\b', caseSensitive: false).hasMatch(product.name);
  if (hasOc) suffixes.add('OC');

  final nameWithoutBrand = product.name
      .replaceFirst(
        RegExp('^${RegExp.escape(product.brand)}\\s+', caseSensitive: false),
        '',
      )
      .trim();
  final model = nameWithoutBrand
      .replaceAll(RegExp(r'\bGeForce\b', caseSensitive: false), '')
      .replaceAll(
        RegExp(r'\bRTX\s*\d{4}\s*(?:Ti|SUPER)?\b', caseSensitive: false),
        '',
      )
      .replaceAll(RegExp(r'\bRadeon\b', caseSensitive: false), '')
      .replaceAll(
        RegExp(r'\bRX\s*\d{4}\s*(?:XT|XTX)?\b', caseSensitive: false),
        '',
      )
      .replaceAll(RegExp(r'\bOC\b', caseSensitive: false), '')
      .replaceAll(RegExp(r'\s+'), ' ')
      .trim();

  return [
    'Card màn hình',
    product.brand,
    if (chipset.isNotEmpty) chipset else nameWithoutBrand,
    model,
    ...suffixes,
  ].where((part) => part.trim().isNotEmpty).join(' ');
}

String _ramSeries(ProductModel product) {
  var name = product.name
      .replaceFirst(
        RegExp('^${RegExp.escape(product.brand)}\\s+', caseSensitive: false),
        '',
      )
      .replaceFirst(RegExp(r'^\bCORSAIR\b\s+', caseSensitive: false), '')
      .trim();
  name = name.split(RegExp(r'\b\d+GB\b', caseSensitive: false)).first.trim();
  return name;
}

String _ramCapacityLabel(Map<String, dynamic> attrs) {
  final capacity = _number(attrs['ramCapacityGb']);
  final modules = _number(attrs['ramModuleCount']);
  if (capacity == null) return '';
  if (modules == null || modules <= 1) return '${_formatNumber(capacity)}GB';
  final perModule = capacity / modules;
  return '${_formatNumber(capacity)}GB (${_formatNumber(modules)} x ${_formatNumber(perModule)}GB)';
}

String _ramSpeedLabel(ProductModel product, Map<String, dynamic> attrs) {
  final type = _string(attrs['ramMemoryType']).isNotEmpty
      ? _string(attrs['ramMemoryType'])
      : _string(product.compatibility['ramMemoryType']);
  final speed = _number(attrs['ramSpeedMhz']);
  if (type.isEmpty || speed == null) return '';
  final pcPrefix = type.toUpperCase() == 'DDR5' ? 'PC5' : 'PC4';
  return '$type ${_formatNumber(speed)} ($pcPrefix ${_formatNumber(speed * 8)})';
}

String _storageInterfaceName(String value) {
  if (value.isEmpty) return '';
  return value
      .replaceAll(RegExp(r'PCIe', caseSensitive: false), 'PCIE Gen')
      .replaceAll(RegExp(r'\.0'), '.0')
      .replaceAll('x4', 'X4');
}

String _storageCapacity(Object? value) {
  final gb = _number(value);
  if (gb == null) return _string(value);
  if (gb >= 1000) return '${_formatNumber(gb / 1000)}TB';
  return '${_formatNumber(gb)}GB';
}

String _string(Object? value) => value?.toString().trim() ?? '';

num? _number(Object? value) {
  if (value is num) return value;
  return num.tryParse(_string(value).replaceAll(RegExp(r'[^0-9.]'), ''));
}

num? _firstNumber(Object? value) {
  final match = RegExp(r'\d+(?:\.\d+)?').firstMatch(_string(value));
  return match == null ? null : num.tryParse(match.group(0)!);
}

String _formatNumber(num value) {
  return value % 1 == 0 ? value.toInt().toString() : value.toStringAsFixed(1);
}
