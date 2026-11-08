import 'package:plugin_platform_interface/plugin_platform_interface.dart';

import 'flutter_qr_scanner_method_channel.dart';

/// The common platform interface for `flutter_qr_scanner`.
///
/// Platform implementations should extend this class rather than implement it
/// as `flutter_qr_scanner` does not consider newly added methods to be breaking
/// changes. Extending this class ensures that the subclass will inherit
/// default fallback behavior.
abstract class FlutterQrScannerPlatform extends PlatformInterface {
  /// Constructs a FlutterQrScannerPlatform.
  FlutterQrScannerPlatform() : super(token: _token);

  static final Object _token = Object();

  static FlutterQrScannerPlatform _instance = MethodChannelFlutterQrScanner();

  /// The default instance of [FlutterQrScannerPlatform] to use.
  ///
  /// Defaults to [MethodChannelFlutterQrScanner].
  static FlutterQrScannerPlatform get instance => _instance;

  /// Platform-specific implementations should set this with their own
  /// platform-specific class that extends [FlutterQrScannerPlatform] when
  /// they register themselves.
  static set instance(FlutterQrScannerPlatform instance) {
    PlatformInterface.verifyToken(instance, _token);
    _instance = instance;
  }

  /// Launches the native camera scanner.
  ///
  /// Returns a [Future] resolving to the scanned barcode or QR code string
  /// value upon success, or `null` if the user dismissed or canceled the
  /// scanner UI without scanning.
  ///
  /// Platform-specific implementations must override this method.
  ///
  /// Throws [UnimplementedError] if not implemented by the platform subclass.
  Future<String?> startScan() {
    throw UnimplementedError('startScan() has not been implemented.');
  }

  /// Legacy platform version method for compatibility with example app.
  Future<String?> getPlatformVersion() {
    throw UnimplementedError('platformVersion() has not been implemented.');
  }
}
