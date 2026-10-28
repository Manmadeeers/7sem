import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

class PlatformService {
  PlatformService._();

  static const MethodChannel _networkChannel = MethodChannel(
    'shoe_shop/network',
  );

  static const MethodChannel _messageChannel = MethodChannel(
    'shoe_shop/messages',
  );

  static const MethodChannel _androidBatteryChannel = MethodChannel(
    'shoe_shop/battery/android',
  );

  static const MethodChannel _iosBatteryChannel = MethodChannel(
    'shoe_shop/battery/ios',
  );

  static bool get isAndroid =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.android;

  static bool get isIOS =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.iOS;

  static bool get isMobile => isAndroid || isIOS;

  static void _requireAndroid() {
    if (!isAndroid) {
      throw PlatformException(
        code: 'UNSUPPORTED_PLATFORM',
        message: 'This feature is currently implemented for Android.',
      );
    }
  }

  static Future<String> getIpAddress() async {
    _requireAndroid();

    final address = await _networkChannel.invokeMethod<String>(
      'getIpAddress',
    );

    if (address == null || address.isEmpty) {
      throw PlatformException(
        code: 'NO_ADDRESS',
        message: 'Android did not return an IP address.',
      );
    }

    return address;
  }

  static Future<void> composeMessage({
    required String phoneNumber,
    required String body,
  }) async {
    _requireAndroid();

    if (phoneNumber.trim().isEmpty || body.trim().isEmpty) {
      throw PlatformException(
        code: 'INVALID_ARGUMENTS',
        message: 'Enter a phone number and message.',
      );
    }

    await _messageChannel.invokeMethod<void>(
      'composeMessage',
      {
        'phoneNumber': phoneNumber.trim(),
        'body': body,
      },
    );
  }

  static Future<int> getBatteryLevel() async {
    final MethodChannel channel;

    if (isAndroid) {
      channel = _androidBatteryChannel;
    } else if (isIOS) {
      channel = _iosBatteryChannel;
    } else {
      throw PlatformException(
        code: 'UNSUPPORTED_PLATFORM',
        message: 'Battery reading is implemented for Android and iOS.',
      );
    }

    final level = await channel.invokeMethod<int>('getBatteryLevel');

    if (level == null || level < 0 || level > 100) {
      throw PlatformException(
        code: 'BATTERY_UNAVAILABLE',
        message: 'The battery level is unavailable.',
      );
    }

    return level;
  }
}