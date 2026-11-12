import 'package:flutter/widgets.dart';

import 'shop_store.dart';

class ShopScope extends InheritedNotifier<ShopStore> {
  const ShopScope({super.key, required ShopStore store, required super.child})
    : super(notifier: store);

  static ShopStore of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<ShopScope>();
    assert(scope != null, 'ShopScope was not found in the widget tree.');
    return scope!.notifier!;
  }
}
