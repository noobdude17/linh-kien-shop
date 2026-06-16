import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_dimens.dart';
import '../../../core/widgets/product_card.dart';
import '../../../data/mock_data.dart';
import '../../../routes/app_routes.dart';

class SearchResultsScreen extends StatelessWidget {
  const SearchResultsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: BackButton(onPressed: () => context.go(AppRoutes.search)),
        title: const Text('Kết quả cho "RTX 4070" (8)', style: TextStyle(fontSize: 15)),
      ),
      body: GridView.count(
        crossAxisCount: 2,
        padding: const EdgeInsets.all(AppDimens.screenPadding),
        mainAxisSpacing: AppDimens.gap,
        crossAxisSpacing: AppDimens.gap,
        childAspectRatio: 0.62,
        children: MockData.gpuList
            .map((p) => ProductCard(
                  product: p,
                  onTap: () => context.go('${AppRoutes.detail}/${p.id}'),
                ))
            .toList(),
      ),
    );
  }
}
