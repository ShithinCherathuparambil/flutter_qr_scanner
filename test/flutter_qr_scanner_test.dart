import 'package:flutter_test/flutter_test.dart';
import 'package:native_qr_scanner/native_qr_scanner.dart';
import 'package:native_qr_scanner/flutter_qr_scanner_method_channel.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

class MockFlutterQrScannerPlatform
    with MockPlatformInterfaceMixin
    implements FlutterQrScannerPlatform {
  String? scanResult;
  Exception? exceptionToThrow;

  @override
  Future<String?> startScan() async {
    if (exceptionToThrow != null) {
      throw exceptionToThrow!;
    }
    return scanResult;
  }

  @override
  Future<String?> getPlatformVersion() => Future.value('42');
}

class ExtendsFlutterQrScannerPlatform extends FlutterQrScannerPlatform {}

void main() {
  final FlutterQrScannerPlatform initialPlatform =
      FlutterQrScannerPlatform.instance;

  test('$MethodChannelFlutterQrScanner is the default instance', () {
    expect(initialPlatform, isInstanceOf<MethodChannelFlutterQrScanner>());
  });

  test(
    'default FlutterQrScannerPlatform startScan() throws UnimplementedError',
    () {
      final platform = ExtendsFlutterQrScannerPlatform();
      expect(() => platform.startScan(), throwsUnimplementedError);
    },
  );

  group('FlutterQrScanner facade with MockPlatform', () {
    late MockFlutterQrScannerPlatform fakePlatform;

    setUp(() {
      fakePlatform = MockFlutterQrScannerPlatform();
      FlutterQrScannerPlatform.instance = fakePlatform;
    });

    tearDown(() {
      FlutterQrScannerPlatform.instance = initialPlatform;
    });

    test('startScan returns scanned string value on success', () async {
      fakePlatform.scanResult = 'https://flutter.dev';
      fakePlatform.exceptionToThrow = null;

      final result = await FlutterQrScanner.startScan();
      expect(result, 'https://flutter.dev');
    });

    test('startScan returns null on user cancellation', () async {
      fakePlatform.scanResult = null;
      fakePlatform.exceptionToThrow = null;

      final result = await FlutterQrScanner.startScan();
      expect(result, isNull);
    });

    test('startScan throws CameraPermissionDeniedException', () async {
      fakePlatform.exceptionToThrow = const CameraPermissionDeniedException(
        'Camera permission was denied.',
      );

      expect(
        () => FlutterQrScanner.startScan(),
        throwsA(
          isA<CameraPermissionDeniedException>().having(
            (e) => e.message,
            'message',
            'Camera permission was denied.',
          ),
        ),
      );
    });

    test('startScan throws CameraUnavailableException', () async {
      fakePlatform.exceptionToThrow = const CameraUnavailableException(
        'No camera present.',
      );

      expect(
        () => FlutterQrScanner.startScan(),
        throwsA(
          isA<CameraUnavailableException>().having(
            (e) => e.message,
            'message',
            'No camera present.',
          ),
        ),
      );
    });

    test('startScan throws ScannerAlreadyInProgressException', () async {
      fakePlatform.exceptionToThrow = const ScannerAlreadyInProgressException(
        'Scan already running.',
      );

      expect(
        () => FlutterQrScanner.startScan(),
        throwsA(
          isA<ScannerAlreadyInProgressException>().having(
            (e) => e.message,
            'message',
            'Scan already running.',
          ),
        ),
      );
    });

    test(
      'startScan throws ScannerExecutionException on unknown error',
      () async {
        fakePlatform.exceptionToThrow = const ScannerExecutionException(
          'Native execution failure.',
          code: 'EXEC_FAIL',
        );

        expect(
          () => FlutterQrScanner.startScan(),
          throwsA(
            isA<ScannerExecutionException>()
                .having(
                  (e) => e.message,
                  'message',
                  'Native execution failure.',
                )
                .having((e) => e.code, 'code', 'EXEC_FAIL'),
          ),
        );
      },
    );

    test(
      'scan() alias delegates to startScan() for both success and cancel',
      () async {
        fakePlatform.scanResult = 'BARCODE_128_PAYLOAD';
        fakePlatform.exceptionToThrow = null;
        expect(await FlutterQrScanner.scan(), 'BARCODE_128_PAYLOAD');

        fakePlatform.scanResult = null;
        expect(await FlutterQrScanner.scan(), isNull);
      },
    );
  });

  group('FlutterQrScannerException hierarchy value equality and toString', () {
    test('CameraPermissionDeniedException equality and default values', () {
      const ex1 = CameraPermissionDeniedException();
      const ex2 = CameraPermissionDeniedException(
        'Camera permission was denied.',
      );
      expect(ex1, equals(ex2));
      expect(ex1.hashCode, equals(ex2.hashCode));
      expect(ex1.code, 'PERMISSION_DENIED');
      expect(
        ex1.toString(),
        'CameraPermissionDeniedException(PERMISSION_DENIED): Camera permission was denied.',
      );
    });

    test('CameraUnavailableException equality and default values', () {
      const ex1 = CameraUnavailableException();
      const ex2 = CameraUnavailableException('No camera device is available.');
      expect(ex1, equals(ex2));
      expect(ex1.hashCode, equals(ex2.hashCode));
      expect(ex1.code, 'CAMERA_UNAVAILABLE');
      expect(
        ex1.toString(),
        'CameraUnavailableException(CAMERA_UNAVAILABLE): No camera device is available.',
      );
    });

    test('ScannerAlreadyInProgressException equality and default values', () {
      const ex1 = ScannerAlreadyInProgressException();
      const ex2 = ScannerAlreadyInProgressException(
        'A scan is already in progress.',
      );
      expect(ex1, equals(ex2));
      expect(ex1.hashCode, equals(ex2.hashCode));
      expect(ex1.code, 'ALREADY_SCANNING');
      expect(
        ex1.toString(),
        'ScannerAlreadyInProgressException(ALREADY_SCANNING): A scan is already in progress.',
      );
    });

    test('ScannerExecutionException preserves code, message, and details', () {
      const details = {'errorId': 101};
      const ex1 = ScannerExecutionException(
        'Unknown failure',
        code: 'ERR_101',
        details: details,
      );
      const ex2 = ScannerExecutionException(
        'Unknown failure',
        code: 'ERR_101',
        details: details,
      );
      expect(ex1, equals(ex2));
      expect(ex1.hashCode, equals(ex2.hashCode));
      expect(ex1.code, 'ERR_101');
      expect(ex1.details, details);
      expect(
        ex1.toString(),
        'ScannerExecutionException(ERR_101): Unknown failure',
      );
    });

    test('FlutterQrScannerException toString without code', () {
      const ex = FlutterQrScannerException('General failure');
      expect(ex.toString(), 'FlutterQrScannerException: General failure');
      expect(ex.code, isNull);
      expect(ex.details, isNull);
    });
  });
}
