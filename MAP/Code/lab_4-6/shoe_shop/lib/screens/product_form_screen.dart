import 'package:flutter/material.dart';

import '../data/shop_scope.dart';
import '../models/product.dart';

class ProductFormScreen extends StatefulWidget {
  const ProductFormScreen({super.key, this.product});

  final Product? product;

  @override
  State<ProductFormScreen> createState() => _ProductFormScreenState();
}

class _ProductFormScreenState extends State<ProductFormScreen> {
  static const _images = <String>[
    'assets/images/teal_sneakers.png',
    'assets/images/grey_sneakers.png',
    'assets/images/white_sneakers.png',
    'assets/images/boots.png',
  ];

  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _priceController;
  late final TextEditingController _locationController;
  late final TextEditingController _reviewsController;
  late final TextEditingController _descriptionController;
  late final TextEditingController _sizesController;
  late String _image;
  late bool _dark;
  bool _saving = false;

  bool get _editing => widget.product != null;

  @override
  void initState() {
    super.initState();
    final product = widget.product;
    _nameController = TextEditingController(text: product?.name);
    _priceController = TextEditingController(text: product?.price.toString());
    _locationController = TextEditingController(text: product?.location);
    _reviewsController = TextEditingController(
      text: product?.reviewCount.toString() ?? '0',
    );
    _descriptionController = TextEditingController(text: product?.description);
    _sizesController = TextEditingController(
      text: product?.sizes.join(', ') ?? '37, 38, 39, 40, 41',
    );
    _image = _images.contains(product?.image) ? product!.image : _images.first;
    _dark = product?.dark ?? false;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _priceController.dispose();
    _locationController.dispose();
    _reviewsController.dispose();
    _descriptionController.dispose();
    _sizesController.dispose();
    super.dispose();
  }

  String? _required(String? value) {
    if (value == null || value.trim().isEmpty) return 'Required field';
    return null;
  }

  String? _positiveNumber(String? value) {
    final number = double.tryParse(value ?? '');
    if (number == null || number <= 0) return 'Enter a number greater than 0';
    return null;
  }

  String? _reviews(String? value) {
    final number = int.tryParse(value ?? '');
    if (number == null || number < 0) return 'Enter 0 or a positive integer';
    return null;
  }

  String? _sizes(String? value) {
    final sizes = value
        ?.split(',')
        .map((part) => int.tryParse(part.trim()))
        .toList();
    if (sizes == null || sizes.isEmpty || sizes.any((size) => size == null)) {
      return 'Example: 37, 38, 39';
    }
    return null;
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    final oldProduct = widget.product;
    final product = Product(
      id: oldProduct?.id ?? 'shoe-${DateTime.now().microsecondsSinceEpoch}',
      name: _nameController.text.trim(),
      image: _image,
      price: double.parse(_priceController.text.trim()),
      location: _locationController.text.trim(),
      reviewCount: int.parse(_reviewsController.text.trim()),
      description: _descriptionController.text.trim(),
      sizes: _sizesController.text
          .split(',')
          .map((part) => int.parse(part.trim()))
          .toList(),
      dark: _dark,
    );

    final store = ShopScope.of(context);
    if (_editing) {
      await store.updateProduct(product);
    } else {
      await store.addProduct(product);
    }
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(_editing ? 'Edit product' : 'Add product')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            TextFormField(
              key: const ValueKey('product-name-field'),
              controller: _nameController,
              decoration: const InputDecoration(labelText: 'Name'),
              validator: _required,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _priceController,
              decoration: const InputDecoration(labelText: 'Price, USD'),
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              validator: _positiveNumber,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _locationController,
              decoration: const InputDecoration(labelText: 'Location'),
              validator: _required,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _reviewsController,
              decoration: const InputDecoration(labelText: 'Number of reviews'),
              keyboardType: TextInputType.number,
              validator: _reviews,
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              initialValue: _image,
              decoration: const InputDecoration(labelText: 'Image path'),
              items: [
                for (final image in _images)
                  DropdownMenuItem(value: image, child: Text(image)),
              ],
              onChanged: (value) => setState(() => _image = value!),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _sizesController,
              decoration: const InputDecoration(labelText: 'EU sizes'),
              validator: _sizes,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _descriptionController,
              decoration: const InputDecoration(labelText: 'Description'),
              minLines: 3,
              maxLines: 6,
              validator: _required,
            ),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Dark image tint'),
              value: _dark,
              onChanged: (value) => setState(() => _dark = value),
            ),
            const SizedBox(height: 18),
            FilledButton.icon(
              key: const ValueKey('save-product'),
              onPressed: _saving ? null : _save,
              icon: const Icon(Icons.save_outlined),
              label: Text(_editing ? 'Save changes' : 'Create product'),
            ),
          ],
        ),
      ),
    );
  }
}
