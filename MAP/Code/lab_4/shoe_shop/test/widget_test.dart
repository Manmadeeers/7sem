import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shoe_shop/main.dart';

void main() {
  for (final size in [
    const Size(320, 640),
    const Size(390, 844),
    const Size(1200, 900),
  ]) {
    testWidgets('Catalog, details and back at $size', (tester) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(const ShoeShopApp());
      await tester.pumpAndSettle();
      expect(find.text('Explore'), findsOneWidget);
      expect(tester.takeException(), isNull);

      for (final target in [
        find.byKey(const ValueKey('lebron-card')),
        find.byKey(const ValueKey('promo-details')),
      ]) {
        await tester.ensureVisible(target);
        await tester.tap(target);
        await tester.pumpAndSettle();
        expect(find.text('Details'), findsOneWidget);
        expect(find.text('Nike Lebron'), findsOneWidget);
        expect(find.text('130\$'), findsOneWidget);
        expect(tester.takeException(), isNull);

        await tester.tap(find.byKey(const ValueKey('detail-back')));
        await tester.pumpAndSettle();
        expect(find.text('Explore'), findsOneWidget);
        expect(find.text('Details'), findsNothing);
        expect(tester.takeException(), isNull);
      }
    });
  }
}
