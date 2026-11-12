class Product {
  const Product({
    required this.id,
    required this.name,
    required this.image,
    required this.price,
    required this.location,
    required this.reviewCount,
    required this.description,
    this.sizes = const [37, 38, 39, 40, 41],
    this.dark = false,
  });

  final String id;
  final String name;
  final String image;
  final double price;
  final String location;
  final int reviewCount;
  final String description;
  final List<int> sizes;
  final bool dark;

  String get formattedPrice => '${price.toStringAsFixed(0)}\$';

  Product copyWith({
    String? id,
    String? name,
    String? image,
    double? price,
    String? location,
    int? reviewCount,
    String? description,
    List<int>? sizes,
    bool? dark,
  }) {
    return Product(
      id: id ?? this.id,
      name: name ?? this.name,
      image: image ?? this.image,
      price: price ?? this.price,
      location: location ?? this.location,
      reviewCount: reviewCount ?? this.reviewCount,
      description: description ?? this.description,
      sizes: sizes ?? this.sizes,
      dark: dark ?? this.dark,
    );
  }

  Map<String, dynamic> toMap() => {
    'id': id,
    'name': name,
    'image': image,
    'price': price,
    'location': location,
    'reviewCount': reviewCount,
    'description': description,
    'sizes': sizes,
    'dark': dark,
  };

  factory Product.fromMap(Map<dynamic, dynamic> map) {
    return Product(
      id: map['id'] as String,
      name: map['name'] as String,
      image: map['image'] as String,
      price: (map['price'] as num).toDouble(),
      location: map['location'] as String? ?? 'Not specified',
      reviewCount: (map['reviewCount'] as num?)?.toInt() ?? 0,
      description: map['description'] as String,
      sizes: (map['sizes'] as List<dynamic>? ?? const [37, 38, 39, 40, 41])
          .map((value) => (value as num).toInt())
          .toList(),
      dark: map['dark'] as bool? ?? false,
    );
  }
}

class PurchaseSelection {
  const PurchaseSelection({required this.product, required this.size});

  final Product product;
  final int size;
}

const catalogProducts = <Product>[
  Product(
    id: 'nike-shoe',
    name: 'Nike Shoe',
    image: 'assets/images/teal_sneakers.png',
    price: 85,
    location: 'Minsk, Galleria Mall',
    reviewCount: 124,
    description:
        'Lightweight everyday sneakers with a breathable upper '
        'and a soft sole. Suitable for walking and casual outfits.',
  ),
  Product(
    id: 'lebron',
    name: 'Nike Lebron',
    image: 'assets/images/grey_sneakers.png',
    price: 130,
    location: 'Minsk, Dana Mall',
    reviewCount: 238,
    description:
        'Basketball-inspired sneakers with comfortable cushioning '
        'and reliable ankle support. Designed for an active lifestyle.',
  ),
  Product(
    id: 'boots',
    name: 'Classic Boots',
    image: 'assets/images/boots.png',
    price: 95,
    location: 'Grodno, OldCity',
    reviewCount: 76,
    sizes: [38, 39, 40, 41, 42],
    description:
        'Classic boots with a durable upper and a stable sole. '
        'A practical choice for cooler weather and everyday use.',
  ),
  Product(
    id: 'black-sneakers',
    name: 'Black Sneakers',
    image: 'assets/images/teal_sneakers.png',
    price: 90,
    location: 'Brest, Gallery Grand',
    reviewCount: 91,
    dark: true,
    description:
        'Dark everyday sneakers with a simple design. '
        'The flexible sole provides comfort during long walks.',
  ),
];
