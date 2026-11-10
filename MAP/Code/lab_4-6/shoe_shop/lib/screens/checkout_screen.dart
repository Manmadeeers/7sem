import 'package:flutter/material.dart';

import '../models/product.dart';
import '../theme.dart';
import '../widgets/shared.dart';

class CheckoutScreen extends StatelessWidget {
  const CheckoutScreen({
    super.key,
    required this.selection,
  });

  static const routeName = '/checkout';

  final PurchaseSelection selection;

  @override
  Widget build(BuildContext context) {
    final product = selection.product;

    return Scaffold(
      appBar: AppBar(title: const Text('Checkout')),
      body: ListView(
        padding: const EdgeInsets.all(22),
        children: [
          SizedBox(
            height: 200,
            child: ShoeImage(
              image: product.image,
              dark: product.dark,
            ),
          ),
          const SizedBox(height: 20),
          Text(
            product.name,
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 12),
          Text(
            product.description,
            style: const TextStyle(
              color: ShopColors.muted,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: ShopColors.card,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Column(
              children: [
                _SummaryRow(
                  label: 'EU size',
                  value: '${selection.size}',
                ),
                const SizedBox(height: 14),
                const _SummaryRow(
                  label: 'Quantity',
                  value: '1',
                ),
                const Divider(height: 30),
                _SummaryRow(
                  label: 'Total',
                  value: product.formattedPrice,
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            'Demo checkout. No payment will be processed.',
            style: TextStyle(color: ShopColors.muted),
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        top: false,
        minimum: const EdgeInsets.all(22),
        child: SizedBox(
          height: 52,
          child: FilledButton(
            key: const ValueKey('confirm-purchase'),
            onPressed: () => Navigator.of(context).pop<bool>(true),
            child: const Text('Confirm purchase'),
          ),
        ),
      ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  const _SummaryRow({
    required this.label,
    required this.value,
  });

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label),
        Text(
          value,
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
      ],
    );
  }
}