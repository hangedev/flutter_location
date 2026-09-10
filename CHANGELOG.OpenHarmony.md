# CHANGELOG - OpenHarmony/ohos

## 8.0.1-ohos-1.0.0 - 2026.9

### Added

- Sync with upstream [location](https://pub.dev/packages/location) **8.0.1** on branch `br_3.41` (Flutter **3.41/3.44** adaptation) ([#41](https://gitcode.com/CPF-Flutter/flutter_location/pull/41)).
- Dart unit tests under `packages/location/test/` covering `MethodChannelLocation` mocks, `LocationData` / `AndroidNotificationData` field parsing, exception paths, and concurrency scenarios via `coverage_test.dart` ([#41](https://gitcode.com/CPF-Flutter/flutter_location/pull/41)).
- `coverage` package in `dev_dependencies` for test coverage reporting ([#41](https://gitcode.com/CPF-Flutter/flutter_location/pull/41)).

### Changed

- OpenHarmony documentation updates in `README.OpenHarmony.md` / `README.OpenHarmony_CN.md`: version matrix for location 8.0.1 and Flutter 3.41/3.44, inline usage examples, `AndroidNotificationData` field notes, and migration guidance ([#41](https://gitcode.com/CPF-Flutter/flutter_location/pull/41)).
- `changeSettings` Dart API aligned with upstream 8.x: restore `pausesLocationUpdatesAutomatically`; keep OHOS-only `scenario` / `distanceInterval` as optional parameters for 7.x API compatibility ([#41](https://gitcode.com/CPF-Flutter/flutter_location/pull/41)).
- Dependencies switched from monorepo `path` to pub-hosted `location_platform_interface` ^6.0.0 and `location_web` ^6.0.0 ([#41](https://gitcode.com/CPF-Flutter/flutter_location/pull/41)).
- Default OHOS location request configuration aligned with Android: 5s interval and `ACCURACY` priority ([#41](https://gitcode.com/CPF-Flutter/flutter_location/pull/41)).

### Fixed

- `buildLocationMap` now returns `altitude`, `speed`, `heading`, and `time` for cross-platform parity with Android/iOS; added `toChannelDouble` to avoid integer channel encoding breaking Dart `LocationData.fromMap` casts ([#41](https://gitcode.com/CPF-Flutter/flutter_location/pull/41)).
- `requestService()` returns `false` (`success(0)`) when location service is disabled, matching the Dart `Future<bool>` contract instead of throwing `PlatformException` ([#41](https://gitcode.com/CPF-Flutter/flutter_location/pull/41)).
- `getLocationPriority` mapping aligned with Android (`powerSave` → `LOW_POWER`, `balanced` → `UNSET`) ([#41](https://gitcode.com/CPF-Flutter/flutter_location/pull/41)).
- `enableBackgroundMode(null)` returns `success(0)` matching Android boundary behavior ([#41](https://gitcode.com/CPF-Flutter/flutter_location/pull/41)).
- Stream error code unified to `NO_CONTEXT` (matching Android) ([#41](https://gitcode.com/CPF-Flutter/flutter_location/pull/41)).
- `sendError()` now stops location subscription immediately to prevent brief subscription retention ([#41](https://gitcode.com/CPF-Flutter/flutter_location/pull/41)).
- Removed non-null assertion in `startBackgroundRunningTask()` with explicit `ability` null guard ([#41](https://gitcode.com/CPF-Flutter/flutter_location/pull/41)).

## 7.0.1-ohos.1.0.1

- **Fixed**: `changeSettings()` now re-throws exceptions so `onChangeSettings` can propagate the error to Flutter via `result.error()` instead of returning a misleading success
- **Fixed**: `startRequestingLocation()` now propagates `geoLocationManager.on("locationChange")` subscription failures to Flutter via `events.error()`/`getLocationResult.error()`, preventing the `onLocationChanged` stream from hanging silently
- **Fixed**: `requestPermissions()` now captures the result reference in a closure at call time, preventing a race where a concurrent request overwrites `this.result` and causes the Promise to resolve the wrong result
- **Fixed**: `dispose()` no longer uses `null as unknown as` type hacks — location callback fields are now declared as nullable (`| null`) and cleared with direct `null` assignment
- **Fixed**: `stopLocationSubscription()` now has an `off("locationChange")` fallback when the typed `off()` fails, and marks `isSubscribed = false` unconditionally to prevent a dangling reference chain that could leak the `FlutterLocation` instance
- **Fixed**: `dispose()` now updates `isForeground` in the `stopBackgroundRunning().then()` callback (instead of immediately) so state stays consistent with the actual background task lifecycle
- **Fixed**: `LocationPlugin.onDetachedFromEngine()` now clears handler references before disposing `location`, eliminating the window where a handler could hold a reference to an already-disposed instance

- **Security**: Added concurrent-safe accessors for `result` and `getLocationResult` to prevent Flutter call hang when result references are overwritten
- **Fixed**: `isDisposed` checks in all async callbacks now complete pending MethodResult/EventSink before returning, preventing Flutter side hangs
- **Fixed**: `requestPermissions()` now has try-catch protection for synchronous exceptions
- **Fixed**: `changeSettings()` now has try-catch protection and parameter boundary validation (negative values clamped to 0)
- **Fixed**: `locationCallback` now has try-catch protection for success() calls
- **Fixed**: `LocationPlugin.initialize()` no longer uses non-null assertion (`!`) for `abilityBinding`
- **Fixed**: `dispose()` now synchronously stops background task instead of using async `disableBackgroundMode()`, ensuring cleanup completes before references are cleared

- **Added**: OpenHarmony/ohos platform support for `location@7.0.1`
- **Added**: `LocationScenario` enum with 6 OHOS-specific scenario modes (unset, navigation, trajectoryTracking, carHailing, dailyLifeService, noPower)
- **Added**: `distanceInterval` parameter for OHOS-specific distance interval control
- **Added**: `LocationAccuracy.unset` enum value mapped to OHOS `UNSET` priority
- **Added**: Background location mode using `backgroundTaskManager.startBackgroundRunning()`
- **Added**: Permission management for `ohos.permission.LOCATION`, `ohos.permission.APPROXIMATELY_LOCATION`, and `ohos.permission.LOCATION_IN_BACKGROUND`
- **Added**: `PermissionStatus.grantedLimited` support for approximate location permission
- **Fixed**: `requestPermission` now correctly returns `denied`(0) instead of `deniedForever`(2) when permission is denied, since OHOS cannot distinguish between denied and deniedForever
- **Fixed**: `requestPermission` now always sends `result.success(1)` when permission is granted, matching Android behavior
- **Fixed**: `time` field in `LocationData` now returns epoch milliseconds (using `Date.now()`) instead of `timeSinceBoot`, matching Android/iOS behavior
- **Fixed**: `LocationAccuracy.balanced` and `LocationAccuracy.reduced` now correctly map to `LOW_POWER` priority on OHOS
- **Fixed**: `StreamHandlerImpl.onListen` now sends error to `EventSink` when location/ability is null instead of silently returning
- **Fixed**: `disableBackgroundMode` now has try-catch protection around `stopBackgroundRunning` call
- **Fixed**: `changeSettings` now checks permissions before restarting location requests
- **Fixed**: `enableBackgroundMode` now validates `enable` parameter type
- **Fixed**: `dispose()` now clears `atManager`, `tokenId`, and `locationCallback` references to prevent memory leaks
- **Fixed**: Added `isDisposed` flag to prevent callback execution after dispose
- **Fixed**: `sendError()` no longer clears `this.result` — the calling method is responsible for sending and clearing `result`, matching Android behavior. This fixes a critical bug where `requestPermission` Future would never complete when permission was denied
- **Fixed**: `requestPermissions()` now sends `result.success(0)` BEFORE calling `sendError()`, ensuring Flutter receives the permission denial response
- **Fixed**: `requestService()` now checks if location service is already enabled before returning error, matching Android behavior
- **Fixed**: `enableBackgroundMode` disable operation no longer requires permission check, matching Android behavior
- **Fixed**: `StreamHandlerImpl.onListen` error code changed from `"NOT_INITIALIZED"` to `"NO_ACTIVITY"` to match Android error code
- **Fixed**: `LocationPriority` enum now includes `navigation = 4`, mapped to `ACCURACY` priority
- **Fixed**: `changeSettings` parameter validation now covers all parameters (`distanceFilter`, `distanceInterval`, `scenario`)
- **Fixed**: `startBackgroundRunning().then()` now checks `isDisposed` and immediately stops background task if disposed during async operation
- **Fixed**: `dispose()` now unconditionally attempts to stop background mode (handles async race condition) and clears `locationCallback` reference
- **Fixed**: `isInForegroundMode()` now has documentation comment explaining its relationship to `isBackgroundModeEnabled`
- **Improved**: Documentation - added `changeNotificationOptions` to Methods table with "ohos Support: no"
- **Improved**: Documentation - added OHOS-specific features example code (LocationScenario, distanceInterval)
- **Improved**: Documentation - merged SDK/ROM version columns into version mapping table
- **Improved**: Documentation - removed redundant underscore-named doc files
- **Improved**: Documentation - fixed Chinese tip text to reference "OHOS 支持" instead of "ohos Support"
- **Improved**: Added comprehensive test coverage including concurrent, exception, and boundary test scenarios
- **Improved**: Added `coverage` package to dev_dependencies for test coverage reporting
- **Improved**: Unified BDD-style test naming conventions
- **Improved**: Documentation - added `onLocationChanged` to Methods table, filled empty sections, localized Chinese table headers
