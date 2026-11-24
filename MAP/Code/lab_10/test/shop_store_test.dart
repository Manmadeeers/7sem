import 'package:flutter_test/flutter_test.dart';
import 'package:shoe_shop/data/shop_store.dart';
import 'package:shoe_shop/models/product.dart';

void main() {
  group('ShopStore roles and favorites', () {
    test('customer cannot modify products, manager can', () async {
      final store = MemoryShopStore.seeded();
      const product = Product(
        id: 'test-shoe',
        name: 'Test Shoe',
        image: 'assets/images/white_sneakers.png',
        price: 100,
        location: 'Minsk',
        reviewCount: 0,
        description: 'A product created by the test.',
      );

      await expectLater(store.addProduct(product), throwsStateError);

      await store.selectUser('max');
      await store.addProduct(product);
      expect(store.products.any((item) => item.id == product.id), isTrue);

      await store.updateProduct(product.copyWith(price: 125));
      expect(
        store.products.firstWhere((item) => item.id == product.id).price,
        125,
      );

      await store.deleteProduct(product.id);
      expect(store.products.any((item) => item.id == product.id), isFalse);
    });

    test('favorites belong to the selected user', () async {
      final store = MemoryShopStore.seeded();

      expect(store.isFavorite('lebron'), isTrue);
      await store.selectUser('max');
      expect(store.isFavorite('lebron'), isFalse);

      await store.toggleFavorite('lebron');
      expect(store.isFavorite('lebron'), isTrue);

      await store.selectUser('anna');
      expect(store.isFavorite('lebron'), isTrue);
      await store.toggleFavorite('lebron');
      expect(store.isFavorite('lebron'), isFalse);

      await store.selectUser('max');
      expect(store.isFavorite('lebron'), isTrue);
    });
  });
}
