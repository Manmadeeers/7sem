import 'package:flutter/material.dart';

import '../data/shop_scope.dart';
import '../models/product.dart';
import '../models/shop_user.dart';
import '../theme.dart';
import '../widgets/shared.dart';
import 'detail_screen.dart';
import 'favorites_screen.dart';
import 'manage_products_screen.dart';
import 'storage_screen.dart';

class CatalogScreen extends StatelessWidget {
  const CatalogScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final store = ShopScope.of(context);
    final products = store.products;

    void openDetails(Product product) {
      Navigator.of(context).push<void>(
        MaterialPageRoute<void>(builder: (_) => DetailScreen(product: product)),
      );
    }

    return Scaffold(
      extendBody: true,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        leadingWidth: 64,
        leading: const Padding(
          padding: EdgeInsets.only(left: 22, top: 8, bottom: 8),
          child: HeaderIcon(icon: Icons.grid_view_rounded),
        ),
        title: const Text('Explore'),
        centerTitle: true,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 22, top: 8, bottom: 8),
            child: _UserMenu(
              users: store.users,
              selected: store.currentUser,
              onSelected: store.selectUser,
            ),
          ),
        ],
      ),
      body: SafeArea(
        top: false,
        bottom: false,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(22, 0, 22, 100),
          children: [
            if (products.isNotEmpty)
              _PromoBanner(
                onTap: () => openDetails(
                  products.firstWhere(
                    (product) => product.id == 'lebron',
                    orElse: () => products.first,
                  ),
                ),
              ),
            const SizedBox(height: 15),
            const PageDots(),
            const SizedBox(height: 22),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Categories',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const Text(
                  'View all',
                  style: TextStyle(fontSize: 12, color: ShopColors.muted),
                ),
              ],
            ),
            const SizedBox(height: 14),
            const _Categories(),
            const SizedBox(height: 24),
            LayoutBuilder(
              builder: (context, constraints) {
                final cardWidth = (constraints.maxWidth - 14) / 2;

                return GridView(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  padding: EdgeInsets.zero,
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 14,
                    mainAxisSpacing: 14,
                    mainAxisExtent: cardWidth * .95 + 72,
                  ),
                  children: [
                    for (final product in products)
                      _ProductCard(
                        key: ValueKey('product-${product.id}'),
                        product: product,
                        onTap: () => openDetails(product),
                        favorite: store.isFavorite(product.id),
                        onFavorite: () => store.toggleFavorite(product.id),
                      ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
      bottomNavigationBar: SafeArea(
        top: false,
        minimum: const EdgeInsets.fromLTRB(22, 0, 22, 12),
        child: _BottomBar(currentUser: store.currentUser),
      ),
    );
  }
}

class _UserMenu extends StatelessWidget {
  const _UserMenu({
    required this.users,
    required this.selected,
    required this.onSelected,
  });

  final List<ShopUser> users;
  final ShopUser selected;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<String>(
      key: const ValueKey('user-menu'),
      tooltip: 'Switch user',
      onSelected: onSelected,
      itemBuilder: (context) => [
        for (final user in users)
          PopupMenuItem<String>(
            value: user.id,
            child: Row(
              children: [
                Icon(
                  user.id == selected.id
                      ? Icons.radio_button_checked
                      : Icons.radio_button_off,
                  size: 18,
                ),
                const SizedBox(width: 10),
                Expanded(child: Text(user.name)),
                Text(
                  user.role.label,
                  style: const TextStyle(fontSize: 11, color: ShopColors.muted),
                ),
              ],
            ),
          ),
      ],
      child: Container(
        width: 42,
        height: 42,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: const Color(0xFFECEEEF), width: 1.5),
        ),
        alignment: Alignment.center,
        child: Text(
          selected.name.substring(0, 1).toUpperCase(),
          style: const TextStyle(fontWeight: FontWeight.w800),
        ),
      ),
    );
  }
}

class _PromoBanner extends StatelessWidget {
  const _PromoBanner({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;

        return SizedBox(
          height: width * .49,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Positioned(
                left: 0,
                right: 0,
                top: width * .045,
                height: width * .372,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: const Color(0xFF0F1626),
                    borderRadius: BorderRadius.circular(width * .06),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x12000000),
                        blurRadius: 6,
                        offset: Offset(0, 3),
                      ),
                    ],
                  ),
                ),
              ),
              Positioned(
                right: width * .034,
                bottom: width * .017,
                child: Container(
                  width: width * .32,
                  height: 4,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(100),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x30000000),
                        blurRadius: 8,
                        spreadRadius: 1,
                      ),
                    ],
                  ),
                ),
              ),
              Positioned(
                right: width * .024,
                top: 0,
                width: width * .46,
                height: width * .46,
                child: IgnorePointer(
                  child: Image.asset(
                    'assets/images/promo_sneakers.png',
                    fit: BoxFit.contain,
                    semanticLabel: 'Two floating white sneakers',
                  ),
                ),
              ),
              Positioned(
                left: width * .072,
                top: width * .12,
                width: width * .51,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Flat 50% discount on\nyour first order.',
                      style: TextStyle(
                        color: const Color(0xFFD6DAE1),
                        fontSize: width * .037,
                        height: 1.35,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    SizedBox(height: width * .05),
                    SizedBox(
                      width: width * .27,
                      height: width * .079,
                      child: FilledButton(
                        key: const ValueKey('promo-details'),
                        onPressed: onTap,
                        style: FilledButton.styleFrom(
                          backgroundColor: ShopColors.orange,
                          foregroundColor: Colors.white,
                          padding: EdgeInsets.zero,
                          minimumSize: Size.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          shape: const StadiumBorder(),
                        ),
                        child: Text(
                          'Buy Now',
                          style: TextStyle(
                            fontSize: width * .035,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _Categories extends StatelessWidget {
  const _Categories();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 92,
          height: 42,
          padding: const EdgeInsets.symmetric(horizontal: 7),
          decoration: BoxDecoration(
            color: ShopColors.blue,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(3),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(5),
                ),
                child: Image.asset(
                  'assets/icons/shoes.png',
                  width: 23,
                  height: 23,
                ),
              ),
              const SizedBox(width: 6),
              const Expanded(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    'Shoes',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        for (final category in ['heels', 'sneakers', 'sandals', 'boots']) ...[
          const SizedBox(width: 7),
          Expanded(
            child: Container(
              height: 42,
              padding: const EdgeInsets.all(7),
              decoration: BoxDecoration(
                color: ShopColors.card,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Image.asset(
                'assets/icons/$category.png',
                fit: BoxFit.contain,
              ),
            ),
          ),
        ],
      ],
    );
  }
}

class _ProductCard extends StatelessWidget {
  const _ProductCard({
    super.key,
    required this.product,
    required this.onTap,
    required this.favorite,
    required this.onFavorite,
  });

  final Product product;
  final VoidCallback onTap;
  final bool favorite;
  final VoidCallback onFavorite;

  @override
  Widget build(BuildContext context) {
    final cardName = product.id == 'lebron' ? 'Sneakers ft' : product.name;

    return Material(
      color: ShopColors.card,
      borderRadius: BorderRadius.circular(16),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Column(
          children: [
            Expanded(
              child: Stack(
                children: [
                  Positioned.fill(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(8, 20, 8, 0),
                      child: ShoeImage(
                        image: product.image,
                        dark: product.dark,
                      ),
                    ),
                  ),
                  Positioned(
                    top: 11,
                    right: 11,
                    child: IconButton(
                      key: ValueKey('favorite-${product.id}'),
                      tooltip: favorite
                          ? 'Remove from favorites'
                          : 'Add to favorites',
                      visualDensity: VisualDensity.compact,
                      onPressed: onFavorite,
                      icon: Icon(
                        favorite ? Icons.favorite : Icons.favorite_border,
                        color: favorite ? ShopColors.orange : ShopColors.ink,
                        size: 21,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    cardName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        product.formattedPrice,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const Rating(small: true),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BottomBar extends StatelessWidget {
  const _BottomBar({required this.currentUser});

  final ShopUser currentUser;

  @override
  Widget build(BuildContext context) {
    const icons = [
      Icons.home_rounded,
      Icons.favorite_outline_rounded,
      Icons.inventory_2_outlined,
      Icons.security_outlined,
    ];

    void openPage(Widget page) {
      Navigator.of(
        context,
      ).push<void>(MaterialPageRoute<void>(builder: (_) => page));
    }

    return Container(
      height: 61,
      decoration: BoxDecoration(
        color: ShopColors.ink,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: List.generate(
          icons.length,
          (index) => Expanded(
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: switch (index) {
                1 => () => openPage(const FavoritesScreen()),
                2 when currentUser.role.canManageProducts => () => openPage(
                  const ManageProductsScreen(),
                ),
                3 => () => openPage(const StorageScreen()),
                _ => null,
              },
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(
                    width: 35,
                    height: 29,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        Icon(
                          icons[index],
                          size: 25,
                          color: index == 0
                              ? Colors.white
                              : const Color(0xFF8996A4),
                        ),
                        if (index == 2 && !currentUser.role.canManageProducts)
                          const Positioned(
                            right: 0,
                            top: 0,
                            child: Icon(
                              Icons.lock,
                              size: 12,
                              color: ShopColors.orange,
                            ),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 4),
                  Container(
                    width: 4,
                    height: 4,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: index == 0 ? ShopColors.blue : Colors.transparent,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
