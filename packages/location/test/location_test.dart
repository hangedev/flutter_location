import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:location/location.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

import 'location_test.mocks.dart';

@GenerateMocks([Location])
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Location originalInstance;
  late MockLocation mockLocation;
  late Location location;

  setUp(() {
    originalInstance = Location.instance;
    mockLocation = MockLocation();
    Location.instance = mockLocation;
    location = Location();
  });

  tearDown(() {
    Location.instance = originalInstance;
    resetMockitoState();
  });

  group('Location forwarding', () {
    test('changeSettings should forward and return result', () async {
      when(mockLocation.changeSettings()).thenAnswer((_) async => true);

      final result = await location.changeSettings();
      expect(result, isTrue);
      verify(mockLocation.changeSettings()).called(1);
    });

    test('isBackgroundModeEnabled should forward and return result', () async {
      when(mockLocation.isBackgroundModeEnabled()).thenAnswer((_) async => true);

      final result = await location.isBackgroundModeEnabled();
      expect(result, isTrue);
      verify(mockLocation.isBackgroundModeEnabled()).called(1);
    });

    test('enableBackgroundMode should forward and return result', () async {
      when(mockLocation.enableBackgroundMode()).thenAnswer((_) async => true);

      final result = await location.enableBackgroundMode();
      expect(result, isTrue);
      verify(mockLocation.enableBackgroundMode()).called(1);
    });

    test('getLocation should forward and return LocationData', () async {
      final expected = LocationData.fromMap(<String, dynamic>{
        'latitude': 1.0,
        'longitude': 2.0,
      });
      when(mockLocation.getLocation()).thenAnswer((_) async => expected);

      final result = await location.getLocation();
      expect(result.latitude, 1.0);
      verify(mockLocation.getLocation()).called(1);
    });

    test('hasPermission should forward and return PermissionStatus', () async {
      when(mockLocation.hasPermission())
          .thenAnswer((_) async => PermissionStatus.granted);

      final result = await location.hasPermission();
      expect(result, PermissionStatus.granted);
      verify(mockLocation.hasPermission()).called(1);
    });

    test('requestPermission should forward and return PermissionStatus', () async {
      when(mockLocation.requestPermission())
          .thenAnswer((_) async => PermissionStatus.denied);

      final result = await location.requestPermission();
      expect(result, PermissionStatus.denied);
      verify(mockLocation.requestPermission()).called(1);
    });

    test('serviceEnabled should forward and return result', () async {
      when(mockLocation.serviceEnabled()).thenAnswer((_) async => false);

      final result = await location.serviceEnabled();
      expect(result, isFalse);
      verify(mockLocation.serviceEnabled()).called(1);
    });

    test('requestService should forward and return result', () async {
      when(mockLocation.requestService()).thenAnswer((_) async => false);

      final result = await location.requestService();
      expect(result, isFalse);
      verify(mockLocation.requestService()).called(1);
    });

    test('changeNotificationOptions should forward', () async {
      when(mockLocation.changeNotificationOptions()).thenAnswer((_) async => null);

      final result = await location.changeNotificationOptions();
      expect(result, isNull);
      verify(mockLocation.changeNotificationOptions()).called(1);
    });
  });

  group('onLocationChanged', () {
    late StreamController<LocationData> controller;

    setUp(() {
      controller = StreamController<LocationData>();
      when(mockLocation.onLocationChanged).thenAnswer((_) => controller.stream);
    });

    tearDown(() => controller.close());

    test('should receive values from underlying stream', () async {
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
  });
}
