import 'package:flutter/material.dart';

class ProductListScreen extends StatelessWidget {
  final String? categoryId;
  const ProductListScreen({super.key, this.categoryId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(categoryId != null ? 'Danh mục' : 'Tất cả sản phẩm')),
      body: const Center(child: Text('TODO: Product List')),
    );
  }
}
