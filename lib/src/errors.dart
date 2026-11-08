/// Base exception thrown when a Flutter QR Scanner operation fails.
///
/// Subclasses provide more specific information for well-known failure modes:
/// - [CameraPermissionDeniedException]
/// - [CameraUnavailableException]
/// - [ScannerAlreadyInProgressException]
/// - [ScannerExecutionException]
class FlutterQrScannerException implements Exception {
  /// Constructs a [FlutterQrScannerException] with the provided [message],
  /// and optional [code] and [details].
  const FlutterQrScannerException(this.message, {this.code, this.details});

  /// The human-readable message describing the error.
  final String message;

  /// The machine-readable error code, if available.
  final String? code;

  /// Additional error details supplied by the platform, if available.
  final dynamic details;

  @override
  String toString() {
    if (code != null) {
      return '$runtimeType($code): $message';
    }
    return '$runtimeType: $message';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    return other is FlutterQrScannerException &&
        other.runtimeType == runtimeType &&
        other.message == message &&
        other.code == code &&
        other.details == details;
  }

  @override
  int get hashCode => Object.hash(runtimeType, message, code, details);
}

/// Thrown when camera access permission is denied or restricted.
///
/// This occurs when the user rejects camera access or when access is blocked
/// by device policy (such as enterprise management or parental restrictions).
class CameraPermissionDeniedException extends FlutterQrScannerException {
  /// Constructs a [CameraPermissionDeniedException] with an optional [message]
  /// and [details].
  const CameraPermissionDeniedException([
    super.message = 'Camera permission was denied.',
    dynamic details,
  ]) : super(code: 'PERMISSION_DENIED', details: details);
}

/// Thrown when no camera hardware is available on the device or simulator.
///
/// This occurs on hardware lacking a video camera, when camera hardware has
/// failed, or when running on an iOS Simulator or Android emulator without
/// a virtual camera configured.
class CameraUnavailableException extends FlutterQrScannerException {
  /// Constructs a [CameraUnavailableException] with an optional [message]
  /// and [details].
  const CameraUnavailableException([
    super.message = 'No camera device is available.',
    dynamic details,
  ]) : super(code: 'CAMERA_UNAVAILABLE', details: details);
}

/// Thrown when a scan session is started while another scan is active.
///
/// Only a single scan session can be active at a time. Callers should await
/// the active scan session before initiating another.
class ScannerAlreadyInProgressException extends FlutterQrScannerException {
  /// Constructs a [ScannerAlreadyInProgressException] with an optional
  /// [message] and [details].
  const ScannerAlreadyInProgressException([
    super.message = 'A scan is already in progress.',
    dynamic details,
  ]) : super(code: 'ALREADY_SCANNING', details: details);
}

/// Thrown when an unexpected error occurs during scanner execution.
///
/// Wraps unhandled platform exceptions or scanner errors that do not match
/// the more specific exception categories.
class ScannerExecutionException extends FlutterQrScannerException {
  /// Constructs a [ScannerExecutionException] with the provided [message],
  /// and optional [code] and [details].
  const ScannerExecutionException(super.message, {super.code, super.details});
}
