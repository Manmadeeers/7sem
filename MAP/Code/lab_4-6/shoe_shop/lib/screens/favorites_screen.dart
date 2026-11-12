import 'package:flutter/material.dart';

import '../data/shop_scope.dart';
import '../models/product.dart';
import '../theme.dart';
import '../widgets/shared.dart';
import 'detail_screen.dart';

class FavoritesScreen extends StatelessWidget {
  const FavoritesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final store = ShopScope.of(context);
    final favorites = store.products
        .where((product) => store.isFavorite(product.id))
        .toList();

    return Scaffold(
      appBar: AppBar(title: Text('${store.currentUser.name} · Favorites')),
      body: favorites.isEmpty
          ? const Center(
              child: Padding(
                padding: EdgeInsets.all(32),
                child: Text(
                  'No favorite products yet. Tap the heart in the catalog.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: ShopColors.muted),
                ),
              ),
            )
          : ListView.separated(
              padding: const EdgeInsets.all(18),
              itemCount: favorites.length,
              separatorBuilder: (_, _) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final product = favorites[index];
                return _FavoriteTile(
                  product: product,
                  onOpen: () => Navigator.of(context).push<void>(
                    MaterialPageRoute<void>(
                      builder: (_) => DetailScreen(product: product),
                    ),
                  ),
                  onRemove: () => store.toggleFavorite(product.id),
                );
              },
            ),
    );
  }
}

class _FavoriteTile extends StatelessWidget {
  const _FavoriteTile({
    required this.product,
    required this.onOpen,
    required this.onRemove,
  });

  final Product product;
  final VoidCallback onOpen;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: ShopColors.card,
      borderRadius: BorderRadius.circular(14),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onOpen,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              SizedBox(
                width: 82,
                height: 72,
                child: ShoeImage(image: product.image, dark: product.dark),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      product.name,
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 5),
                    Text(product.formattedPrice),
                    const SizedBox(height: 4),
                    Text(
                      product.location,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 12,
                        color: ShopColors.muted,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                key: ValueKey('remove-favorite-${product.id}'),
                tooltip: 'Remove from favorites',
                onPressed: onRemove,
                icon: const Icon(Icons.favorite, color: ShopColors.orange),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
