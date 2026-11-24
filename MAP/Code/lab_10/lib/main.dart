import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'bloc/shop_bloc.dart';
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
  runApp(ShoeShopApp(storeLoader: HiveShopStore.open));
}

class ShoeShopApp extends StatefulWidget {
  const ShoeShopApp({super.key, this.store, this.storeLoader});

  final ShopStore? store;
  final ShopStoreLoader? storeLoader;

  @override
  State<ShoeShopApp> createState() => _ShoeShopAppState();
}

class _ShoeShopAppState extends State<ShoeShopApp> {
  late final ShopBloc _shopBloc;

  @override
  void initState() {
    super.initState();
    final loadStore =
        widget.storeLoader ??
        () async => widget.store ?? MemoryShopStore.seeded();
    _shopBloc = ShopBloc(storeLoader: loadStore)..add(const ShopStarted());
  }

  @override
  void dispose() {
    _shopBloc.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [BlocProvider<ShopBloc>.value(value: _shopBloc)],
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
        home: const _ShopHome(),
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

class _ShopHome extends StatelessWidget {
  const _ShopHome();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ShopBloc, ShopState>(
      builder: (context, state) {
        return switch (state) {
          ShopInitial() || ShopLoadInProgress() => const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          ),
          ShopLoadFailure(:final message) => Scaffold(
            body: Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.error_outline, size: 48),
                    const SizedBox(height: 16),
                    Text(message, textAlign: TextAlign.center),
                    const SizedBox(height: 20),
                    FilledButton(
                      onPressed: () =>
                          context.read<ShopBloc>().add(const ShopStarted()),
                      child: const Text('Try again'),
                    ),
                  ],
                ),
              ),
            ),
          ),
          ShopLoadSuccess() => const CatalogScreen(),
        };
      },
    );
  }
}
