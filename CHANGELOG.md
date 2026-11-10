## 0.0.2

* Add explicit platform declaration for Android and iOS in `pubspec.yaml`.
* Add Swift Package Manager (SwiftPM) support for iOS via `ios/native_qr_scanner/Package.swift`.
* Synchronize iOS podspec source paths with the Swift package directory layout.

## 0.0.1

* Initial release of `native_qr_scanner`.
* Native Android scanning powered by Google Play Services Code Scanner with auto-zoom and zero host camera permission requirements.
* Native iOS scanning powered by AVFoundation with modal viewfinder, reticle overlay, torch toggle, and haptic feedback.
* Unified cross-platform Dart API with typed exceptions (`CameraPermissionDeniedException`, `CameraUnavailableException`, `ScannerAlreadyInProgressException`).
* Graceful user cancellation returning `null` without throwing unhandled exceptions.
* Comprehensive example application with Material 3 UI demonstrating scan triggering, cancellation, and error handling.
