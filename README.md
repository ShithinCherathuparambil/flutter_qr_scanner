# native_qr_scanner

[![pub package](https://img.shields.io/pub/v/native_qr_scanner.svg)](https://pub.dev/packages/native_qr_scanner)
[![license](https://img.shields.io/badge/license-MIT-blue.svg)](https://opensource.org/licenses/MIT)
[![platform](https://img.shields.io/badge/platform-android%20%7C%20ios-blue.svg)](https://pub.dev/packages/native_qr_scanner)

A high-performance, cross-platform Flutter plugin for native QR code and barcode scanning.

On **Android**, it leverages **Google Play Services Code Scanner** (`GmsBarcodeScanning`), providing hardware auto-zoom on small or distant barcodes with **zero camera permissions** required by the host application.

On **iOS**, it presents a high-speed **AVFoundation** modal scanner equipped with a centered reticle overlay, torch/flashlight toggle, haptic feedback, and camera availability protection for simulators.

---

## Features

- **Zero Host Permissions on Android**: Google Play Services runs the camera out-of-process. Your app does not need `android.permission.CAMERA` in its manifest.
- **Hardware Auto-Zoom on Android**: Google Code Scanner automatically zooms in when small or far-away barcodes are detected.
- **AVFoundation Viewfinder on iOS**: Clean, responsive modal scanner with viewfinder reticle cutout, torch toggle, and haptic feedback.
- **All Standard Barcode Formats**: Supports 2D formats (QR Code, Data Matrix, Aztec, PDF417) and 1D formats (EAN-13, EAN-8, UPC-A, UPC-E, Code 128, Code 39, Code 93, ITF, Codabar).
- **Clean Cancellation Flow**: Returns `null` when the user dismisses or cancels the scanner UI, without throwing messy unhandled exceptions.
- **Simulator & Hardware Protection**: Returns clean, typed exceptions (`CameraUnavailableException`) on iOS Simulators rather than crashing.
- **Strongly-Typed Exceptions**: Clear exception taxonomy for permissions, availability, and concurrency.

---

## Platform Support & Requirements

| Platform | Min Version | Camera Permission Required? | Native Engine |
| :--- | :--- | :--- | :--- |
| **Android** | SDK 24 (Android 7.0+) | **No** (Handled by Google Play Services) | Google Play Services Code Scanner |
| **iOS** | iOS 15.0+ | **Yes** (`NSCameraUsageDescription`) | AVFoundation (`AVCaptureSession`) |

---

## Installation & Platform Configuration

### 1. Add Dependency

Add `native_qr_scanner` to your `pubspec.yaml`:

```bash
flutter pub add native_qr_scanner
```

---

### 2. Android Configuration

#### Camera Permission
**No camera permissions are required in your `AndroidManifest.xml`.**  
Because Google Play Services Code Scanner runs the scanner UI in an external Google Play Services process, your application does not need to declare or request `android.permission.CAMERA`.

#### Optional: Pre-download ML Kit Scanning Module
By default, Google Play Services downloads the scanning model on demand when the scanner is first opened. To have the model automatically downloaded from the Google Play Store upon app installation, add the following `<meta-data>` tag inside the `<application>` tag of your `android/app/src/main/AndroidManifest.xml`:

```xml
<manifest xmlns:android="http://schemas.android.com/apk/res/android">
    <application
        android:label="Your App Name"
        android:icon="@mipmap/ic_launcher">

        <!-- Optional: Pre-downloads the Code Scanner module on app install -->
        <meta-data
            android:name="com.google.mlkit.vision.DEPENDENCIES"
            android:value="barcode_ui" />

        <activity ...>
            ...
        </activity>
    </application>
</manifest>
```

---

### 3. iOS Configuration

#### Camera Permission Description
iOS requires `NSCameraUsageDescription` to be declared in `ios/Runner/Info.plist`. Add this key with a message explaining why your app requires camera access:

```xml
<key>NSCameraUsageDescription</key>
<string>We need camera access to scan QR codes and barcodes.</string>
```

> **Note**: If this key is missing from `Info.plist`, iOS will terminate the application immediately when attempting to open the camera.

---

## Usage

### Simple Scan

```dart
import 'package:native_qr_scanner/native_qr_scanner.dart';

Future<void> scanBarcode() async {
  // Launches the native scanner interface
  final String? code = await NativeQrScanner.startScan();

  if (code != null) {
    print('Scanned code: $code');
  } else {
    print('Scan was cancelled by user');
  }
}
```

*Tip: `NativeQrScanner.scan()` is also available as a convenient shorthand alias.*

---

### Comprehensive Error Handling

```dart
import 'package:flutter/material.dart';
import 'package:native_qr_scanner/native_qr_scanner.dart';

Future<void> scanWithFullHandling(BuildContext context) async {
  try {
    final String? result = await NativeQrScanner.startScan();

    if (result != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Scanned: $result')),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Scan cancelled')),
      );
    }
  } on CameraPermissionDeniedException catch (e) {
    // User denied or restricted camera access on iOS
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Camera permission denied: ${e.message}')),
    );
  } on CameraUnavailableException catch (e) {
    // Running on iOS Simulator or device without a working camera
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Camera unavailable: ${e.message}')),
    );
  } on ScannerAlreadyInProgressException catch (e) {
    // startScan() called while a scan is already running
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Scan already active: ${e.message}')),
    );
  } on FlutterQrScannerException catch (e) {
    // Other operational scanner errors
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Scanner error (${e.code}): ${e.message}')),
    );
  }
}
```

---

## Supported Barcode Symbologies

| Symbology | Type | Android | iOS |
| :--- | :--- | :---: | :---: |
| **QR Code** | 2D | Yes | Yes |
| **Data Matrix** | 2D | Yes | Yes |
| **Aztec** | 2D | Yes | Yes |
| **PDF417** | 2D | Yes | Yes |
| **Code 128** | 1D | Yes | Yes |
| **Code 39** | 1D | Yes | Yes |
| **Code 93** | 1D | Yes | Yes |
| **EAN-13** | 1D | Yes | Yes |
| **EAN-8** | 1D | Yes | Yes |
| **UPC-A** | 1D | Yes | Yes |
| **UPC-E** | 1D | Yes | Yes |
| **ITF-14 / ITF** | 1D | Yes | Yes |
| **Codabar** | 1D | Yes | Yes (iOS 15.4+) |

---

## Exception Reference

All exceptions inherit from `FlutterQrScannerException`:

| Exception | Error Code | Description |
| :--- | :--- | :--- |
| `CameraPermissionDeniedException` | `PERMISSION_DENIED` | Camera access was denied or restricted by user settings. |
| `CameraUnavailableException` | `CAMERA_UNAVAILABLE` | Device has no camera, or running on iOS Simulator. |
| `ScannerAlreadyInProgressException` | `ALREADY_SCANNING` | `startScan()` was invoked while another scan session was active. |
| `ScannerExecutionException` | `SCAN_FAILED` / custom | An underlying native operational error occurred. |

---

## Example Application

Check out the [`example/`](https://github.com/ShithinCherathuparambil/flutter_qr_scanner/tree/main/example) directory for a complete runnable application demonstrating:
- Custom Material 3 UI with scanner status and result display.
- Cancellation banner and error feedback.
- Quick re-scan and result clearing controls.

To run the example app:

```bash
cd example
flutter run
```

---

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.
