import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../bloc/shop_bloc.dart';
import '../theme.dart';
import 'platform_demo_screen.dart';

class StorageScreen extends StatelessWidget {
  const StorageScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<ShopBloc, ShopState>(
      listenWhen: (previous, current) =>
          current is ShopLoadSuccess &&
          current.actionStatus == ShopActionStatus.failure &&
          (current.action == ShopAction.wrongKeyDemo ||
              current.action == ShopAction.compactStorage) &&
          (previous is! ShopLoadSuccess ||
              previous.actionRevision != current.actionRevision),
      listener: (context, state) {
        final shop = state as ShopLoadSuccess;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(shop.actionMessage ?? 'Operation failed.')),
        );
      },
      builder: (context, state) {
        final shop = state as ShopLoadSuccess;
        final storageAction =
            shop.action == ShopAction.wrongKeyDemo ||
            shop.action == ShopAction.compactStorage;
        final busy =
            storageAction && shop.actionStatus == ShopActionStatus.inProgress;
        final showResult =
            storageAction && shop.actionStatus == ShopActionStatus.success;
        return Scaffold(
          appBar: AppBar(title: const Text('Hive storage')),
          body: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              _InfoCard(
                icon: Icons.lock_outline,
                title: 'Encrypted boxes',
                text: shop.storageDescription,
              ),
              const SizedBox(height: 12),
              _InfoCard(
                icon: Icons.key_outlined,
                title: 'Saved encryption key',
                text:
                    'Fingerprint: ${shop.keyFingerprint}…\n'
                    'Only a fingerprint is shown; the full 256-bit key stays in '
                    'the application support directory.',
              ),
              const SizedBox(height: 18),
              FilledButton.icon(
                key: const ValueKey('wrong-key-demo'),
                onPressed: busy
                    ? null
                    : () => context.read<ShopBloc>().add(
                        const WrongKeyDemoRequested(),
                      ),
                icon: const Icon(Icons.vpn_key_off_outlined),
                label: const Text('Try the second (wrong) key'),
              ),
              if (showResult && shop.action == ShopAction.wrongKeyDemo) ...[
                const SizedBox(height: 10),
                Text(
                  shop.actionMessage!,
                  style: const TextStyle(color: ShopColors.muted),
                ),
              ],
              const SizedBox(height: 12),
              OutlinedButton.icon(
                key: const ValueKey('compact-boxes'),
                onPressed: busy
                    ? null
                    : () => context.read<ShopBloc>().add(
                        const StorageCompactionRequested(),
                      ),
                icon: const Icon(Icons.compress_outlined),
                label: const Text('Compact Hive boxes'),
              ),
              if (showResult && shop.action == ShopAction.compactStorage) ...[
                const SizedBox(height: 10),
                Text(
                  shop.actionMessage!,
                  style: const TextStyle(color: ShopColors.muted),
                ),
              ],
              const SizedBox(height: 24),
              TextButton.icon(
                onPressed: () => Navigator.of(context).push<void>(
                  MaterialPageRoute<void>(
                    builder: (_) => const PlatformDemoScreen(),
                  ),
                ),
                icon: const Icon(Icons.phone_android_outlined),
                label: const Text('Open laboratory 4–5 platform demo'),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _InfoCard extends StatelessWidget {
  const _InfoCard({
    required this.icon,
    required this.title,
    required this.text,
  });

  final IconData icon;
  final String title;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: ShopColors.card,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: ShopColors.blue),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 7),
                Text(text, style: const TextStyle(color: ShopColors.muted)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
