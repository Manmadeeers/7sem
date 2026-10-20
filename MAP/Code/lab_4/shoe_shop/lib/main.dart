import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'screens/catalog_screen.dart';
import 'theme.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle.dark);
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
    );
  }
}
