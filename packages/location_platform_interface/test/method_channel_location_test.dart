import 'dart:async';

import 'package:async/async.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:location_platform_interface/location_platform_interface.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

import 'method_channel_location_test.mocks.dart';

@GenerateMocks([EventChannel])
void main() {
  final binding = TestWidgetsFlutterBinding.ensureInitialized();

  MethodChannel? methodChannel;
  MockEventChannel? eventChannel;
  late MethodChannelLocation location;

  final log = <MethodCall>[];

  setUp(() {
    methodChannel = const MethodChannel('lyokone/location');
    eventChannel = MockEventChannel();
    location = MethodChannelLocation.private(methodChannel, eventChannel);

    binding.defaultBinaryMessenger.setMockMethodCallHandler(
      methodChannel!,
      (methodCall) async {
        log.add(methodCall);
        switch (methodCall.method) {
          case 'getLocation':
            return <String, dynamic>{
              'latitude': 48.8534,
              'longitude': 2.3488,
            };
          case 'changeSettings':
            return 1;
          case 'serviceEnabled':
            return 1;
          case 'requestService':
            return 1;
          case 'isBackgroundModeEnabled':
            return 1;
          case 'enableBackgroundMode':
            return 1;
          case 'changeNotificationOptions':
            return null;
          default:
            return '';
        }
      },
    );

    log.clear();
  });

  tearDown(() {
    binding.defaultBinaryMessenger.setMockMethodCallHandler(methodChannel!, null);
    log.clear();
  });

  group('getLocation', () {
    test('getLocation should convert results correctly', () async {
      final receivedLocation = await location.getLocation();
      expect(receivedLocation.latitude, 48.8534);
      expect(receivedLocation.longitude, 2.3488);
    });

    test('getLocation with complete location data (all fields)', () async {
      binding.defaultBinaryMessenger.setMockMethodCallHandler(
        methodChannel!,
        (methodCall) async {
          if (methodCall.method == 'getLocation') {
            return <String, dynamic>{
              'latitude': 48.8534,
              'longitude': 2.3488,
              'accuracy': 10.5,
              'altitude': 35.0,
              'speed': 1.2,
              'speed_accuracy': 0.5,
              'heading': 180.0,
              'time': 1609459200000.0,
              'isMock': 1,
              'verticalAccuracy': 3.0,
              'headingAccuracy': 2.0,
              'elapsedRealtimeNanos': 123456789.0,
              'elapsedRealtimeUncertaintyNanos': 100.0,
              'satelliteNumber': 12,
              'provider': 'gps',
            };
          }
          return null;
        },
      );

      final receivedLocation = await location.getLocation();
      expect(receivedLocation.latitude, 48.8534);
      expect(receivedLocation.longitude, 2.3488);
      expect(receivedLocation.accuracy, 10.5);
      expect(receivedLocation.altitude, 35.0);
      expect(receivedLocation.speed, 1.2);
      expect(receivedLocation.speedAccuracy, 0.5);
      expect(receivedLocation.heading, 180.0);
      expect(receivedLocation.time, 1609459200000.0);
      expect(receivedLocation.isMock, true);
      expect(receivedLocation.verticalAccuracy, 3.0);
      expect(receivedLocation.headingAccuracy, 2.0);
      expect(receivedLocation.elapsedRealtimeNanos, 123456789.0);
      expect(receivedLocation.elapsedRealtimeUncertaintyNanos, 100.0);
      expect(receivedLocation.satelliteNumber, 12);
      expect(receivedLocation.provider, 'gps');
    });

    test('getLocation null result throws PlatformException', () async {
      binding.defaultBinaryMessenger.setMockMethodCallHandler(
        methodChannel!,
        (methodCall) async {
          return null;
        },
      );

      expect(
        () => location.getLocation(),
        throwsA(isA<PlatformException>().having(
          (e) => e.code,
          'code',
          'NULL_RESULT',
        )),
      );
    });
  });

  test('changeSettings passes parameters correctly', () async {
    await location.changeSettings();
    expect(log, <Matcher>[
      isMethodCall(
        'changeSettings',
        arguments: <String, dynamic>{
          'accuracy': LocationAccuracy.high.index,
          'scenario': LocationScenario.unset.index,
          'interval': 1000,
          'distanceFilter': 0,
          'distanceInterval': 0,
        },
      ),
    ]);
  });

  group('Service Status', () {
    test('serviceEnabled should convert results correctly', () async {
      final result = await location.serviceEnabled();
      expect(result, true);
    });

    test('serviceEnabled returns false when result is 0', () async {
      binding.defaultBinaryMessenger.setMockMethodCallHandler(
        methodChannel!,
        (methodCall) async {
          return 0;
        },
      );
      final result = await location.serviceEnabled();
      expect(result, false);
    });

    test('requestService should convert to string correctly', () async {
      final result = await location.requestService();
      expect(result, true);
    });
  });

  group('Background Mode', () {
    test('isBackgroundModeEnabled returns true when result is 1', () async {
      final result = await location.isBackgroundModeEnabled();
      expect(result, true);
    });

    test('isBackgroundModeEnabled returns false when result is 0', () async {
      binding.defaultBinaryMessenger.setMockMethodCallHandler(
        methodChannel!,
        (methodCall) async {
          if (methodCall.method == 'isBackgroundModeEnabled') {
            return 0;
          }
          return '';
        },
      );
      final result = await location.isBackgroundModeEnabled();
      expect(result, false);
    });

    test('enableBackgroundMode passes enable parameter correctly', () async {
      await location.enableBackgroundMode(enable: true);
      expect(log, <Matcher>[
        isMethodCall(
          'enableBackgroundMode',
          arguments: <String, dynamic>{'enable': true},
        ),
      ]);
    });

    test('enableBackgroundMode returns true when result is 1', () async {
      final result = await location.enableBackgroundMode(enable: true);
      expect(result, true);
    });

    test('enableBackgroundMode returns false when result is 0', () async {
      binding.defaultBinaryMessenger.setMockMethodCallHandler(
        methodChannel!,
        (methodCall) async {
          if (methodCall.method == 'enableBackgroundMode') {
            return 0;
          }
          return '';
        },
      );
      final result = await location.enableBackgroundMode(enable: false);
      expect(result, false);
    });
  });

  group('changeNotificationOptions', () {
    test('returns null on non-Android', () async {
      // changeNotificationOptions checks Platform.isAndroid and returns null
      // on non-Android platforms. Since tests run on Windows, this should
      // return null without invoking the method channel.
      final result = await location.changeNotificationOptions(
        channelName: 'test_channel',
        title: 'Test Title',
        iconName: 'test_icon',
      );
      expect(result, isNull);
    });
  });

  group('Permission Status', () {
    test('Should convert int to correct Permission Status', () async {
      binding.defaultBinaryMessenger.setMockMethodCallHandler(
        methodChannel!,
        (methodCall) async {
          return 0;
        },
      );
      var receivedPermission = await location.hasPermission();
      expect(receivedPermission, PermissionStatus.denied);
      receivedPermission = await location.requestPermission();
      expect(receivedPermission, PermissionStatus.denied);

      binding.defaultBinaryMessenger.setMockMethodCallHandler(
        methodChannel!,
        (methodCall) async {
          return 1;
        },
      );
      receivedPermission = await location.hasPermission();
      expect(receivedPermission, PermissionStatus.granted);
      receivedPermission = await location.requestPermission();
      expect(receivedPermission, PermissionStatus.granted);

      binding.defaultBinaryMessenger.setMockMethodCallHandler(
        methodChannel!,
        (methodCall) async {
          return 2;
        },
      );
      receivedPermission = await location.hasPermission();
      expect(receivedPermission, PermissionStatus.deniedForever);
      receivedPermission = await location.requestPermission();
      expect(receivedPermission, PermissionStatus.deniedForever);

      binding.defaultBinaryMessenger.setMockMethodCallHandler(
        methodChannel!,
        (methodCall) async {
          return 3;
        },
      );
      receivedPermission = await location.hasPermission();
      expect(receivedPermission, PermissionStatus.grantedLimited);
      receivedPermission = await location.requestPermission();
      expect(receivedPermission, PermissionStatus.grantedLimited);
    });

    test('Should throw if other message is sent', () async {
      binding.defaultBinaryMessenger.setMockMethodCallHandler(
        methodChannel!,
        (methodCall) async {
          return 12;
        },
      );
      try {
        await location.hasPermission();
      } on PlatformException catch (err) {
        expect(err.code, 'UNKNOWN_NATIVE_MESSAGE');
      }
      try {
        await location.requestPermission();
      } on PlatformException catch (err) {
        expect(err.code, 'UNKNOWN_NATIVE_MESSAGE');
      }
    });
  });

  group('Location Updates', () {
    late StreamController<Map<String, dynamic>> controller;

    setUp(() {
      controller = StreamController<Map<String, dynamic>>();
      when(eventChannel!.receiveBroadcastStream())
          .thenAnswer((invoke) => controller.stream);
    });

    tearDown(() {
      controller.close();
    });

    test('call receiveBrodcastStream once', () {
      location
        ..onLocationChanged
        ..onLocationChanged
        ..onLocationChanged;
      verify(eventChannel!.receiveBroadcastStream()).called(1);
    });

    test('should receive values', () async {
      final queue = StreamQueue<LocationData>(location.onLocationChanged);

      controller.add(<String, dynamic>{
        'latitude': 48.8534,
        'longitude': 2.3488,
      });
      var data = await queue.next;
      expect(data.latitude, 48.8534);
      expect(data.longitude, 2.3488);

      controller.add(<String, dynamic>{
        'latitude': 42.8534,
        'longitude': 23.3488,
      });
      data = await queue.next;
      expect(data.latitude, 42.8534);
      expect(data.longitude, 23.3488);
    });

    test('should receive complete location data via stream', () async {
      final queue = StreamQueue<LocationData>(location.onLocationChanged);

      controller.add(<String, dynamic>{
        'latitude': 48.8534,
        'longitude': 2.3488,
        'accuracy': 10.5,
        'altitude': 35.0,
        'speed': 1.2,
        'speed_accuracy': 0.5,
        'heading': 180.0,
        'time': 1609459200000.0,
        'isMock': 1,
        'verticalAccuracy': 3.0,
        'headingAccuracy': 2.0,
        'elapsedRealtimeNanos': 123456789.0,
        'elapsedRealtimeUncertaintyNanos': 100.0,
        'satelliteNumber': 12,
        'provider': 'gps',
      });

      final data = await queue.next;
      expect(data.latitude, 48.8534);
      expect(data.longitude, 2.3488);
      expect(data.accuracy, 10.5);
      expect(data.altitude, 35.0);
      expect(data.speed, 1.2);
      expect(data.speedAccuracy, 0.5);
      expect(data.heading, 180.0);
      expect(data.time, 1609459200000.0);
      expect(data.isMock, true);
      expect(data.verticalAccuracy, 3.0);
      expect(data.headingAccuracy, 2.0);
      expect(data.elapsedRealtimeNanos, 123456789.0);
      expect(data.elapsedRealtimeUncertaintyNanos, 100.0);
      expect(data.satelliteNumber, 12);
      expect(data.provider, 'gps');
    });
  });
}
