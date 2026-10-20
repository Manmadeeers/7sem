import 'package:flutter/material.dart';

import '../theme.dart';
import '../widgets/shared.dart';
import 'detail_screen.dart';

class CatalogScreen extends StatelessWidget {
  const CatalogScreen({super.key});

  @override
  Widget build(BuildContext context) {
    void openDetails() {
      Navigator.of(
        context,
      ).push(MaterialPageRoute<void>(builder: (_) => const DetailScreen()));
    }

    return Scaffold(
      extendBody: true,
      body: SafeArea(
        bottom: false,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(22, 0, 22, 100),
          children: [
            const ShopHeader(
              title: 'Explore',
              leading: HeaderIcon(icon: Icons.grid_view_rounded),
              trailing: HeaderIcon(icon: Icons.search_rounded),
            ),
            _PromoBanner(onTap: openDetails),
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
                    const _ProductCard(
                      name: 'Nike Shoe',
                      image: 'teal_sneakers',
                    ),
                    _ProductCard(
                      key: const ValueKey('lebron-card'),
                      name: 'Sneakers ft',
                      image: 'grey_sneakers',
                      favorite: true,
                      onTap: openDetails,
                    ),
                    const _ProductCard(name: 'Classic Boots', image: 'boots'),
                    const _ProductCard(
                      name: 'Black Sneakers',
                      image: 'teal_sneakers',
                      dark: true,
                    ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
      bottomNavigationBar: const SafeArea(
        top: false,
        minimum: EdgeInsets.fromLTRB(22, 0, 22, 12),
        child: _BottomBar(),
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
              const Text(
                'Shoes',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
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
    required this.name,
    required this.image,
    this.favorite = false,
    this.dark = false,
    this.onTap,
  });

  final String name;
  final String image;
  final bool favorite;
  final bool dark;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
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
                      child: ShoeImage(image: image, dark: dark),
                    ),
                  ),
                  Positioned(
                    top: 11,
                    right: 11,
                    child: Icon(
                      favorite ? Icons.favorite : Icons.favorite_border,
                      size: 21,
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
                    name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 5),
                  const Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '85\$',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      Rating(small: true),
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
  const _BottomBar();

  @override
  Widget build(BuildContext context) {
    const icons = [
      Icons.home_rounded,
      Icons.shopping_bag_outlined,
      Icons.shopping_cart_outlined,
      Icons.person_outline_rounded,
    ];

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
                      if (index == 2)
                        const Positioned(
                          right: 0,
                          top: 0,
                          child: CircleAvatar(
                            radius: 6,
                            backgroundColor: ShopColors.blue,
                            child: Text(
                              '0',
                              style: TextStyle(
                                fontSize: 8,
                                color: Colors.white,
                              ),
                            ),
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
    );
  }
}
