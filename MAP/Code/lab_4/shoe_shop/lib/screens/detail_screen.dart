import 'package:flutter/material.dart';

import '../theme.dart';
import '../widgets/shared.dart';

class DetailScreen extends StatelessWidget {
  const DetailScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 22),
          child: Column(
            children: [
              ShopHeader(
                title: 'Details',
                leading: HeaderIcon(
                  key: const ValueKey('detail-back'),
                  icon: Icons.chevron_left_rounded,
                  onTap: () => Navigator.of(context).pop(),
                ),
                trailing: const HeaderIcon(icon: Icons.favorite),
              ),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.only(bottom: 12),
                  children: [
                    const _ProductPhoto(),
                    const SizedBox(height: 12),
                    const _Thumbnails(),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Size',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        const Rating(),
                      ],
                    ),
                    const SizedBox(height: 12),
                    const _Sizes(),
                    const SizedBox(height: 18),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Nike Lebron',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        Text(
                          '130\$',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    const Row(
                      children: [
                        Expanded(
                          child: _DescriptionTab('Description', selected: true),
                        ),
                        SizedBox(width: 14),
                        Expanded(child: _DescriptionTab('Reviews')),
                      ],
                    ),
                    const SizedBox(height: 16),
                    const Text.rich(
                      TextSpan(
                        text:
                            'Created for the hardwood but taken to the streets, '
                            'the sneakers fit even better. helps bring the comfort luxury..... ',
                        children: [
                          TextSpan(
                            text: 'Read More',
                            style: TextStyle(
                              color: ShopColors.orange,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                      style: TextStyle(
                        fontSize: 12,
                        height: 1.4,
                        color: ShopColors.muted,
                      ),
                    ),
                  ],
                ),
              ),
              const _PurchaseBar(),
            ],
          ),
        ),
      ),
    );
  }
}

class _ProductPhoto extends StatelessWidget {
  const _ProductPhoto();

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 1.6,
      child: Container(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 14),
        decoration: BoxDecoration(
          color: ShopColors.card,
          borderRadius: BorderRadius.circular(20),
        ),
        child: const Column(
          children: [
            Expanded(child: ShoeImage(image: 'grey_sneakers')),
            SizedBox(height: 8),
            PageDots(count: 5),
          ],
        ),
      ),
    );
  }
}

class _Thumbnails extends StatelessWidget {
  const _Thumbnails();

  @override
  Widget build(BuildContext context) {
    const colors = [
      Color(0xFFFFEFE8),
      Color(0xFFEAF8FC),
      Color(0xFFF4F1E9),
      Color(0xFFF1EBFC),
    ];

    return Row(
      children: colors
          .map(
            (color) => Container(
              width: 48,
              height: 48,
              margin: const EdgeInsets.only(right: 10),
              padding: const EdgeInsets.all(3),
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const ShoeImage(image: 'grey_sneakers', shadow: false),
            ),
          )
          .toList(),
    );
  }
}

class _Sizes extends StatelessWidget {
  const _Sizes();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        for (var size = 37; size <= 41; size++) ...[
          if (size > 37) const SizedBox(width: 10),
          Expanded(
            child: Container(
              height: 44,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: ShopColors.card,
                borderRadius: BorderRadius.circular(9),
              ),
              child: Text(
                '$size',
                style: const TextStyle(
                  color: ShopColors.muted,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }
}

class _DescriptionTab extends StatelessWidget {
  const _DescriptionTab(this.label, {this.selected = false});

  final String label;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 42,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: selected ? ShopColors.blue : ShopColors.card,
        borderRadius: BorderRadius.circular(7),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: selected ? Colors.white : ShopColors.ink,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _PurchaseBar extends StatelessWidget {
  const _PurchaseBar();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 8, bottom: 12),
      child: Row(
        children: [
          Container(
            width: 54,
            height: 54,
            decoration: BoxDecoration(
              color: const Color(0xFFECEDEE),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.add_shopping_cart_rounded, size: 28),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Container(
              height: 54,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: ShopColors.ink,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Text(
                'Buy Now',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
