import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shoe_shop/main.dart';
import 'package:shoe_shop/models/product.dart';

void main() {
  testWidgets('Selected product is passed to details', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;

    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const ShoeShopApp());
    await tester.pumpAndSettle();

    for (final product in catalogProducts) {
      final card = find.byKey(
        ValueKey('product-${product.id}'),
      );

      await tester.ensureVisible(card);
      await tester.pumpAndSettle();
      await tester.tap(card);
      await tester.pumpAndSettle();

      final name = tester.widget<Text>(
        find.byKey(const ValueKey('detail-product-name')),
      );

      final price = tester.widget<Text>(
        find.byKey(const ValueKey('detail-product-price')),
      );

      expect(name.data, product.name);
      expect(price.data, product.formattedPrice);
      expect(tester.takeException(), isNull);

      await tester.tap(
        find.byKey(const ValueKey('detail-back')),
      );
      await tester.pumpAndSettle();

      expect(find.text('Explore'), findsOneWidget);
    }
  });

  testWidgets('Gallery and navigation results work', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;

    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const ShoeShopApp());
    await tester.pumpAndSettle();

    await tester.tap(
      find.byKey(const ValueKey('promo-details')),
    );
    await tester.pumpAndSettle();

    final galleryFinder = find.byKey(
      const ValueKey('product-pages'),
    );

    await tester.drag(
      galleryFinder,
      const Offset(-300, 0),
    );
    await tester.pumpAndSettle();

    var gallery = tester.widget<PageView>(galleryFinder);

    expect(gallery.controller!.page, closeTo(1, .01));

    await tester.tap(
      find.byKey(const ValueKey('photo-thumbnail-2')),
    );
    await tester.pumpAndSettle();

    gallery = tester.widget<PageView>(galleryFinder);

    expect(gallery.controller!.page, closeTo(2, .01));

    final sizeButton = find.byKey(
      const ValueKey('detail-size-40'),
    );

    await tester.ensureVisible(sizeButton);
    await tester.pumpAndSettle();
    await tester.tap(sizeButton);
    await tester.pumpAndSettle();

    expect(find.text('Choose size'), findsOneWidget);
    expect(find.text('Nike Lebron'), findsOneWidget);

    await tester.tap(
      find.byKey(const ValueKey('confirm-size')),
    );
    await tester.pumpAndSettle();

    expect(find.text('Selected size: 40'), findsOneWidget);

    await tester.pump(const Duration(seconds: 5));
    await tester.pumpAndSettle();

    await tester.tap(
      find.byKey(const ValueKey('buy-now')),
    );
    await tester.pumpAndSettle();

    expect(find.text('Checkout'), findsOneWidget);
    expect(find.text('Nike Lebron'), findsOneWidget);
    expect(find.text('40'), findsOneWidget);
    expect(
      find.text(catalogProducts[1].formattedPrice),
      findsOneWidget,
    );

    await tester.tap(
      find.byKey(const ValueKey('confirm-purchase')),
    );
    await tester.pumpAndSettle();

    expect(
      find.text('Purchase confirmed: Nike Lebron, size 40.'),
      findsOneWidget,
    );

    expect(tester.takeException(), isNull);
  });
}