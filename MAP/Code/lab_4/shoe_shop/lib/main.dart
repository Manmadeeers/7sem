import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'models/product.dart';
import 'screens/catalog_screen.dart';
import 'screens/checkout_screen.dart';
import 'services/camera_service.dart';
import 'theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle.dark);

  await CameraService.recoverLostPhoto();

  runApp(const ShoeShopApp());
}

class ShoeShopApp extends StatelessWidget {
  const ShoeShopApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
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
    );
  }
}