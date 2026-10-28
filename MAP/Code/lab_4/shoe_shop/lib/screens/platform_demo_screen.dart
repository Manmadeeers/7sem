import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../services/camera_service.dart';
import '../services/platform_service.dart';
import '../theme.dart';

class PlatformDemoScreen extends StatefulWidget {
  const PlatformDemoScreen({super.key});

  @override
  State<PlatformDemoScreen> createState() => _PlatformDemoScreenState();
}

class _PlatformDemoScreenState extends State<PlatformDemoScreen> {
  final _messageFormKey = GlobalKey<FormState>();

  final _phoneController = TextEditingController();

  final _messageController = TextEditingController(
    text: 'Hello! I would like to ask about shoes in your shop.',
  );

  String? _ipAddress;
  int? _batteryLevel;
  Uint8List? _photo = CameraService.lastPhoto;
  String? _status = CameraService.recoveryError;
  bool _busy = false;

  @override
  void dispose() {
    _phoneController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  Future<void> _run(Future<String> Function() action) async {
    if (_busy) {
      return;
    }

    setState(() {
      _busy = true;
      _status = null;
    });

    String message;

    try {
      message = await action();
    } on PlatformException catch (exception) {
      message = exception.message ?? exception.code;
    } on MissingPluginException {
      message =
          'A native implementation is missing. '
          'Stop the application and run it again on a supported device.';
    } catch (exception) {
      message = 'Operation failed: $exception';
    }

    if (!mounted) {
      return;
    }

    setState(() {
      _status = message;
      _busy = false;
    });
  }

  Future<void> _loadIpAddress() async {
    await _run(() async {
      _ipAddress = await PlatformService.getIpAddress();
      return 'IP address updated.';
    });
  }

  Future<void> _loadBatteryLevel() async {
    await _run(() async {
      _batteryLevel = await PlatformService.getBatteryLevel();
      return 'Battery level updated.';
    });
  }

  Future<void> _openMessage() async {
    if (!_messageFormKey.currentState!.validate()) {
      return;
    }

    final phoneNumber = _phoneController.text;
    final body = _messageController.text;

    await _run(() async {
      await PlatformService.composeMessage(
        phoneNumber: phoneNumber,
        body: body,
      );

      return 'The messaging composer was opened.';
    });
  }

  Future<void> _takePhoto() async {
    await _run(() async {
      final photo = await CameraService.takePhoto();

      if (photo == null) {
        return 'Camera closed without a new photo.';
      }

      _photo = photo;
      return 'Photo captured.';
    });
  }

  Widget _section(String title, List<Widget> children) {
    return Container(
      margin: const EdgeInsets.only(bottom: 18),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: ShopColors.card,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            title,
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 16),
          ...children,
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final androidAvailable = PlatformService.isAndroid;
    final mobileAvailable = PlatformService.isMobile;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Platform Method Channel'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(22),
        children: [
          if (_busy) ...[
            const LinearProgressIndicator(),
            const SizedBox(height: 16),
          ],
          if (_status != null) ...[
            Text(
              _status!,
              style: const TextStyle(
                color: ShopColors.muted,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 18),
          ],
          _section(
            'IP address',
            [
              SelectableText(
                _ipAddress ?? 'Not requested',
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                'Address on the active network. Android implementation.',
                style: TextStyle(color: ShopColors.muted),
              ),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: _busy || !androidAvailable
                    ? null
                    : _loadIpAddress,
                child: const Text('Get IP address'),
              ),
            ],
          ),
          _section(
            'Battery',
            [
              Text(
                _batteryLevel == null
                    ? 'Not requested'
                    : 'Battery level: $_batteryLevel%',
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: _busy || !mobileAvailable
                    ? null
                    : _loadBatteryLevel,
                child: const Text('Get battery level'),
              ),
            ],
          ),
          _section(
            'Compose a message',
            [
              Form(
                key: _messageFormKey,
                child: Column(
                  children: [
                    TextFormField(
                      controller: _phoneController,
                      keyboardType: TextInputType.phone,
                      decoration: const InputDecoration(
                        labelText: 'Phone number',
                        hintText: 'Enter a phone number',
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Enter a phone number.';
                        }

                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _messageController,
                      keyboardType: TextInputType.multiline,
                      minLines: 3,
                      maxLines: 6,
                      decoration: const InputDecoration(
                        labelText: 'Message',
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Enter a message.';
                        }

                        return null;
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: _busy || !androidAvailable
                    ? null
                    : _openMessage,
                child: const Text('Open messaging app'),
              ),
              const SizedBox(height: 12),
              const Text(
                'Review and send the message in the messaging app. '
                'This demonstration is implemented for Android.',
                style: TextStyle(
                  color: ShopColors.muted,
                  height: 1.5,
                ),
              ),
            ],
          ),
          _section(
            'Camera',
            [
              if (_photo != null) ...[
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.memory(
                    _photo!,
                    height: 240,
                    width: double.infinity,
                    fit: BoxFit.contain,
                  ),
                ),
                const SizedBox(height: 16),
              ] else ...[
                const Icon(
                  Icons.camera_alt_outlined,
                  size: 60,
                  color: ShopColors.muted,
                ),
                const SizedBox(height: 16),
              ],
              FilledButton(
                onPressed: _busy || !mobileAvailable ? null : _takePhoto,
                child: const Text('Take photo'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}