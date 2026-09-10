import 'dart:async';
import 'dart:ui';

import 'package:async/async.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:location/location.dart';
import 'package:location_platform_interface/location_platform_interface.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

import 'coverage_test.mocks.dart';

@GenerateMocks([EventChannel])
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Location singleton', () {
    late Location originalInstance;

    setUp(() {
      originalInstance = Location.instance;
    });

    tearDown(() {
      Location.instance = originalInstance;
    });

    test('should expose singleton instance', () {
      expect(Location.instance, isA<Location>());
      expect(identical(Location(), Location.instance), isTrue);
    });
  });

  group('LocationData fields', () {
    test('fromMap should parse all supported fields', () {
      final data = LocationData.fromMap(<String, dynamic>{
        'latitude': 48.8534,
        'longitude': 2.3488,
        'accuracy': 12.5,
        'altitude': 35.0,
        'speed': 1.2,
        'speed_accuracy': 0.5,
        'heading': 90.0,
        'time': 1_700_000_000_000.0,
        'isMock': 1,
        'verticalAccuracy': 3.0,
        'headingAccuracy': 2.0,
        'elapsedRealtimeNanos': 1000.0,
        'elapsedRealtimeUncertaintyNanos': 10.0,
        'satelliteNumber': 8,
        'provider': 'gps',
      });

      expect(data.latitude, 48.8534);
      expect(data.longitude, 2.3488);
      expect(data.accuracy, 12.5);
      expect(data.altitude, 35.0);
      expect(data.speed, 1.2);
      expect(data.speedAccuracy, 0.5);
      expect(data.heading, 90.0);
      expect(data.time, 1_700_000_000_000.0);
      expect(data.isMock, isTrue);
      expect(data.verticalAccuracy, 3.0);
      expect(data.headingAccuracy, 2.0);
      expect(data.elapsedRealtimeNanos, 1000.0);
      expect(data.elapsedRealtimeUncertaintyNanos, 10.0);
      expect(data.satelliteNumber, 8);
      expect(data.provider, 'gps');
    });

    test('fromMap should tolerate empty map boundary values', () {
      final data = LocationData.fromMap(<String, dynamic>{});
      expect(data.latitude, isNull);
      expect(data.longitude, isNull);
      expect(data.accuracy, isNull);
    });
  });

  group('AndroidNotificationData fields', () {
    test('fromMap should expose channelId and notificationId', () {
      final notification = AndroidNotificationData.fromMap(<String, dynamic>{
        'channelId': 'location_channel',
        'notificationId': 42,
      });

      expect(notification.channelId, 'location_channel');
      expect(notification.notificationId, 42);
    });
  });

  group('MethodChannelLocation', () {
    final binding = TestWidgetsFlutterBinding.ensureInitialized();
    MethodChannel? methodChannel;
    MockEventChannel? eventChannel;
    late MethodChannelLocation channelLocation;
    final log = <MethodCall>[];

    setUp(() {
      methodChannel = const MethodChannel('lyokone/location');
      eventChannel = MockEventChannel();
      channelLocation = MethodChannelLocation.private(methodChannel, eventChannel);
      log.clear();

      binding.defaultBinaryMessenger.setMockMethodCallHandler(
        methodChannel!,
        (methodCall) async {
          log.add(methodCall);
          switch (methodCall.method) {
            case 'getLocation':
              return <String, dynamic>{
                'latitude': 48.8534,
                'longitude': 2.3488,
                'accuracy': 5.0,
                'altitude': 10.0,
                'speed': 1.0,
                'heading': 180.0,
                'time': 1_700_000_000_000.0,
              };
            case 'changeSettings':
              return 1;
            case 'isBackgroundModeEnabled':
              return 1;
            case 'enableBackgroundMode':
              return 1;
            case 'hasPermission':
            case 'requestPermission':
              return 1;
            case 'serviceEnabled':
              return 1;
            case 'requestService':
              return 0;
            case 'changeNotificationOptions':
              return <String, dynamic>{
                'channelId': 'test',
                'notificationId': 1,
              };
            default:
              return null;
          }
        },
      );
    });

    tearDown(() {
      binding.defaultBinaryMessenger.setMockMethodCallHandler(methodChannel!, null);
    });

    test('changeSettings should return true and send arguments', () async {
      final result = await channelLocation.changeSettings(
        accuracy: LocationAccuracy.high,
        interval: 2000,
        distanceFilter: 5,
        pausesLocationUpdatesAutomatically: false,
      );
      expect(result, isTrue);
      expect(log.last.method, 'changeSettings');
    });

    test('isBackgroundModeEnabled should return true', () async {
      expect(await channelLocation.isBackgroundModeEnabled(), isTrue);
    });

    test('enableBackgroundMode should return true', () async {
      expect(await channelLocation.enableBackgroundMode(enable: true), isTrue);
    });

    test('getLocation should return LocationData', () async {
      final location = await channelLocation.getLocation();
      expect(location.latitude, 48.8534);
      expect(location.altitude, 10.0);
    });

    test('hasPermission should return granted', () async {
      expect(await channelLocation.hasPermission(), PermissionStatus.granted);
    });

    test('requestPermission should return granted', () async {
      expect(await channelLocation.requestPermission(), PermissionStatus.granted);
    });

    test('serviceEnabled should return true', () async {
      expect(await channelLocation.serviceEnabled(), isTrue);
    });

    test('requestService should return false when native returns 0', () async {
      expect(await channelLocation.requestService(), isFalse);
    });

    test('changeNotificationOptions should complete on non-Android', () async {
      final notification = await channelLocation.changeNotificationOptions(
        channelName: 'channel',
        title: 'title',
        color: const Color(0xFF0000FF),
      );
      // Dart API returns null on non-Android without invoking the platform channel.
      expect(notification, isNull);
    });

    group('onLocationChanged', () {
      late StreamController<Map<String, dynamic>> controller;

      setUp(() {
        controller = StreamController<Map<String, dynamic>>();
        when(eventChannel!.receiveBroadcastStream())
            .thenAnswer((_) => controller.stream);
      });

      tearDown(() async {
        await controller.close();
      });

      test('should emit location updates from event channel', () async {
        final queue = StreamQueue<LocationData>(channelLocation.onLocationChanged);
        controller.add(<String, dynamic>{
          'latitude': 1.0,
          'longitude': 2.0,
          'accuracy': 3.0,
        });
        final data = await queue.next;
        expect(data.latitude, 1.0);
        await queue.cancel();
      });
    });

    group('exception scenarios', () {
      test('hasPermission should throw on unknown native code', () async {
        binding.defaultBinaryMessenger.setMockMethodCallHandler(
          methodChannel!,
          (_) async => 99,
        );
        await expectLater(
          channelLocation.hasPermission(),
          throwsA(isA<PlatformException>()),
        );
      });

      test('getLocation should throw when native returns PlatformException', () async {
        binding.defaultBinaryMessenger.setMockMethodCallHandler(
          methodChannel!,
          (_) async {
            throw PlatformException(code: 'PERMISSION_DENIED');
          },
        );
        await expectLater(
          channelLocation.getLocation(),
          throwsA(isA<PlatformException>()),
        );
      });
    });

    group('concurrency scenarios', () {
      test('parallel getLocation calls should complete independently', () async {
        final results = await Future.wait([
          channelLocation.getLocation(),
          channelLocation.getLocation(),
        ]);
        expect(results, hasLength(2));
        expect(results.first.latitude, 48.8534);
      });
    });
  });
}
