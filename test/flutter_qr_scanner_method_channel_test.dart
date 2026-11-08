import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:native_qr_scanner/flutter_qr_scanner_method_channel.dart';
import 'package:native_qr_scanner/src/errors.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final MethodChannelFlutterQrScanner platform =
      MethodChannelFlutterQrScanner();
  const MethodChannel channel = MethodChannel('flutter_qr_scanner');
  final List<MethodCall> log = <MethodCall>[];

  void setMockMethodCallHandler(
    Future<Object?>? Function(MethodCall methodCall) handler,
  ) {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (MethodCall methodCall) async {
          log.add(methodCall);
          return handler(methodCall);
        });
  }

  setUp(() {
    log.clear();
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null);
  });

  group('MethodChannelFlutterQrScanner.startScan', () {
    test('invokes startScan method on flutter_qr_scanner channel with null arguments', () async {
      setMockMethodCallHandler((MethodCall methodCall) async {
        return 'SCAN_RESULT_123';
      });

      final result = await platform.startScan();

      expect(log, hasLength(1));
      expect(log.single.method, 'startScan');
      expect(log.single.arguments, isNull);
      expect(result, 'SCAN_RESULT_123');
    });

    test('returns scanned string when channel returns string', () async {
      setMockMethodCallHandler((MethodCall methodCall) async {
        return 'https://flutter.dev/docs';
      });

      final result = await platform.startScan();
      expect(result, 'https://flutter.dev/docs');
    });

    test(
      'returns null when channel returns null on user cancellation',
      () async {
        setMockMethodCallHandler((MethodCall methodCall) async {
          return null;
        });

        final result = await platform.startScan();
        expect(result, isNull);
      },
    );

    test('maps PERMISSION_DENIED PlatformException to CameraPermissionDeniedException', () async {
      setMockMethodCallHandler((MethodCall methodCall) async {
        throw PlatformException(
          code: 'PERMISSION_DENIED',
          message: 'Camera permission denied by user.',
        );
      });

      expect(
        () => platform.startScan(),
        throwsA(
          isA<CameraPermissionDeniedException>()
              .having((e) => e.code, 'code', 'PERMISSION_DENIED')
              .having(
                (e) => e.message,
                'message',
                'Camera permission denied by user.',
              ),
        ),
      );
    });

    test('maps PERMISSION_RESTRICTED PlatformException to CameraPermissionDeniedException', () async {
      setMockMethodCallHandler((MethodCall methodCall) async {
        throw PlatformException(
          code: 'PERMISSION_RESTRICTED',
          message: 'Camera permission is restricted by parental controls.',
        );
      });

      expect(
        () => platform.startScan(),
        throwsA(
          isA<CameraPermissionDeniedException>()
              .having((e) => e.code, 'code', 'PERMISSION_DENIED')
              .having((e) => e.message, 'message', contains('restricted')),
        ),
      );
    });

    test(
      'maps CAMERA_UNAVAILABLE PlatformException to CameraUnavailableException',
      () async {
        setMockMethodCallHandler((MethodCall methodCall) async {
          throw PlatformException(
            code: 'CAMERA_UNAVAILABLE',
            message: 'No camera hardware found on this device or simulator.',
          );
        });

        expect(
          () => platform.startScan(),
          throwsA(
            isA<CameraUnavailableException>()
                .having((e) => e.code, 'code', 'CAMERA_UNAVAILABLE')
                .having(
                  (e) => e.message,
                  'message',
                  contains('No camera hardware found'),
                ),
          ),
        );
      },
    );

    test(
      'maps NO_CAMERA PlatformException to CameraUnavailableException',
      () async {
        setMockMethodCallHandler((MethodCall methodCall) async {
          throw PlatformException(
            code: 'NO_CAMERA',
            message: 'Simulator has no camera sensor.',
          );
        });

        expect(
          () => platform.startScan(),
          throwsA(
            isA<CameraUnavailableException>()
                .having((e) => e.code, 'code', 'CAMERA_UNAVAILABLE')
                .having(
                  (e) => e.message,
                  'message',
                  contains('Simulator has no camera sensor.'),
                ),
          ),
        );
      },
    );

    test('maps ALREADY_SCANNING PlatformException to ScannerAlreadyInProgressException', () async {
      setMockMethodCallHandler((MethodCall methodCall) async {
        throw PlatformException(
          code: 'ALREADY_SCANNING',
          message: 'A scanning session is already active.',
        );
      });

      expect(
        () => platform.startScan(),
        throwsA(
          isA<ScannerAlreadyInProgressException>()
              .having((e) => e.code, 'code', 'ALREADY_SCANNING')
              .having(
                (e) => e.message,
                'message',
                'A scanning session is already active.',
              ),
        ),
      );
    });

    test(
      'maps unrecognized PlatformException codes to ScannerExecutionException',
      () async {
        setMockMethodCallHandler((MethodCall methodCall) async {
          throw PlatformException(
            code: 'GENERIC_SCAN_ERROR',
            message: 'Google Play Services scanning failed unexpectedly.',
            details: {'status': 500},
          );
        });

        expect(
          () => platform.startScan(),
          throwsA(
            isA<ScannerExecutionException>()
                .having((e) => e.code, 'code', 'GENERIC_SCAN_ERROR')
                .having(
                  (e) => e.message,
                  'message',
                  contains('Google Play Services scanning failed'),
                )
                .having((e) => e.details, 'details', {'status': 500}),
          ),
        );
      },
    );

    test('handles PlatformException with null message by providing default message', () async {
      setMockMethodCallHandler((MethodCall methodCall) async {
        throw PlatformException(code: 'PERMISSION_DENIED');
      });

      expect(
        () => platform.startScan(),
        throwsA(
          isA<CameraPermissionDeniedException>()
              .having((e) => e.code, 'code', 'PERMISSION_DENIED')
              .having((e) => e.message, 'message', isNotEmpty),
        ),
      );
    });
  });
}
