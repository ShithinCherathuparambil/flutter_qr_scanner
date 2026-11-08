import 'flutter_qr_scanner_platform_interface.dart';
export 'flutter_qr_scanner_platform_interface.dart';
export 'src/errors.dart';

/// The public entry point for the Native QR Scanner plugin.
///
/// Provides static methods to launch native barcode and QR code scanning
/// on Android (via Google Play Services Code Scanner) and iOS (via AVFoundation).
class NativeQrScanner {
  /// Constructs a [NativeQrScanner] instance.
  ///
  /// Prefer using the static methods [NativeQrScanner.startScan] or
  /// [NativeQrScanner.scan] directly.
  const NativeQrScanner();

  /// Launches the native camera scanner to scan a barcode or QR code.
  ///
  /// On Android, this opens the Google Play Services Code Scanner modal with
  /// auto-zoom enabled without requiring host CAMERA permissions.
  /// On iOS, this presents an AVFoundation camera scanner modal with reticle
  /// viewfinder, flash/torch toggle, and cancel controls.
  ///
  /// Returns the scanned barcode or QR code string value upon success.
  /// Returns `null` if the user closes, dismisses, or cancels the scanner UI
  /// without scanning.
  ///
  /// Throws [CameraPermissionDeniedException] if camera permission is denied
  /// or restricted on iOS.
  /// Throws [CameraUnavailableException] if no camera hardware is available
  /// on the device or simulator.
  /// Throws [ScannerAlreadyInProgressException] if another scanning session
  /// is already active.
  /// Throws [ScannerExecutionException] or [FlutterQrScannerException] if an
  /// unexpected operational error occurs during scanning.
  static Future<String?> startScan() {
    return FlutterQrScannerPlatform.instance.startScan();
  }

  /// Ergonomic shorthand alias for [startScan].
  static Future<String?> scan() => startScan();

  /// Legacy platform version method for compatibility with example app.
  Future<String?> getPlatformVersion() {
    return FlutterQrScannerPlatform.instance.getPlatformVersion();
  }
}

/// Backwards-compatible alias for [NativeQrScanner].
typedef FlutterQrScanner = NativeQrScanner;
