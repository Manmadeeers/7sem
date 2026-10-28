class Product {
  const Product({
    required this.id,
    required this.name,
    required this.image,
    required this.price,
    required this.description,
    this.sizes = const [37, 38, 39, 40, 41],
    this.dark = false,
    this.favorite = false,
  });

  final String id;
  final String name;
  final String image;
  final double price;
  final String description;
  final List<int> sizes;
  final bool dark;
  final bool favorite;

  String get formattedPrice => '${price.toStringAsFixed(0)}\$';
}

class PurchaseSelection {
  const PurchaseSelection({
    required this.product,
    required this.size,
  });

  final Product product;
  final int size;
}

const catalogProducts = <Product>[
  Product(
    id: 'nike-shoe',
    name: 'Nike Shoe',
    image: 'teal_sneakers',
    price: 85,
    description:
        'Lightweight everyday sneakers with a breathable upper '
        'and a soft sole. Suitable for walking and casual outfits.',
  ),
  Product(
    id: 'lebron',
    name: 'Nike Lebron',
    image: 'grey_sneakers',
    price: 130,
    favorite: true,
    description:
        'Basketball-inspired sneakers with comfortable cushioning '
        'and reliable ankle support. Designed for an active lifestyle.',
  ),
  Product(
    id: 'boots',
    name: 'Classic Boots',
    image: 'boots',
    price: 95,
    sizes: [38, 39, 40, 41, 42],
    description:
        'Classic boots with a durable upper and a stable sole. '
        'A practical choice for cooler weather and everyday use.',
  ),
  Product(
    id: 'black-sneakers',
    name: 'Black Sneakers',
    image: 'teal_sneakers',
    price: 90,
    dark: true,
    description:
        'Dark everyday sneakers with a simple design. '
        'The flexible sole provides comfort during long walks.',
  ),
];