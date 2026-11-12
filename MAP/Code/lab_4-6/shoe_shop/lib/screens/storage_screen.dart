import 'package:flutter/material.dart';

import '../data/shop_scope.dart';
import '../theme.dart';
import 'platform_demo_screen.dart';

class StorageScreen extends StatefulWidget {
  const StorageScreen({super.key});

  @override
  State<StorageScreen> createState() => _StorageScreenState();
}

class _StorageScreenState extends State<StorageScreen> {
  String? _wrongKeyResult;
  String? _compactionResult;
  bool _busy = false;

  Future<void> _run(Future<String> Function() action, bool wrongKey) async {
    setState(() => _busy = true);
    final result = await action();
    if (!mounted) return;
    setState(() {
      _busy = false;
      if (wrongKey) {
        _wrongKeyResult = result;
      } else {
        _compactionResult = result;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final store = ShopScope.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Hive storage')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          _InfoCard(
            icon: Icons.lock_outline,
            title: 'Encrypted boxes',
            text: store.storageDescription,
          ),
          const SizedBox(height: 12),
          _InfoCard(
            icon: Icons.key_outlined,
            title: 'Saved encryption key',
            text:
                'Fingerprint: ${store.keyFingerprint}…\n'
                'Only a fingerprint is shown; the full 256-bit key stays in '
                'the application support directory.',
          ),
          const SizedBox(height: 18),
          FilledButton.icon(
            key: const ValueKey('wrong-key-demo'),
            onPressed: _busy
                ? null
                : () => _run(store.demonstrateWrongKey, true),
            icon: const Icon(Icons.vpn_key_off_outlined),
            label: const Text('Try the second (wrong) key'),
          ),
          if (_wrongKeyResult != null) ...[
            const SizedBox(height: 10),
            Text(
              _wrongKeyResult!,
              style: const TextStyle(color: ShopColors.muted),
            ),
          ],
          const SizedBox(height: 12),
          OutlinedButton.icon(
            key: const ValueKey('compact-boxes'),
            onPressed: _busy ? null : () => _run(store.compactBoxes, false),
            icon: const Icon(Icons.compress_outlined),
            label: const Text('Compact Hive boxes'),
          ),
          if (_compactionResult != null) ...[
            const SizedBox(height: 10),
            Text(
              _compactionResult!,
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
