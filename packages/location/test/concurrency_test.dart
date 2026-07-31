import 'dart:async';

import 'package:async/async.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:location/location.dart';
import 'package:mockito/mockito.dart';

import 'location_test.mocks.dart';

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

  group('Concurrent getLocation calls', () {
    test('should handle multiple simultaneous getLocation requests', () async {
      when(location.getLocation()).thenAnswer(
        (_) => Future.value(
          LocationData.fromMap({
            'latitude': 48.8534,
            'longitude': 2.3488,
          }),
        ),
      );

      // Fire multiple getLocation calls concurrently
      final futures = List.generate(5, (_) => location.getLocation());
      final results = await Future.wait(futures);

      expect(results.length, 5);
      for (final result in results) {
        expect(result.latitude, 48.8534);
        expect(result.longitude, 2.3488);
      }
      verify(mockLocation.getLocation()).called(5);
    });
  });

  group('Concurrent onLocationChanged listeners', () {
    test('should support multiple listeners on the same stream', () async {
      final controller = StreamController<LocationData>.broadcast();
      when(location.onLocationChanged).thenAnswer((_) => controller.stream);

      final data1 = LocationData.fromMap({'latitude': 48.0, 'longitude': 2.0});
      final data2 = LocationData.fromMap({'latitude': 42.0, 'longitude': 23.0});

      // Subscribe two listeners concurrently
      final queue1 = StreamQueue<LocationData>(location.onLocationChanged);
      final queue2 = StreamQueue<LocationData>(location.onLocationChanged);

      controller
        ..add(data1)
        ..add(data2);

      final received1a = await queue1.next;
      expect(received1a.latitude, 48.0);
      final received1b = await queue1.next;
      expect(received1b.latitude, 42.0);

      final received2a = await queue2.next;
      expect(received2a.latitude, 48.0);
      final received2b = await queue2.next;
      expect(received2b.latitude, 42.0);

      await queue1.cancel();
      await queue2.cancel();
      await controller.close();
    });
  });

  group('Concurrent changeSettings during onLocationChanged', () {
    test('should allow changeSettings while stream is active', () async {
      final controller = StreamController<LocationData>();
      when(location.onLocationChanged).thenAnswer((_) => controller.stream);
      when(location.changeSettings(
        accuracy: anyNamed('accuracy'),
        scenario: anyNamed('scenario'),
        interval: anyNamed('interval'),
        distanceFilter: anyNamed('distanceFilter'),
        distanceInterval: anyNamed('distanceInterval'),
      )).thenAnswer((_) => Future.value(true));

      // Start listening
      final subscription = location.onLocationChanged.listen((_) {});

      // Change settings while stream is active
      final result = await location.changeSettings(
        accuracy: LocationAccuracy.high,
        interval: 2000,
      );
      expect(result, true);

      await subscription.cancel();
      await controller.close();
    });
  });

  group('Rapid enableBackgroundMode toggle', () {
    test('should handle rapid enable/disable background mode calls', () async {
      when(location.enableBackgroundMode(enable: true))
          .thenAnswer((_) => Future.value(true));
      when(location.enableBackgroundMode(enable: false))
          .thenAnswer((_) => Future.value(false));

      // Rapid toggle
      final results = await Future.wait(<Future<bool>>[
        location.enableBackgroundMode(enable: true),
        location.enableBackgroundMode(enable: false),
        location.enableBackgroundMode(enable: true),
      ]);

      expect(results, [true, false, true]);
    });
  });

  group('Concurrent permission and location calls', () {
    test('should handle concurrent requestPermission and hasPermission', () async {
      when(location.hasPermission())
          .thenAnswer((_) => Future.value(PermissionStatus.granted));
      when(location.requestPermission())
          .thenAnswer((_) => Future.value(PermissionStatus.granted));

      // Call both concurrently
      final results = await Future.wait(<Future<PermissionStatus>>[
        location.hasPermission(),
        location.requestPermission(),
      ]);

      expect(results[0], PermissionStatus.granted);
      expect(results[1], PermissionStatus.granted);
    });
  });
}
