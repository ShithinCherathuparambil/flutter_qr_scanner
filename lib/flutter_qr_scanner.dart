import 'flutter_qr_scanner_platform_interface.dart';
export 'src/errors.dart';

/// The public entry point for the Flutter QR Scanner plugin.
///
/// Provides static methods to launch native barcode and QR code scanning
/// on Android and iOS devices.
class FlutterQrScanner {
  /// Constructs a [FlutterQrScanner] instance.
  ///
  /// Note: Prefer using the static methods [FlutterQrScanner.startScan]
  /// or [FlutterQrScanner.scan] directly.
  const FlutterQrScanner();

  /// Launches the native camera scanner to scan a barcode or QR code.
  ///
  /// On Android, this opens the Google Play Services Code Scanner modal with
  /// auto-zoom enabled. On iOS, this presents an AVFoundation camera scanner
  /// modal with reticle viewfinder and torch controls.
  ///
  /// Returns the scanned barcode or QR code string value upon success.
  /// Returns `null` if the user closes, dismisses, or cancels the scanner UI
  /// without scanning.
  ///
  /// Throws [CameraPermissionDeniedException] if camera permission is denied
  /// or restricted.
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
  ///
  /// Launches the native scanner interface. See [startScan] for complete
  /// details on return values and exceptions.
  static Future<String?> scan() => startScan();

  /// Legacy platform version method for compatibility with example app.
  Future<String?> getPlatformVersion() {
    return FlutterQrScannerPlatform.instance.getPlatformVersion();
  }
}
