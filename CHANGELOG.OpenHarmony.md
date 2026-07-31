# CHANGELOG - OpenHarmony/ohos

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
