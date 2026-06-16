import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class CartScreen extends StatelessWidget {
  const CartScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Giỏ hàng')),
      body: const Center(child: Text('TODO: Cart')),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.all(16),
        child: ElevatedButton(
          onPressed: () => context.go('/checkout'),
          child: const Text('Tiến hành đặt hàng'),
        ),
      ),
    );
  }
}
