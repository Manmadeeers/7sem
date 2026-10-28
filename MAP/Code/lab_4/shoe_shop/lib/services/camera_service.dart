import 'dart:typed_data';

import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';

import 'platform_service.dart';

class CameraService {
  CameraService._();

  static final ImagePicker _picker = ImagePicker();

  static Uint8List? lastPhoto;
  static String? recoveryError;

  static Future<void> recoverLostPhoto() async {
    if (!PlatformService.isAndroid) {
      return;
    }

    try {
      final response = await _picker.retrieveLostData();

      if (response.isEmpty) {
        return;
      }

      final files = response.files;

      if (files != null && files.isNotEmpty) {
        lastPhoto = await files.first.readAsBytes();
      } else {
        recoveryError =
            response.exception?.message ?? 'Could not recover the photo.';
      }
    } catch (exception) {
      recoveryError = 'Could not recover the photo: $exception';
    }
  }

  static Future<Uint8List?> takePhoto() async {
    if (!PlatformService.isMobile) {
      throw PlatformException(
        code: 'UNSUPPORTED_PLATFORM',
        message: 'This camera demonstration supports Android and iOS.',
      );
    }

    final photo = await _picker.pickImage(
      source: ImageSource.camera,
      maxWidth: 1600,
      maxHeight: 1600,
      imageQuality: 85,
      requestFullMetadata: false,
    );

    if (photo == null) {
      return null;
    }

    final bytes = await photo.readAsBytes();
    lastPhoto = bytes;

    return bytes;
  }
}