import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'data/shop_scope.dart';
import 'data/shop_store.dart';
import 'models/product.dart';
import 'screens/catalog_screen.dart';
import 'screens/checkout_screen.dart';
import 'services/camera_service.dart';
import 'theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle.dark);

  await CameraService.recoverLostPhoto();
  final store = await HiveShopStore.open();

  runApp(ShoeShopApp(store: store));
}

class ShoeShopApp extends StatelessWidget {
  const ShoeShopApp({super.key, this.store});

  final ShopStore? store;

  static final ShopStore _testStore = MemoryShopStore.seeded();

  @override
  Widget build(BuildContext context) {
    return ShopScope(
      store: store ?? _testStore,
      child: MaterialApp(
        title: 'Shoe Shop',
        debugShowCheckedModeBanner: false,
        theme: shopTheme,
        builder: (context, child) => ColoredBox(
          color: const Color(0xFFECEEEF),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 430),
              child: child!,
            ),
          ),
        ),
        home: const CatalogScreen(),
        onGenerateRoute: (settings) {
          if (settings.name == CheckoutScreen.routeName) {
            final arguments = settings.arguments;

            if (arguments is! PurchaseSelection) {
              throw FlutterError(
                '${CheckoutScreen.routeName} requires PurchaseSelection.',
              );
            }

            return MaterialPageRoute<bool>(
              settings: settings,
              builder: (_) => CheckoutScreen(selection: arguments),
            );
          }

          return null;
        },
      ),
    );
  }
}
