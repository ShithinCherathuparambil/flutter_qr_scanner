import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'flutter_qr_scanner_platform_interface.dart';
import 'src/errors.dart';

/// An implementation of [FlutterQrScannerPlatform] that uses method channels.
class MethodChannelFlutterQrScanner extends FlutterQrScannerPlatform {
  /// The method channel used to interact with the native platform.
  @visibleForTesting
  final methodChannel = const MethodChannel('flutter_qr_scanner');

  @override
  Future<String?> startScan() async {
    try {
      final result = await methodChannel.invokeMethod<String>('startScan');
      return result;
    } on PlatformException catch (e) {
      throw _mapPlatformException(e);
    }
  }

  @override
  Future<String?> getPlatformVersion() async {
    return methodChannel.invokeMethod<String>('getPlatformVersion');
  }

  /// Maps a [PlatformException] thrown by the native method channel into a
  /// typed [FlutterQrScannerException].
  FlutterQrScannerException _mapPlatformException(PlatformException e) {
    switch (e.code) {
      case 'PERMISSION_DENIED':
      case 'PERMISSION_RESTRICTED':
        return CameraPermissionDeniedException(
          e.message ?? 'Camera permission was denied.',
          e.details,
        );
      case 'CAMERA_UNAVAILABLE':
      case 'NO_CAMERA':
        return CameraUnavailableException(
          e.message ?? 'No camera device is available.',
          e.details,
        );
      case 'ALREADY_SCANNING':
        return ScannerAlreadyInProgressException(
          e.message ?? 'A scan is already in progress.',
          e.details,
        );
      default:
        return ScannerExecutionException(
          e.message ?? 'An unknown scanner error occurred.',
          code: e.code,
          details: e.details,
        );
    }
  }
}
