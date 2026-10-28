import 'package:flutter/material.dart';

import '../models/product.dart';
import '../theme.dart';
import '../widgets/shared.dart';
import 'checkout_screen.dart';
import 'size_screen.dart';

class DetailScreen extends StatefulWidget {
  const DetailScreen({
    super.key,
    required this.product,
  });

  final Product product;

  @override
  State<DetailScreen> createState() => _DetailScreenState();
}

class _DetailScreenState extends State<DetailScreen> {
  final PageController _photoController = PageController();

  int _photoPage = 0;
  int? _selectedSize;

  @override
  void dispose() {
    _photoController.dispose();
    super.dispose();
  }

  void _showPhoto(int index) {
    _photoController.animateToPage(
      index,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  Future<void> _chooseSize(int initialSize) async {
    final result = await Navigator.of(context).push<int>(
      MaterialPageRoute<int>(
        builder: (_) => SizeScreen(
          product: widget.product,
          selectedSize: initialSize,
        ),
      ),
    );

    if (!mounted || result == null) {
      return;
    }

    setState(() => _selectedSize = result);

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text('Selected size: $result'),
        ),
      );
  }

  Future<void> _openCheckout() async {
    final selection = PurchaseSelection(
      product: widget.product,
      size: _selectedSize ?? widget.product.sizes.first,
    );

    final confirmed = await Navigator.of(context).pushNamed<bool>(
      CheckoutScreen.routeName,
      arguments: selection,
    );

    if (!mounted || confirmed != true) {
      return;
    }

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(
            'Purchase confirmed: '
            '${selection.product.name}, size ${selection.size}.',
          ),
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    final product = widget.product;

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
                trailing: HeaderIcon(
                  icon: product.favorite
                      ? Icons.favorite
                      : Icons.favorite_border,
                ),
              ),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.only(bottom: 12),
                  children: [
                    _ProductPhoto(
                      product: product,
                      controller: _photoController,
                      activePage: _photoPage,
                      onPageChanged: (index) {
                        setState(() => _photoPage = index);
                      },
                      onSelectPage: _showPhoto,
                    ),
                    const SizedBox(height: 12),
                    _Thumbnails(
                      product: product,
                      onTap: _showPhoto,
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment:
                          MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Size',
                          style:
                              Theme.of(context).textTheme.titleLarge,
                        ),
                        const Rating(),
                      ],
                    ),
                    const SizedBox(height: 12),
                    _Sizes(
                      sizes: product.sizes,
                      selectedSize: _selectedSize,
                      onTap: _chooseSize,
                    ),
                    const SizedBox(height: 18),
                    Row(
                      mainAxisAlignment:
                          MainAxisAlignment.spaceBetween,
                      children: [
                        Flexible(
                          child: Text(
                            product.name,
                            key: const ValueKey(
                              'detail-product-name',
                            ),
                            style: Theme.of(context)
                                .textTheme
                                .titleLarge,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          product.formattedPrice,
                          key: const ValueKey(
                            'detail-product-price',
                          ),
                          style:
                              Theme.of(context).textTheme.titleLarge,
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    const Row(
                      children: [
                        Expanded(
                          child: _DescriptionTab(
                            'Description',
                            selected: true,
                          ),
                        ),
                        SizedBox(width: 14),
                        Expanded(
                          child: _DescriptionTab('Reviews'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Text.rich(
                      TextSpan(
                        text: '${product.description} ',
                        children: const [
                          TextSpan(
                            text: 'Read More',
                            style: TextStyle(
                              color: ShopColors.orange,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                      style: const TextStyle(
                        fontSize: 12,
                        height: 1.4,
                        color: ShopColors.muted,
                      ),
                    ),
                  ],
                ),
              ),
              _PurchaseBar(onBuy: _openCheckout),
            ],
          ),
        ),
      ),
    );
  }
}

class _ProductPhoto extends StatelessWidget {
  const _ProductPhoto({
    required this.product,
    required this.controller,
    required this.activePage,
    required this.onPageChanged,
    required this.onSelectPage,
  });

  final Product product;
  final PageController controller;
  final int activePage;
  final ValueChanged<int> onPageChanged;
  final ValueChanged<int> onSelectPage;

  static const _angles = <double>[
    0,
    -.15,
    .15,
    -.3,
    .3,
  ];

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
        child: Column(
          children: [
            Expanded(
              child: PageView.builder(
                key: const ValueKey('product-pages'),
                controller: controller,
                itemCount: _angles.length,
                onPageChanged: onPageChanged,
                itemBuilder: (context, index) {
                  return ShoeImage(
                    image: product.image,
                    dark: product.dark,
                    angle: _angles[index],
                  );
                },
              ),
            ),
            const SizedBox(height: 8),
            _PhotoDots(
              count: _angles.length,
              activeIndex: activePage,
              onTap: onSelectPage,
            ),
          ],
        ),
      ),
    );
  }
}

class _PhotoDots extends StatelessWidget {
  const _PhotoDots({
    required this.count,
    required this.activeIndex,
    required this.onTap,
  });

  final int count;
  final int activeIndex;
  final ValueChanged<int> onTap;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(
        count,
        (index) => GestureDetector(
          onTap: () => onTap(index),
          behavior: HitTestBehavior.opaque,
          child: Container(
            width: 6,
            height: 6,
            margin: const EdgeInsets.symmetric(horizontal: 4),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: index == activeIndex
                  ? const Color(0xFFE8F5FA)
                  : const Color(0xFFE1E3E5),
              border: index == activeIndex
                  ? Border.all(color: const Color(0xFFABD8E7))
                  : null,
            ),
          ),
        ),
      ),
    );
  }
}

class _Thumbnails extends StatelessWidget {
  const _Thumbnails({
    required this.product,
    required this.onTap,
  });

  final Product product;
  final ValueChanged<int> onTap;

  @override
  Widget build(BuildContext context) {
    const colors = [
      Color(0xFFFFEFE8),
      Color(0xFFEAF8FC),
      Color(0xFFF4F1E9),
      Color(0xFFF1EBFC),
    ];

    return Row(
      children: [
        for (var index = 0; index < colors.length; index++)
          GestureDetector(
            key: ValueKey('photo-thumbnail-$index'),
            onTap: () => onTap(index),
            child: Container(
              width: 48,
              height: 48,
              margin: const EdgeInsets.only(right: 10),
              padding: const EdgeInsets.all(3),
              decoration: BoxDecoration(
                color: colors[index],
                borderRadius: BorderRadius.circular(8),
              ),
              child: ShoeImage(
                image: product.image,
                dark: product.dark,
                shadow: false,
              ),
            ),
          ),
      ],
    );
  }
}

class _Sizes extends StatelessWidget {
  const _Sizes({
    required this.sizes,
    required this.selectedSize,
    required this.onTap,
  });

  final List<int> sizes;
  final int? selectedSize;
  final ValueChanged<int> onTap;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        for (var index = 0; index < sizes.length; index++) ...[
          if (index > 0) const SizedBox(width: 10),
          Expanded(
            child: Material(
              color: ShopColors.card,
              borderRadius: BorderRadius.circular(9),
              clipBehavior: Clip.antiAlias,
              child: InkWell(
                key: ValueKey('detail-size-${sizes[index]}'),
                onTap: () => onTap(sizes[index]),
                child: Container(
                  height: 44,
                  alignment: Alignment.center,
                  child: Text(
                    '${sizes[index]}',
                    style: TextStyle(
                      color: sizes[index] == selectedSize
                          ? ShopColors.blue
                          : ShopColors.muted,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
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
  const _DescriptionTab(
    this.label, {
    this.selected = false,
  });

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
  const _PurchaseBar({required this.onBuy});

  final VoidCallback onBuy;

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
            child: const Icon(
              Icons.add_shopping_cart_rounded,
              size: 28,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Material(
              color: ShopColors.ink,
              borderRadius: BorderRadius.circular(12),
              clipBehavior: Clip.antiAlias,
              child: InkWell(
                key: const ValueKey('buy-now'),
                onTap: onBuy,
                child: Container(
                  height: 54,
                  alignment: Alignment.center,
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
            ),
          ),
        ],
      ),
    );
  }
}