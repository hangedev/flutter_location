import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:location/location.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

import 'location_test.mocks.dart';

@GenerateMocks([Location])
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late MockLocation mockLocation;
  late Location location;
  final defaultInstance = Location.instance;

  setUp(() {
    mockLocation = MockLocation();
    Location.instance = mockLocation;
    location = Location();
  });

  tearDown(() {
    resetMockitoState();
    Location.instance = defaultInstance;
  });

  group('Singleton Pattern', () {
    test('should return same instance when factory constructor is called', () {
      final instance1 = Location();
      final instance2 = Location();
      expect(identical(instance1, instance2), true);
    });

    test('should allow setting a custom instance for testing', () {
      final anotherMock = MockLocation();
      Location.instance = anotherMock;
      expect(identical(Location.instance, anotherMock), true);
      // Restore for other tests
      Location.instance = mockLocation;
    });
  });

  group('changeSettings', () {
    test('should delegate to the underlying platform instance', () async {
      when(location.changeSettings()).thenAnswer((_) => Future.value(true));

      await location.changeSettings();
      verify(mockLocation.changeSettings()).called(1);
    });
  });

  group('isBackgroundModeEnabled', () {
    test('should delegate to the underlying platform instance', () async {
      when(location.isBackgroundModeEnabled())
          .thenAnswer((_) => Future.value(true));

      await location.isBackgroundModeEnabled();
      verify(mockLocation.isBackgroundModeEnabled()).called(1);
    });
  });

  group('enableBackgroundMode', () {
    test('should delegate to the underlying platform instance', () async {
      when(location.enableBackgroundMode())
          .thenAnswer((_) => Future.value(true));

      await location.enableBackgroundMode();
      verify(mockLocation.enableBackgroundMode()).called(1);
    });
  });

  group('getLocation', () {
    test('should delegate to the underlying platform instance', () async {
      when(location.getLocation())
          .thenAnswer((_) => Future.value(LocationData.fromMap({})));

      await location.getLocation();
      verify(mockLocation.getLocation()).called(1);
    });
  });

  group('hasPermission', () {
    test('should delegate to the underlying platform instance', () async {
      when(location.hasPermission())
          .thenAnswer((_) => Future.value(PermissionStatus.granted));

      await location.hasPermission();
      verify(mockLocation.hasPermission()).called(1);
    });
  });

  group('requestPermission', () {
    test('should delegate to the underlying platform instance', () async {
      when(location.requestPermission())
          .thenAnswer((_) => Future.value(PermissionStatus.granted));

      await location.requestPermission();
      verify(mockLocation.requestPermission()).called(1);
    });
  });

  group('serviceEnabled', () {
    test('should delegate to the underlying platform instance', () async {
      when(location.serviceEnabled()).thenAnswer((_) => Future.value(true));

      await location.serviceEnabled();
      verify(mockLocation.serviceEnabled()).called(1);
    });
  });

  group('requestService', () {
    test('should delegate to the underlying platform instance', () async {
      when(location.requestService()).thenAnswer((_) => Future.value(true));

      await location.requestService();
      verify(mockLocation.requestService()).called(1);
    });
  });

  group('changeNotificationOptions', () {
    test('should delegate to the underlying platform instance', () async {
      when(location.changeNotificationOptions())
          .thenAnswer((_) => Future.value());

      await location.changeNotificationOptions();
      verify(mockLocation.changeNotificationOptions()).called(1);
    });
  });

  group('onLocationChanged', () {
    late StreamController<LocationData> controller;

    setUp(() {
      controller = StreamController<LocationData>();
      when(location.onLocationChanged).thenAnswer((_) => controller.stream);
    });

    tearDown(() => controller.close());

    test('should receive location values from stream', () async {
      controller
        ..add(
          LocationData.fromMap(<String, dynamic>{
            'latitude': 48.8534,
            'longitude': 2.3488,
          }),
        )
        ..add(
          LocationData.fromMap(<String, dynamic>{
            'latitude': 42.8534,
            'longitude': 23.3488,
          }),
        );
      unawaited(controller.close());

      await expectLater(
        location.onLocationChanged,
        emitsInOrder(
          <dynamic>[
            LocationData.fromMap(<String, dynamic>{
              'latitude': 48.8534,
              'longitude': 2.3488,
            }),
            LocationData.fromMap(<String, dynamic>{
              'latitude': 42.8534,
              'longitude': 23.3488,
            }),
            emitsDone,
          ],
        ),
      );
    });

    test('should receive complete location data with all 16 fields from stream', () async {
      final completeData = LocationData.fromMap(<String, dynamic>{
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

      controller.add(completeData);
      unawaited(controller.close());

      final received = await location.onLocationChanged.first;
      expect(received.latitude, 48.8534);
      expect(received.longitude, 2.3488);
      expect(received.accuracy, 10.5);
      expect(received.altitude, 35.0);
      expect(received.speed, 1.2);
      expect(received.speedAccuracy, 0.5);
      expect(received.heading, 180.0);
      expect(received.time, 1609459200000.0);
      expect(received.isMock, true);
      expect(received.verticalAccuracy, 3.0);
      expect(received.headingAccuracy, 2.0);
      expect(received.elapsedRealtimeNanos, 123456789.0);
      expect(received.elapsedRealtimeUncertaintyNanos, 100.0);
      expect(received.satelliteNumber, 12);
      expect(received.provider, 'gps');
    });
  });
}
