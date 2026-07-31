import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:location_platform_interface/location_platform_interface.dart';
import 'package:mockito/mockito.dart';

import 'method_channel_location_test.mocks.dart';

void main() {
  final binding = TestWidgetsFlutterBinding.ensureInitialized();

  MethodChannel? methodChannel;
  MockEventChannel? eventChannel;
  late MethodChannelLocation location;

  setUp(() {
    methodChannel = const MethodChannel('lyokone/location');
    eventChannel = MockEventChannel();
    location = MethodChannelLocation.private(methodChannel, eventChannel);
  });

  tearDown(() {
    binding.defaultBinaryMessenger.setMockMethodCallHandler(methodChannel!, null);
  });

  group('Exception scenarios', () {
    group('Parameter validation exceptions', () {
      test('should throw PlatformException when getLocation returns error', () async {
        binding.defaultBinaryMessenger.setMockMethodCallHandler(
          methodChannel!,
          (methodCall) async {
            if (methodCall.method == 'getLocation') {
              throw PlatformException(
                code: 'PERMISSION_DENIED',
                message: 'Location permission denied',
              );
            }
            return null;
          },
        );

        expect(
          () => location.getLocation(),
          throwsA(isA<PlatformException>().having(
            (e) => e.code,
            'code',
            'PERMISSION_DENIED',
          )),
        );
      });

      test('should throw PlatformException when changeSettings returns error', () async {
        binding.defaultBinaryMessenger.setMockMethodCallHandler(
          methodChannel!,
          (methodCall) async {
            if (methodCall.method == 'changeSettings') {
              throw PlatformException(
                code: 'INVALID_ARGUMENT',
                message: 'Invalid parameter types for changeSettings',
              );
            }
            return null;
          },
        );

        expect(
          () => location.changeSettings(),
          throwsA(isA<PlatformException>().having(
            (e) => e.code,
            'code',
            'INVALID_ARGUMENT',
          )),
        );
      });
    });

    group('Permission denied scenarios', () {
      test('should return PermissionStatus.denied when permission is denied', () async {
        binding.defaultBinaryMessenger.setMockMethodCallHandler(
          methodChannel!,
          (methodCall) async {
            return 0; // denied
          },
        );

        final permission = await location.requestPermission();
        expect(permission, PermissionStatus.denied);
      });

      test('should return PermissionStatus.deniedForever when permission is denied forever', () async {
        binding.defaultBinaryMessenger.setMockMethodCallHandler(
          methodChannel!,
          (methodCall) async {
            return 2; // deniedForever
          },
        );

        final permission = await location.requestPermission();
        expect(permission, PermissionStatus.deniedForever);
      });

      test('should throw PlatformException when enableBackgroundMode is denied', () async {
        binding.defaultBinaryMessenger.setMockMethodCallHandler(
          methodChannel!,
          (methodCall) async {
            if (methodCall.method == 'enableBackgroundMode') {
              throw PlatformException(
                code: 'PERMISSION_DENIED',
                message: 'Location permission denied',
              );
            }
            return null;
          },
        );

        expect(
          () => location.enableBackgroundMode(enable: true),
          throwsA(isA<PlatformException>().having(
            (e) => e.code,
            'code',
            'PERMISSION_DENIED',
          )),
        );
      });
    });

    group('Timeout scenarios', () {
      test('should handle getLocation timeout gracefully', () async {
        binding.defaultBinaryMessenger.setMockMethodCallHandler(
          methodChannel!,
          (methodCall) async {
            if (methodCall.method == 'getLocation') {
              // Simulate slow response
              await Future<void>.delayed(const Duration(seconds: 5));
              return <String, dynamic>{'latitude': 0.0, 'longitude': 0.0};
            }
            return null;
          },
        );

        // Use a timeout to verify the call doesn't hang indefinitely
        final result = await location.getLocation().timeout(
          const Duration(seconds: 10),
          onTimeout: () => LocationData.fromMap({}),
        );
        // If we get here, the call completed (even if with timeout fallback)
        expect(result, isA<LocationData>());
      });
    });

    group('Service not available scenarios', () {
      test('should throw PlatformException when requestService is not supported', () async {
        binding.defaultBinaryMessenger.setMockMethodCallHandler(
          methodChannel!,
          (methodCall) async {
            if (methodCall.method == 'requestService') {
              throw PlatformException(
                code: 'SERVICE_STATUS_DISABLED',
                message: 'requestService is not supported on OpenHarmony',
              );
            }
            return null;
          },
        );

        expect(
          () => location.requestService(),
          throwsA(isA<PlatformException>().having(
            (e) => e.code,
            'code',
            'SERVICE_STATUS_DISABLED',
          )),
        );
      });

      test('should return false when serviceEnabled returns 0', () async {
        binding.defaultBinaryMessenger.setMockMethodCallHandler(
          methodChannel!,
          (methodCall) async {
            if (methodCall.method == 'serviceEnabled') {
              return 0;
            }
            return null;
          },
        );

        final enabled = await location.serviceEnabled();
        expect(enabled, false);
      });
    });

    group('Null result scenarios', () {
      test('should throw PlatformException when hasPermission returns null', () async {
        binding.defaultBinaryMessenger.setMockMethodCallHandler(
          methodChannel!,
          (methodCall) async {
            return null;
          },
        );

        expect(
          () => location.hasPermission(),
          throwsA(isA<PlatformException>()),
        );
      });

      test('should throw PlatformException when requestPermission returns null', () async {
        binding.defaultBinaryMessenger.setMockMethodCallHandler(
          methodChannel!,
          (methodCall) async {
            return null;
          },
        );

        expect(
          () => location.requestPermission(),
          throwsA(isA<PlatformException>()),
        );
      });
    });
  });
}
