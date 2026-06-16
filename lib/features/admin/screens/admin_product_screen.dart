import 'package:flutter/material.dart';

class AdminProductScreen extends StatelessWidget {
  const AdminProductScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Quản lý sản phẩm')),
      body: const Center(child: Text('TODO: Admin Product CRUD')),
      floatingActionButton: FloatingActionButton(
        onPressed: () {},
        child: const Icon(Icons.add),
      ),
    );
  }
}
