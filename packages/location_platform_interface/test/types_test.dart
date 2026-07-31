import 'package:flutter_test/flutter_test.dart';
import 'package:location_platform_interface/location_platform_interface.dart';

void main() {
  group('LocationData', () {
    test('LocationData should be correctly converted to string', () {
      final locationData = LocationData.fromMap(<String, dynamic>{
        'latitude': 42.0,
        'longitude': 2.0,
      });
      expect(
        locationData.toString(),
        'LocationData<lat: ${locationData.latitude}, long: ${locationData.longitude}>',
      );
    });

    test('LocationData should be equal if all parameters are equals', () {
      final locationData = LocationData.fromMap(<String, dynamic>{
        'latitude': 42.0,
        'longitude': 2.0,
        'accuracy': 2.0,
        'altitude': 2.0,
        'speed': 2.0,
        'speed_accuracy': 2.0,
        'heading': 2.0,
        'time': 2.0,
      });
      final otherLocationData = LocationData.fromMap(<String, dynamic>{
        'latitude': 42.0,
        'longitude': 2.0,
        'accuracy': 2.0,
        'altitude': 2.0,
        'speed': 2.0,
        'speed_accuracy': 2.0,
        'heading': 2.0,
        'time': 2.0,
      });

      expect(otherLocationData == locationData, true);
      expect(otherLocationData.hashCode == locationData.hashCode, true);
    });

    test('LocationData should be different if one parameters is different', () {
      final locationData = LocationData.fromMap(<String, dynamic>{
        'latitude': 42.0,
        'longitude': 2.0,
        'accuracy': 2.0,
        'altitude': 22.0,
        'speed': 2.0,
        'speed_accuracy': 2.0,
        'heading': 2.0,
        'time': 2.0,
      });
      final otherLocationData = LocationData.fromMap(<String, dynamic>{
        'latitude': 42.0,
        'longitude': 2.0,
        'accuracy': 2.0,
        'altitude': 2.0,
        'speed': 2.0,
        'speed_accuracy': 2.0,
        'heading': 2.0,
        'time': 2.0,
      });

      expect(otherLocationData == locationData, false);
      expect(otherLocationData.hashCode == locationData.hashCode, false);
    });

    test('LocationData with all 16 fields fromMap', () {
      final locationData = LocationData.fromMap(<String, dynamic>{
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

      expect(locationData.latitude, 48.8534);
      expect(locationData.longitude, 2.3488);
      expect(locationData.accuracy, 10.5);
      expect(locationData.altitude, 35.0);
      expect(locationData.speed, 1.2);
      expect(locationData.speedAccuracy, 0.5);
      expect(locationData.heading, 180.0);
      expect(locationData.time, 1609459200000.0);
      expect(locationData.isMock, true);
      expect(locationData.verticalAccuracy, 3.0);
      expect(locationData.headingAccuracy, 2.0);
      expect(locationData.elapsedRealtimeNanos, 123456789.0);
      expect(locationData.elapsedRealtimeUncertaintyNanos, 100.0);
      expect(locationData.satelliteNumber, 12);
      expect(locationData.provider, 'gps');
    });

    test('LocationData with null/missing fields (only latitude/longitude provided)', () {
      final locationData = LocationData.fromMap(<String, dynamic>{
        'latitude': 42.0,
        'longitude': 2.0,
      });

      expect(locationData.latitude, 42.0);
      expect(locationData.longitude, 2.0);
      expect(locationData.accuracy, isNull);
      expect(locationData.altitude, isNull);
      expect(locationData.speed, isNull);
      expect(locationData.speedAccuracy, isNull);
      expect(locationData.heading, isNull);
      expect(locationData.time, isNull);
      expect(locationData.isMock, false);
      expect(locationData.verticalAccuracy, isNull);
      expect(locationData.headingAccuracy, isNull);
      expect(locationData.elapsedRealtimeNanos, isNull);
      expect(locationData.elapsedRealtimeUncertaintyNanos, isNull);
      expect(locationData.satelliteNumber, isNull);
      expect(locationData.provider, isNull);
    });

    test('LocationData with isMock=1 returns true', () {
      final locationData = LocationData.fromMap(<String, dynamic>{
        'latitude': 42.0,
        'longitude': 2.0,
        'isMock': 1,
      });

      expect(locationData.isMock, true);
    });

    test('LocationData with empty Map - all fields null/isMock false', () {
      final locationData = LocationData.fromMap(<String, dynamic>{});

      expect(locationData.latitude, isNull);
      expect(locationData.longitude, isNull);
      expect(locationData.accuracy, isNull);
      expect(locationData.altitude, isNull);
      expect(locationData.speed, isNull);
      expect(locationData.speedAccuracy, isNull);
      expect(locationData.heading, isNull);
      expect(locationData.time, isNull);
      expect(locationData.isMock, false);
      expect(locationData.verticalAccuracy, isNull);
      expect(locationData.headingAccuracy, isNull);
      expect(locationData.elapsedRealtimeNanos, isNull);
      expect(locationData.elapsedRealtimeUncertaintyNanos, isNull);
      expect(locationData.satelliteNumber, isNull);
      expect(locationData.provider, isNull);
    });

    test('LocationData boundary values', () {
      final locationData = LocationData.fromMap(<String, dynamic>{
        'latitude': 90.0,
        'longitude': 180.0,
        'accuracy': 0.0,
      });

      expect(locationData.latitude, 90.0);
      expect(locationData.longitude, 180.0);
      expect(locationData.accuracy, 0.0);
    });

    test('LocationData toString shows mocked when isMock is true', () {
      final locationData = LocationData.fromMap(<String, dynamic>{
        'latitude': 42.0,
        'longitude': 2.0,
        'isMock': 1,
      });

      expect(locationData.toString(), contains('mocked'));
    });
  });

  group('LocationAccuracy', () {
    test('has all 7 values with correct indices', () {
      expect(LocationAccuracy.powerSave.index, 0);
      expect(LocationAccuracy.low.index, 1);
      expect(LocationAccuracy.balanced.index, 2);
      expect(LocationAccuracy.high.index, 3);
      expect(LocationAccuracy.navigation.index, 4);
      expect(LocationAccuracy.reduced.index, 5);
      expect(LocationAccuracy.unset.index, 6);
      expect(LocationAccuracy.values.length, 7);
    });
  });

  group('LocationScenario', () {
    test('has all 6 values with correct indices', () {
      expect(LocationScenario.unset.index, 0);
      expect(LocationScenario.navigation.index, 1);
      expect(LocationScenario.trajectoryTracking.index, 2);
      expect(LocationScenario.carHailing.index, 3);
      expect(LocationScenario.dailyLifeService.index, 4);
      expect(LocationScenario.noPower.index, 5);
      expect(LocationScenario.values.length, 6);
    });
  });

  group('$AndroidNotificationData', () {
    test('AndroidNotificationData should be correctly converted to string', () {
      final androidNotificationData =
          AndroidNotificationData.fromMap(<String, dynamic>{
        'channelId': 'test-id',
        'notificationId': 2,
      });
      expect(
        androidNotificationData.toString(),
        'AndroidNotificationData<channelId: test-id, notificationId: 2>',
      );
    });

    test('AndroidNotificationData should be equal if all parameters are equals',
        () {
      final androidNotificationData = AndroidNotificationData.fromMap(
        <String, dynamic>{
          'channelId': 'test-id',
          'notificationId': 2,
        },
      );
      final otherAndroidNotificationData = AndroidNotificationData.fromMap(
        <String, dynamic>{
          'channelId': 'test-id',
          'notificationId': 2,
        },
      );

      expect(otherAndroidNotificationData == androidNotificationData, true);
      expect(
        otherAndroidNotificationData.hashCode ==
            androidNotificationData.hashCode,
        true,
      );
    });

    test('LocationData should be different if one parameters is different', () {
      final androidNotificationData = AndroidNotificationData.fromMap(
        <String, dynamic>{
          'channelId': 'test-id',
          'notificationId': 2,
        },
      );
      final otherAndroidNotificationData = AndroidNotificationData.fromMap(
        <String, dynamic>{
          'channelId': 'test-id',
          'notificationId': 3,
        },
      );

      expect(otherAndroidNotificationData == androidNotificationData, false);
      expect(
        otherAndroidNotificationData.hashCode ==
            androidNotificationData.hashCode,
        false,
      );
    });
  });
}
