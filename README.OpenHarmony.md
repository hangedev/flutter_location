<p align="center">
  <h1 align="center"> <code>location</code> </h1>
</p>

This project provides OpenHarmony/ohos platform support for [location@5.0.3](https://pub.dev/packages/location/versions/5.0.3) and [location@7.0.1](https://pub.dev/packages/location/versions/7.0.1).

## 1. Installation and Usage

### 1.1 Installation

Go to the project directory and add the following dependencies in pubspec.yaml

<!-- tabs:start -->

#### pubspec.yaml

```yaml
dependencies:
  location:
    git:
      url: https://gitcode.com/CPF-Flutter/flutter_location.git
      # ref: Select the TAG version that matches your Flutter framework version from the table below
      ref: TAG  # Select a TAG from the TAG version mapping table below
      path: "./packages/location"
```

Execute Command

```bash
flutter pub get
```

> TAG naming rule: original-version-ohos-version-betax. See CHANGELOG.OpenHarmony.md for changes between TAG versions. Replace TAG in the dependency example with the TAG selected from the table.

| Flutter framework version | TAG | Branch |
|---|---|---|
| 3.7 | 5.0.3-ohos-1.0.0-beta.1 | master |
| 3.22 | 7.0.1-ohos.1.0.1 | br_location-v7.0.1_ohos |
| 3.27 | 7.0.1-ohos.1.0.1 | br_location-v7.0.1_ohos |
| 3.35 | 7.0.1-ohos.1.0.1 | br_location-v7.0.1_ohos |

> **Migration Note**: When upgrading from location@5.0.3 to location@7.0.1, note that `LocationScenario` enum and `distanceInterval` parameter have been added. Existing code without these parameters will continue to work with default values.

<!-- tabs:end -->

### 1.2 Usage

For use cases see [example](./packages/location/example)

#### Quick Start Example

```dart
import 'package:location/location.dart';

// Get singleton instance
final location = Location();

// Check and request permission
bool serviceEnabled = await location.serviceEnabled();
if (!serviceEnabled) {
  serviceEnabled = await location.requestService();
  if (!serviceEnabled) {
    return;
  }
}

PermissionStatus permissionGranted = await location.hasPermission();
if (permissionGranted == PermissionStatus.denied) {
  permissionGranted = await location.requestPermission();
  if (permissionGranted != PermissionStatus.granted) {
    return;
  }
}

// Get current location
LocationData locationData = await location.getLocation();

// Listen to location stream
location.onLocationChanged.listen((LocationData currentLocation) {
  print('Latitude: ${currentLocation.latitude}');
  print('Longitude: ${currentLocation.longitude}');
  print('Accuracy: ${currentLocation.accuracy}');
  print('Altitude: ${currentLocation.altitude}');
  print('Speed: ${currentLocation.speed}');
  print('Heading: ${currentLocation.heading}');
});
```

#### OHOS-Specific Features Example

```dart
import 'package:location/location.dart';

final location = Location();

// Use OHOS-specific LocationScenario for automatic optimization
await location.changeSettings(
  accuracy: LocationAccuracy.high,
  scenario: LocationScenario.navigation,  // OHOS-specific: navigation scenario
  interval: 1000,
  distanceInterval: 10.0,  // OHOS-specific: distance interval in meters
);

// Use OHOS-specific LocationAccuracy values
await location.changeSettings(
  accuracy: LocationAccuracy.balanced,  // Maps to LOW_POWER on OHOS
  scenario: LocationScenario.trajectoryTracking,  // Trajectory tracking mode
);

// Check and enable background mode
bool isBackgroundEnabled = await location.isBackgroundModeEnabled();
if (!isBackgroundEnabled) {
  await location.enableBackgroundMode(enable: true);
}
```

### 1.3 OHOS Environment Setup

To build and run on OpenHarmony/ohos platform:

1. **Install DevEco Studio**: Download and install [DevEco Studio] version 5.0.13.200 or later
2. **Configure SDK**: Set up OpenHarmony SDK (API version 12 or later) in DevEco Studio
3. **Build the project**:
   ```bash
   cd packages/location/example
   flutter pub get
   flutter build hap
   ```
4. **Deploy and run**: Use DevEco Studio or hdc command to deploy the HAP to the device

## 2. Constraints

### 2.1 Compatibility

This document is verified based on the following versions:

| Library version | Flutter (OHOS) | SDK | DevEco Studio | ROM |
|---|---|---|---|---|
| location@7.0.1 | 3.27.5-ohos-1.0.1 | 5.0.0(12) | 6.0.1.260 | 6.0.0.120 SP6 |
| location@7.0.1 | 3.35.7-ohos-0.0.1 | 6.0.1(21) | 6.0.1.260 | 6.0.0.120 SP6 |

## 3. API

> [!TIP] If the value of **ohos Support** is **yes**, it means that the ohos platform supports this property; **no** means the opposite; **partially** means some capabilities of this property are supported. The usage method is the same on different platforms and the effect is the same as that of iOS or Android.

### Methods

| Name                | return          | Description                                                                                                             | Type     | ohos Support |
|---------------------|-------------------------------------------------------------------------------------------------------------------------|----------|-------------------|-------------------|
| changeSettings({[LocationAccuracy](#LocationAccuracy)? accuracy = [LocationAccuracy](#LocationAccuracy).high,[LocationScenario](#LocationScenario)? scenario = [LocationScenario](#LocationScenario).unset,int? interval = 1000,double? distanceFilter = 0,double? distanceInterval = 0,})                                 | Future<bool> | Changes settings of the location request. | function | yes          |
| isBackgroundModeEnabled() | Future<bool>                                                  | Checks if service is enabled in the background mode. | function | yes          |
| enableBackgroundMode({bool? enable = true})                                 | Future<bool> | Enables or disables service in the background mode. | function | yes          |
| getLocation()                                 | Future<[LocationData](#LocationData)> | Gets the current location of the user. | function | yes          |
| hasPermission()                                 | Future<[PermissionStatus](#PermissionStatus)> | Checks if the app has permission to access location. | function | yes          |
| requestPermission()                                 | Future<[PermissionStatus](#PermissionStatus)> | Requests permission to access location. | function | yes          |
| serviceEnabled()                                 | Future<bool> | Checks if the location service is enabled. | function | yes          |
| requestService()                                 | Future<bool> | Request the activation of the location service. | function | partially          |
| onLocationChanged                                 | Stream<[LocationData](#LocationData)> | Stream of location changes. Subscribe to receive continuous location updates. | property | yes          |
| changeNotificationOptions({...})                                 | Future<[AndroidNotificationData](#AndroidNotificationData)?> | Changes Android notification options for background mode. | function | no          |

> **Note**: `requestService()` is marked as `partially` on OHOS because OpenHarmony does not provide a system API to pop up the location enable dialog. The method will return a `PlatformException` with code `SERVICE_NOT_SUPPORTED`. Users need to manually enable location in system Settings.

### Parameter

| Name                              | return       | Description                                                  | Type     | ohos Support |
| --------------------------------- | ------------ | ------------------------------------------------------------ | -------- | ------------ |
| interval |  | Control the time interval for location updates. | int | yes          |
| distanceFilter |  | Control the distance threshold for location updates. Maps to `distanceInterval` on OHOS. | double | yes          |
| distanceInterval |  | Control the distance interval for location updates (OHOS-specific). | double | yes          |
| enable |  | Control whether to enable the background mode service. | bool | yes          |
| [LocationAccuracy](#LocationAccuracy) |  | Precision of the Location. A lower precision will provide a greater battery life. | enum | yes          |
| [LocationScenario](#LocationScenario) |  | Define location scenario modes in ohos for automatic strategy optimization. | enum | yes          |
| [LocationData](#LocationData) |  | Represents a geographical location in the real world. | class | yes          |
| [PermissionStatus](#PermissionStatus) |  | Status of a permission request to use location services. | enum | yes          |

### LocationAccuracy

| Name                              | return       | Description                                                  | Type     | ohos Support |
| --------------------------------- | ------------ | ------------------------------------------------------------ | -------- | ------------ |
| powerSave |  | Request best accuracy with zero additional power. On OHOS, equivalent to FIRST_FIX. | enum | yes          |
| low |  | Request "city" level accuracy. On OHOS, equivalent to LOW_POWER. | enum | yes          |
| balanced |  | Request "block" level accuracy. On OHOS, equivalent to LOW_POWER. | enum | yes          |
| high |  | Request the most accurate locations. On OHOS, equivalent to ACCURACY. | enum | yes          |
| navigation |  | Request location for navigation usage (affects only iOS). | enum | yes          |
| reduced |  | On iOS 14.0+, mapped to kCLLocationAccuracyReduced. On OHOS, equivalent to LOW_POWER. | enum | yes          |
| unset |  | On OHOS, equivalent to UNSET (affects only OHOS). | enum | yes          |

### LocationScenario

| Name                              | return       | Description                                                  | Type     | ohos Support |
| --------------------------------- | ------------ | ------------------------------------------------------------ | -------- | ------------ |
| unset |  | Request location for default scene (affects only OHOS). | enum | yes          |
| navigation |  | Request location for NAVIGATION scene (affects only OHOS). | enum | yes          |
| trajectoryTracking |  | Request location for TRAJECTORY_TRACKING scene (affects only OHOS). | enum | yes          |
| carHailing |  | Request location for CAR_HAILING scene (affects only OHOS). | enum | yes          |
| dailyLifeService |  | Request location for DAILY_LIFE_SERVICE scene (affects only OHOS). | enum | yes          |
| noPower |  | Request location for NO_POWER scene (affects only OHOS). | enum | yes          |

### LocationData

| Name                              | return       | Description                                                  | Type     | ohos Support |
| --------------------------------- | ------------ | ------------------------------------------------------------ | -------- | ------------ |
| latitude |  | Latitude in degrees. | double | yes          |
| longitude |  | Longitude, in degrees. | double | yes          |
| accuracy |  | Estimated horizontal accuracy of this location, radial, in meters. | double | yes          |
| altitude |  | In meters above the WGS 84 reference ellipsoid. | double | yes          |
| speed |  | In meters/second. | double | yes          |
| heading |  | Heading is the horizontal direction of travel of this device, in degrees. | double | yes          |
| time |  | Timestamp of the LocationData. | double | yes          |
| verticalAccuracy |  | Estimated vertical accuracy of altitude, in meters. | double | no           |
| speedAccuracy |  | In meters/second. | double | no           |
| isMock |  | Is the location currently mocked. | bool | no           |
| headingAccuracy |  | Get the estimated bearing accuracy, in degrees. | double | no           |
| elapsedRealtimeNanos |  | Return the time of this fix, in elapsed real-time since system boot. | double | no           |
| elapsedRealtimeUncertaintyNanos |  | Get estimate of the relative precision of the ElapsedRealtimeNanos timestamp. | double | no           |
| satelliteNumber |  | The number of satellites used to derive the fix. | int | no           |
| provider |  | The name of the provider that generated this fix. | String | no           |

> **Note**: Fields marked as `no` for ohos Support are not directly available in the OHOS `geoLocationManager.Location` API and will return `null`. The `LocationData.fromMap(Map<String, dynamic>)` constructor can be used to create LocationData from a map, with unavailable fields defaulting to `null`.

### PermissionStatus

| Name                              | return       | Description                                                  | Type     | ohos Support |
| --------------------------------- | ------------ | ------------------------------------------------------------ | -------- | ------------ |
| granted |  | The permission to use location services has been granted for high accuracy. | enum | yes          |
| grantedLimited |  | The permission has been granted but for low accuracy (approximate location only). On OHOS, APPROXIMATELY_LOCATION is granted but LOCATION is not. | enum | yes          |
| denied |  | The permission to use location services has been denied by the user. | enum | yes          |
| deniedForever |  | The permission to use location services has been denied forever. No dialog will be displayed on permission request. On OHOS, this status is never returned — see Known Issues. | enum | partially    |

### Singleton Pattern

The `Location` class uses a singleton pattern via factory constructor:

```dart
// Get the singleton instance
final location = Location();

// Or access the instance directly
Location.instance;
```

You can set a custom instance for testing:

```dart
Location.instance = MockLocation();
```

### Stream API

The `onLocationChanged` property provides a stream of location updates:

```dart
// Subscribe to location changes
location.onLocationChanged.listen((LocationData currentLocation) {
  print('Location updated: ${currentLocation.latitude}, ${currentLocation.longitude}');
});

// Cancel subscription
StreamSubscription<LocationData> subscription = location.onLocationChanged.listen((_) {});
subscription.cancel();
```

## 4. Properties

> [!TIP] If the value of **ohos Support** is **yes**, it means that the ohos platform supports this property; **no** means the opposite; **partially** means some capabilities of this property are supported.

| Name                              | return       | Description                                                  | Type     | ohos Support |
| --------------------------------- | ------------ | ------------------------------------------------------------ | -------- | ------------ |
| onLocationChanged | Stream<[LocationData](#LocationData)> | Stream of location changes. Subscribe to receive continuous location updates. | property | yes          |
| instance | Location | Static singleton instance. Can be set to a custom instance for testing. | property | yes          |

## 5. Known Issues

- **requestService()**: On OHOS platform, this method returns a `PlatformException` with code `SERVICE_STATUS_DISABLED` because OpenHarmony does not provide a system API to pop up the location enable dialog. Users need to manually enable location in system Settings.
- **LocationData fields**: Some fields (`verticalAccuracy`, `speedAccuracy`, `isMock`, `headingAccuracy`, `elapsedRealtimeNanos`, `elapsedRealtimeUncertaintyNanos`, `satelliteNumber`, `provider`) are not available in the OHOS `geoLocationManager.Location` API and will return `null`.
- **PermissionStatus.deniedForever**: OHOS platform cannot distinguish between "denied" (user can still request again) and "deniedForever" (user checked "never ask again"). On OHOS, `requestPermission()` always returns `denied`(0) instead of `deniedForever`(2) because the system lacks a `shouldShowRequestPermissionRationale` equivalent API.

## 6. Others

- **Upstream repository**: [location on pub.dev](https://pub.dev/packages/location)
- **Issue tracker**: [GitHub Issues](https://github.com/Lyokone/flutterlocation/issues)
- **OpenHarmony/ohos documentation**: [ohos Location Kit]

## 7. License

This project is licensed under [MIT License](https://gitcode.com/CPF-Flutter/flutter_location/blob/master/LICENSE).

> Template version: v0.0.1
