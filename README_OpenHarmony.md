<p align="center">
  <h1 align="center"> <code>location</code> </h1>
</p>



This project is based on [location@5.0.3](https://pub.dev/packages/location/versions/5.0.3).



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
      path: "./packages/location"
```

Execute Command

```bash
flutter pub get
```

<!-- tabs:end -->

### 1.2 Usage

For use cases [example](./packages/location/example)

## 2. Constraints

### 2.1 Compatibility

This document is verified based on the following versions:

1. Flutter: 3.7.12-ohos-1.1.1; SDK: 5.0.0(12); IDE: DevEco Studio: 5.0.13.200; ROM: 5.1.0.120 SP3;

## 3. API

> [!TIP] If the value of **ohos Support** is **yes**, it means that the ohos platform supports this property; **no** means the opposite; **partially** means some capabilities of this property are supported. The usage method is the same on different platforms and the effect is the same as that of iOS or Android.

| Name                | return          | Description                                                                                                             | Type     | ohos Support |
|---------------------|-------------------------------------------------------------------------------------------------------------------------|----------|-------------------|-------------------|
| changeSettings({[LocationAccuracy](#LocationAccuracy)? accuracy = [LocationAccuracy](#LocationAccuracy).high,[LocationScenario](#LocationScenario)? scenario = [LocationScenario](#LocationScenario).unset,int? interval = 1000,double? distanceFilter = 0,double? distanceInterval = 0,})                                 | Future<bool> | Changes settings of the location request. | function | yes          |
| isBackgroundModeEnabled() | Future<bool>                                                  | Checks if service is enabled in the background mode. | function | yes          |
| enableBackgroundMode({bool? enable = true})                                 | Future<bool> | Enables or disables service in the background mode. | function | yes          |
| getLocation()                                 | Future<[LocationData](#LocationData)> | Gets the current location of the user. | function | yes          |
| hasPermission()                                 | Future<[PermissionStatus](#PermissionStatus)> | Checks if the app has permission to access location. | function | yes          |
| requestPermission()                                 | Future<[PermissionStatus](#PermissionStatus)> | Requests permission to access location. | function | yes          |
| serviceEnabled()                                 | Future<bool> | Checks if the location service is enabled. | function | yes          |
| requestService()                                 | Future<bool> | Request the activation of the location service. | function | yes          |

### Parameter
| Name                              | return       | Description                                                  | Type     | ohos Support |
| --------------------------------- | ------------ | ------------------------------------------------------------ | -------- | ------------ |
| interval |  | Control the time interval for location updates. | int | yes          |
| distanceFilter |  | Control the distance threshold for location updates. | double | yes          |
| distanceInterval |  | Control the distance interval for location updates. | double | yes          |
| enable |  | Control whether to enable the background mode service. | bool | yes          |
| [LocationAccuracy](#LocationAccuracy) |  | Precision of the Location. A lower precision will provide a greater battery life. | enum | yes          |
| [LocationScenario](#LocationScenario) |  | It is used to define location scenario modes in HarmonyOS, allowing the system to automatically optimize location strategies according to different scenarios (such as high accuracy, low power consumption, etc.) to balance accuracy and power consumption. | enum | yes          |
| [LocationData](#LocationData) |  | Represents a geographical location in the real world. | class | yes          |
| [PermissionStatus](#PermissionStatus) |  | Status of a permission request to use location services. | enum | yes          |

### LocationAccuracy
| Name                              | return       | Description                                                  | Type     | ohos Support |
| --------------------------------- | ------------ | ------------------------------------------------------------ | -------- | ------------ |
| powerSave |  | To request best accuracy possible with zero additional power consumption.On Ohos, this is equivalent to FIRST_FIX. | enum | yes          |
| low |  | To request "city" level accuracy.On Ohos, this is equivalent to LOW_POWER. | enum | yes          |
| balanced |  | To request "block" level accuracy. | enum | yes          |
| high |  | To request the most accurate locations available.On Ohos, this is equivalent to ACCURACY.| enum | yes          |
| navigation |  | To request location for navigation usage (affect only iOS) | enum | yes          |
| reduced |  | On iOS 14.0+, this is mapped to kCLLocationAccuracyReduced. | enum | yes          |
| unset |  | On Ohos, this is equivalent to UNSET. (affect only Ohos). | enum | yes          |

### LocationScenario
| Name                              | return       | Description                                                  | Type     | ohos Support |
| --------------------------------- | ------------ | ------------------------------------------------------------ | -------- | ------------ |
| unset |  | To request location for default scene (affect only Ohos). | enum | yes          |
| navigation |  | To request location for NAVIGATION scene (affect only Ohos). | enum | yes          |
| trajectoryTracking |  | To request location for default scene (affect only Ohos). | enum | yes          |
| carHailing |  | To request location for CAR_HAILING scene (affect only Ohos). | enum | yes          |
| dailyLifeService |  | To request location for DAILY_LIFE_SERVICE scene (affect only Ohos). | enum | yes          |
| noPower |  | To request location for NO_POWER scene (affect only Ohos). | enum | yes          |

### LocationData
| Name                              | return       | Description                                                  | Type     | ohos Support |
| --------------------------------- | ------------ | ------------------------------------------------------------ | -------- | ------------ |
| latitude |  | Latitude in degrees. | double | yes          |
| longitude |  | Longitude, in degrees. | double | yes          |
| accuracy |  | Estimated horizontal accuracy of this location, radial, in meters. | double | yes          |
| verticalAccuracy |  | Estimated vertical accuracy of altitude, in meters. | double | yes          |
| altitude |  | In meters above the WGS 84 reference ellipsoid. Derived from GPS informations. | double | yes          |
| speed |  |In meters/second. | double | yes          |
| speedAccuracy |  | In meters/second. | double | yes          |
| heading |  | Heading is the horizontal direction of travel of this device, in degrees. | double | yes          |
| time |  | timestamp of the LocationData. | double | yes          |
| isMock |  | Is the location currently mocked. | bool | yes          |
| headingAccuracy |  | Get the estimated bearing accuracy of this location, in degrees. | double | yes          |
| elapsedRealtimeNanos |  | Return the time of this fix, in elapsed real-time since system boot. | double | yes          |
| elapsedRealtimeUncertaintyNanos |  | Get estimate of the relative precision of the alignment of the ElapsedRealtimeNanos timestamp. | double | yes          |
| satelliteNumber |  | The number of satellites used to derive the fix. | int | yes          |
| provider |  | The name of the provider that generated this fix. | String | yes          |

### PermissionStatus
| Name                              | return       | Description                                                  | Type     | ohos Support |
| --------------------------------- | ------------ | ------------------------------------------------------------ | -------- | ------------ |
| granted |  | The permission to use location services has been granted for high accuracy. | enum | yes          |
| grantedLimited |  | The permission has been granted but for low accuracy. Only valid on iOS 14+. | enum | yes          |
| denied |  | The permission to use location services has been denied by the user. May have been denied forever on iOS. | enum | yes          |
| deniedForever |  | The permission to use location services has been denied forever by the user. No dialog will be displayed on permission request. | enum | yes          |


## 4. Properties

> [!TIP] If the value of **ohos Support** is **yes**, it means that the ohos platform supports this property; **no** means the opposite; **partially** means some capabilities of this property are supported. The usage method is the same on different platforms and the effect is the same as that of iOS or Android.

## 5. Known Issues

not

## 6. Others

## 7. License

This project is licensed under  [MIT License](https://gitcode.com/CPF-Flutter/flutter_location/blob/master/LICENSE) .

> Template version: v0.0.1