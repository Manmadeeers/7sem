import 'package:flutter/material.dart';

import '../models/product.dart';
import '../theme.dart';
import '../widgets/shared.dart';

class SizeScreen extends StatefulWidget {
  const SizeScreen({
    super.key,
    required this.product,
    this.selectedSize,
  });

  final Product product;
  final int? selectedSize;

  @override
  State<SizeScreen> createState() => _SizeScreenState();
}

class _SizeScreenState extends State<SizeScreen> {
  int? _selectedSize;

  @override
  void initState() {
    super.initState();
    _selectedSize = widget.selectedSize;
  }

  void _confirmSize() {
    final size = _selectedSize;

    if (size != null) {
      Navigator.of(context).pop<int>(size);
    }
  }

  @override
  Widget build(BuildContext context) {
    final product = widget.product;

    return Scaffold(
      appBar: AppBar(title: const Text('Choose size')),
      body: ListView(
        padding: const EdgeInsets.all(22),
        children: [
          SizedBox(
            height: 180,
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
          const SizedBox(height: 8),
          Text(product.formattedPrice),
          const SizedBox(height: 24),
          const Text(
            'Available EU sizes',
            style: TextStyle(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              for (final size in product.sizes)
                ChoiceChip(
                  key: ValueKey('size-$size'),
                  label: Text('$size'),
                  selected: size == _selectedSize,
                  selectedColor: const Color(0xFFDDF3FC),
                  onSelected: (_) {
                    setState(() => _selectedSize = size);
                  },
                ),
            ],
          ),
          const SizedBox(height: 20),
          Text(
            _selectedSize == null
                ? 'Select a size to continue.'
                : 'Your choice: $_selectedSize',
            style: const TextStyle(color: ShopColors.muted),
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        top: false,
        minimum: const EdgeInsets.all(22),
        child: SizedBox(
          height: 52,
          child: FilledButton(
            key: const ValueKey('confirm-size'),
            onPressed: _selectedSize == null ? null : _confirmSize,
            child: const Text('Confirm size'),
          ),
        ),
      ),
    );
  }
}