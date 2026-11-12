import 'package:flutter/material.dart';

import '../data/shop_scope.dart';
import '../models/product.dart';
import '../theme.dart';
import '../widgets/shared.dart';
import 'detail_screen.dart';
import 'product_form_screen.dart';

class ManageProductsScreen extends StatelessWidget {
  const ManageProductsScreen({super.key});

  Future<void> _delete(BuildContext context, Product product) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete product?'),
        content: Text('${product.name} will also be removed from favorites.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed == true && context.mounted) {
      await ShopScope.of(context).deleteProduct(product.id);
    }
  }

  @override
  Widget build(BuildContext context) {
    final store = ShopScope.of(context);
    if (!store.currentUser.role.canManageProducts) {
      return const Scaffold(
        body: Center(child: Text('Manager or administrator role required.')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage products'),
        actions: [
          Center(
            child: Padding(
              padding: const EdgeInsets.only(right: 16),
              child: Text(
                store.currentUser.role.label,
                style: const TextStyle(fontSize: 12, color: ShopColors.muted),
              ),
            ),
          ),
        ],
      ),
      body: ListView.separated(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 96),
        itemCount: store.products.length,
        separatorBuilder: (_, _) => const SizedBox(height: 10),
        itemBuilder: (context, index) {
          final product = store.products[index];
          return Card(
            margin: EdgeInsets.zero,
            elevation: 0,
            color: ShopColors.card,
            child: ListTile(
              key: ValueKey('manage-${product.id}'),
              onTap: () => Navigator.of(context).push<void>(
                MaterialPageRoute<void>(
                  builder: (_) => DetailScreen(product: product),
                ),
              ),
              leading: SizedBox(
                width: 58,
                child: ShoeImage(image: product.image, dark: product.dark),
              ),
              title: Text(product.name),
              subtitle: Text('${product.formattedPrice} · ${product.location}'),
              trailing: PopupMenuButton<String>(
                onSelected: (action) {
                  if (action == 'edit') {
                    Navigator.of(context).push<void>(
                      MaterialPageRoute<void>(
                        builder: (_) => ProductFormScreen(product: product),
                      ),
                    );
                  } else {
                    _delete(context, product);
                  }
                },
                itemBuilder: (_) => const [
                  PopupMenuItem(value: 'edit', child: Text('Edit')),
                  PopupMenuItem(value: 'delete', child: Text('Delete')),
                ],
              ),
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        key: const ValueKey('add-product'),
        onPressed: () => Navigator.of(context).push<void>(
          MaterialPageRoute<void>(builder: (_) => const ProductFormScreen()),
        ),
        icon: const Icon(Icons.add),
        label: const Text('Add product'),
      ),
    );
  }
}
