/*
 * Copyright (C) 2024 Huawei Device Co., Ltd.
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

import { Log } from '@ohos/flutter_ohos';
import { EventSink } from '@ohos/flutter_ohos/src/main/ets/plugin/common/EventChannel';
import { MethodResult } from '@ohos/flutter_ohos/src/main/ets/plugin/common/MethodChannel';
import { BusinessError } from '@ohos.base';
import geoLocationManager from '@ohos.geoLocationManager';
import abilityAccessCtrl, { Permissions } from '@ohos.abilityAccessCtrl';
import bundleManager from '@ohos.bundle.bundleManager';
import UIAbility from '@ohos.app.ability.UIAbility';
import backgroundTaskManager from '@ohos.resourceschedule.backgroundTaskManager';
import wantAgent, { WantAgent } from '@ohos.app.ability.wantAgent';

const TAG = 'FlutterLocation';

/**
 * Core location logic implementation for OpenHarmony platform.
 * Encapsulates geoLocationManager, permission management,
 * background task management, and location event subscription.
 */
export class FlutterLocation {
  /** UIAbility instance for context access */
  ability: UIAbility | null = null;
  /** EventSink for streaming location updates to Flutter */
  events: EventSink | null = null;
  /** MethodResult for one-shot permission request responses */
  private _result: MethodResult | null = null;
  /** MethodResult for one-shot getLocation responses */
  private _getLocationResult: MethodResult | null = null;

  /** Concurrent-safe accessor for result */
  get result(): MethodResult | null {
    return this._result;
  }
  set result(value: MethodResult | null) {
    if (this._result != null && value != null) {
      Log.w(TAG, 'Overwriting pending result — completing old result with error');
      this._result.error('REQUEST_INTERRUPTED', 'Previous request was interrupted by a new one', null);
    }
    this._result = value;
  }

  /** Concurrent-safe accessor for getLocationResult */
  get getLocationResult(): MethodResult | null {
    return this._getLocationResult;
  }
  set getLocationResult(value: MethodResult | null) {
    if (this._getLocationResult != null && value != null) {
      Log.w(TAG, 'Overwriting pending getLocationResult — completing old result with error');
      this._getLocationResult.error('REQUEST_INTERRUPTED', 'Previous getLocation request was interrupted', null);
    }
    this._getLocationResult = value;
  }
  /** Token ID for permission verification */
  private tokenId: number | null = null;
  /** Access token manager for permission operations */
  private atManager: abilityAccessCtrl.AtManager = abilityAccessCtrl.createAtManager();
  /** Whether the app is running in foreground (background task) mode */
  private isForeground: boolean = false;
  /** Whether this instance has been disposed */
  private isDisposed: boolean = false;
  /** Whether the location change subscription is active */
  private isSubscribed: boolean = false;
  /** Whether enableBackgroundMode should run after foreground permission is granted */
  private pendingEnableBackgroundMode: boolean = false;
  /** Location request configuration */
  private requestInfo: geoLocationManager.LocationRequest = {
    'priority': geoLocationManager.LocationRequestPriority.FIRST_FIX,
    'scenario': geoLocationManager.LocationRequestScenario.UNSET,
    'timeInterval': 0,
    'distanceInterval': 0,
    'maxAccuracy': 0
  };

  /**
   * Callback for location change events.
   * Returns complete location data to Flutter including all available fields.
   * Nullable so that dispose() can clear the reference without type hacks.
   */
  private locationCallback: ((location: geoLocationManager.Location) => void) | null =
    (location: geoLocationManager.Location): void => {
    if (this.isDisposed) {
      // Complete any pending results to avoid Flutter hang
      if (this.getLocationResult != null) {
        this.getLocationResult.error('PLUGIN_DISPOSED', 'Plugin has been disposed', null);
        this.getLocationResult = null;
      }
      return;
    }
    try {
    const loc = this.buildLocationMap(location);
    if (this.getLocationResult != null) {
      this.getLocationResult.success(loc);
      this.getLocationResult = null;
    }
    if (this.events != null) {
      this.events.success(loc);
    } else {
      this.stopLocationSubscription();
    }
    } catch (err) {
      Log.e(TAG, 'locationCallback error: ' + JSON.stringify(err));
      // Propagate error to Flutter to prevent indefinite hang
      if (this.getLocationResult != null) {
        this.getLocationResult.error('LOCATION_CALLBACK_ERROR',
          'Error processing location data: ' + JSON.stringify(err), null);
        this.getLocationResult = null;
      }
      if (this.events != null) {
        this.events.error('LOCATION_CALLBACK_ERROR',
          'Error processing location data: ' + JSON.stringify(err), null);
      }
    }
  };

  /**
   * Pre-defined success handler for getCurrentLocation Promise.
   * Extracted as a named class property to avoid creating new anonymous functions
   * on each call, reducing GC pressure in high-frequency location request scenarios.
   */
  private onCurrentLocationResolved: ((location: geoLocationManager.Location) => void) | null =
    (location: geoLocationManager.Location): void => {
    if (this.isDisposed) {
      if (this.getLocationResult != null) {
        this.getLocationResult.error('PLUGIN_DISPOSED', 'Plugin has been disposed', null);
        this.getLocationResult = null;
      }
      return;
    }
    if (this.locationCallback != null) {
      this.locationCallback(location);
    }
  };

  /**
   * Pre-defined error handler for getCurrentLocation Promise.
   * Extracted as a named class property to avoid creating new anonymous functions
   * on each call, reducing GC pressure in high-frequency location request scenarios.
   * Nullable so that dispose() can clear the reference without type hacks.
   */
  private onCurrentLocationRejected: ((err: BusinessError) => void) | null =
    (err: BusinessError): void => {
    Log.e(TAG, 'getCurrentLocation err: ' + JSON.stringify(err));
    this.sendError('UNEXPECTED_ERROR',
      'Failed to get location: ' + err.message, null);
  };

  /**
   * Set the UIAbility instance for context access.
   * @param ability - The UIAbility instance, or null to clear
   */
  setAbility(ability: UIAbility | null): void {
    this.ability = ability;
  }

  /**
   * Mark that the pending permission request originates from enableBackgroundMode.
   */
  setPendingEnableBackgroundMode(pending: boolean): void {
    this.pendingEnableBackgroundMode = pending;
  }

  /**
   * Check if the app has location permissions (LOCATION or APPROXIMATELY_LOCATION).
   * @returns true if at least one location permission is granted
   */
  checkPermissions(): boolean {
    Log.i(TAG, 'checkPermissions');
    try {
      if (!this.tokenId) {
        let bundleInfo = bundleManager
          .getBundleInfoForSelfSync(bundleManager.BundleFlag.GET_BUNDLE_INFO_WITH_APPLICATION);
        this.tokenId = bundleInfo.appInfo.accessTokenId;
      }
      let locationPermissionState = this.atManager.verifyAccessTokenSync(
        this.tokenId, 'ohos.permission.LOCATION');
      let approximatelyPermissionState = this.atManager.verifyAccessTokenSync(
        this.tokenId, 'ohos.permission.APPROXIMATELY_LOCATION');
      const locationGranted =
        locationPermissionState == abilityAccessCtrl.GrantStatus.PERMISSION_GRANTED;
      const approxGranted =
        approximatelyPermissionState == abilityAccessCtrl.GrantStatus.PERMISSION_GRANTED;
      return locationGranted || approxGranted;
    } catch (err) {
      Log.e(TAG, 'checkPermissions err: ' + JSON.stringify(err));
      return false;
    }
  }

  /**
   * Check the detailed permission status.
   * @returns Permission status code: 0=denied, 1=granted, 2=deniedForever, 3=grantedLimited
   */
  checkPermissionStatus(): number {
    Log.i(TAG, 'checkPermissionStatus');
    try {
      if (!this.tokenId) {
        let bundleInfo = bundleManager
          .getBundleInfoForSelfSync(bundleManager.BundleFlag.GET_BUNDLE_INFO_WITH_APPLICATION);
        this.tokenId = bundleInfo.appInfo.accessTokenId;
      }
      let locationPermissionState = this.atManager.verifyAccessTokenSync(
        this.tokenId, 'ohos.permission.LOCATION');
      let approximatelyPermissionState = this.atManager.verifyAccessTokenSync(
        this.tokenId, 'ohos.permission.APPROXIMATELY_LOCATION');
      const locationGranted =
        locationPermissionState == abilityAccessCtrl.GrantStatus.PERMISSION_GRANTED;
      const approxGranted =
        approximatelyPermissionState == abilityAccessCtrl.GrantStatus.PERMISSION_GRANTED;
      if (locationGranted) {
        return 1; // granted - precise location
      }
      if (approxGranted) {
        return 3; // grantedLimited - approximate location only
      }
      return 0; // denied
    } catch (err) {
      Log.e(TAG, 'checkPermissionStatus err: ' + JSON.stringify(err));
      return 0;
    }
  }

  /**
   * Request location permissions from the user.
   */
  requestPermissions(): void {
    Log.i(TAG, 'requestPermissions');
    try {
    if (!this.ability || !(this.result || this.getLocationResult || this.events != null)) {
      return;
    }
    if (this.checkPermissions()) {
      const status = this.checkPermissionStatus();
      if (this.getLocationResult != null || this.events != null) {
        this.startRequestingLocation();
      }
      if (this.pendingEnableBackgroundMode && this.result != null) {
        const pendingResult = this.result;
        this.pendingEnableBackgroundMode = false;
        this.result = null;
        this.enableBackgroundMode(pendingResult);
        return;
      }
      this.result?.success(status);
      this.result = null;
      return;
    }
    let array: Array<Permissions> = [
      'ohos.permission.APPROXIMATELY_LOCATION',
      'ohos.permission.LOCATION'
    ];
    // Capture the result reference at call time and clear it from the instance field.
    // This avoids a race where a second concurrent requestPermission() call overwrites
    // this.result, causing this Promise's .then() to resolve the *new* result instead
    // of the one that initiated this request.
    const pendingResult = this.result;
    this.result = null;
    this.atManager.requestPermissionsFromUser(this.ability.context, array).then((data) => {
      if (this.isDisposed) {
        // Complete pending results to avoid Flutter hang
        if (pendingResult != null) {
          pendingResult.error('PLUGIN_DISPOSED', 'Plugin has been disposed', null);
        }
        return;
      }
      // Boundary check: ensure authResults array exists and has expected length
      if (!data.authResults || data.authResults.length < 2) {
        Log.e(TAG, 'requestPermissions: unexpected authResults format');
        if (pendingResult != null) {
          pendingResult.error('PERMISSION_REQUEST_ERROR',
            'Unexpected permission result format', null);
        }
        return;
      }
      if (data.authResults[0] == abilityAccessCtrl.GrantStatus.PERMISSION_GRANTED ||
          data.authResults[1] == abilityAccessCtrl.GrantStatus.PERMISSION_GRANTED) {
        if (this.getLocationResult != null || this.events != null) {
          this.startRequestingLocation();
        }
        if (this.pendingEnableBackgroundMode && pendingResult != null) {
          this.pendingEnableBackgroundMode = false;
          this.enableBackgroundMode(pendingResult);
          return;
        }
        if (data.authResults[1] == abilityAccessCtrl.GrantStatus.PERMISSION_GRANTED) {
          // Precise location granted - return granted(1), matching Android behavior
          pendingResult?.success(1);
        } else {
          // Only approximate location granted - return grantedLimited(3)
          pendingResult?.success(3);
        }
      } else if (data.authResults[1] == abilityAccessCtrl.GrantStatus.PERMISSION_DENIED) {
        this.pendingEnableBackgroundMode = false;
        // OHOS cannot distinguish "denied" from "deniedForever" (no shouldShowRequestPermissionRationale API)
        // Default to "denied" (0) for consistency with other platforms
        // IMPORTANT: Must send result BEFORE sendError, because sendError clears getLocationResult/events
        // but must NOT clear this.result (unlike Android, we need result.success(0) to reach Flutter)
        if (pendingResult != null) {
          pendingResult.success(0);
        }
        this.sendError('PERMISSION_DENIED',
          'Location permission denied', null);
      } else {
        this.pendingEnableBackgroundMode = false;
        if (pendingResult != null) {
          pendingResult.success(0);
        }
        this.sendError('PERMISSION_DENIED', 'Location permission denied', null);
      }
    }).catch((err: BusinessError) => {
      Log.e(TAG, 'requestPermissionsFromUser err: ' + JSON.stringify(err));
      this.sendError('PERMISSION_REQUEST_ERROR',
        'Failed to request permissions: ' + err.message, null);
      if (pendingResult != null) {
        pendingResult.error('PERMISSION_REQUEST_ERROR',
          'Failed to request permissions: ' + err.message, null);
      }
    });
    } catch (err) {
      Log.e(TAG, 'requestPermissions outer err: ' + JSON.stringify(err));
      this.sendError('PERMISSION_REQUEST_ERROR',
        'Failed to request permissions: ' + JSON.stringify(err), null);
      if (this.result != null) {
        this.result.error('PERMISSION_REQUEST_ERROR',
          'Failed to request permissions: ' + JSON.stringify(err), null);
        this.result = null;
      }
    }
  }

  /**
   * Send error to both getLocationResult and events sinks.
   * @param errorCode - Error code string
   * @param errorMessage - Human-readable error message
   * @param errorDetails - Additional error details
   */
  private sendError(errorCode: string, errorMessage: string, errorDetails: string | null): void {
    if (this.getLocationResult != null) {
      this.getLocationResult?.error(errorCode, errorMessage, errorDetails as ESObject);
      this.getLocationResult = null;
    }
    if (this.events != null) {
      this.events?.error(errorCode, errorMessage, errorDetails as ESObject);
      this.events = null;
    }
    // Do NOT clear this.result here — it is managed by the calling method.
    // Android's sendError also does not clear the result reference.
    // The caller is responsible for sending result.success/error and clearing this.result.
  }

  /**
   * Check if the location service is enabled on the device.
   * @returns true if location service is enabled
   */
  checkServiceEnabled(): boolean {
    Log.i(TAG, 'checkServiceEnabled');
    try {
      return geoLocationManager.isLocationEnabled();
    } catch (err) {
      Log.e(TAG, 'isLocationEnabled err:' + JSON.stringify(err));
      return false;
    }
  }

  /**
   * Request to enable the location service.
   * OHOS platform limitation: no system API to pop up enable dialog.
   * @param result - MethodResult to return the response to Flutter
   */
  requestService(result: MethodResult): void {
    Log.i(TAG, 'requestService');
    // First check if the service is already enabled (matching Android behavior)
    try {
      if (this.checkServiceEnabled()) {
        result.success(1);
        return;
      }
    } catch (err) {
      Log.e(TAG, 'requestService checkServiceEnabled err: ' + JSON.stringify(err));
      result.error('SERVICE_STATUS_ERROR',
        'Failed to check location service status', null);
      return;
    }
    // OHOS platform limitation: no system API to pop up location enable dialog.
    Log.i(TAG, 'requestService: service not enabled and cannot prompt on OHOS platform.');
    result.error('SERVICE_STATUS_DISABLED',
      'requestService is not supported on OpenHarmony - please enable location in Settings manually',
      null);
  }

  /**
   * Change location request settings.
   * @param accuracy - Location accuracy enum index
   * @param interval - Update interval in milliseconds
   * @param distanceFilter - Minimum distance for updates (meters), maps to distanceInterval
   * @param distanceInterval - OHOS-specific distance interval parameter
   * @param scenario - Location scenario enum index
   */
  changeSettings(accuracy: number, interval: number, distanceFilter: number,
    distanceInterval: number, scenario: number): void {
    Log.i(TAG, 'changeSettings');
    try {
    // Parameter boundary validation
    if (interval < 0) {
      interval = 0;
    }
    if (distanceFilter != null && distanceFilter < 0) {
      distanceFilter = 0;
    }
    if (distanceInterval != null && distanceInterval < 0) {
      distanceInterval = 0;
    }
    this.requestInfo.timeInterval = interval / 1000;
    // distanceFilter controls minimum displacement distance (meters),
    // should map to distanceInterval (not maxAccuracy) for cross-platform consistency
    this.requestInfo.distanceInterval =
      distanceFilter > 0 ? distanceFilter : distanceInterval;
    this.requestInfo.maxAccuracy = 0;
    this.requestInfo.priority = this.getLocationPriority(accuracy);
    this.requestInfo.scenario = this.getLocationScenario(scenario);
    if (this.events != null) {
      if (this.checkPermissions()) {
        this.startRequestingLocation();
      } else {
        this.requestPermissions();
      }
    }
    } catch (err) {
      Log.e(TAG, 'changeSettings err: ' + JSON.stringify(err));
      // Re-throw so the caller (onChangeSettings) can propagate the error
      // to Flutter via result.error() instead of returning a misleading success(1).
      throw new Error('changeSettings failed: ' + JSON.stringify(err));
    }
  }

  /**
   * Start requesting location updates.
   */
  startRequestingLocation(): void {
    Log.i(TAG, 'startRequestingLocation');
    if (this.isDisposed) {
      // Complete pending results to avoid Flutter hang
      if (this.getLocationResult != null) {
        this.getLocationResult.error('PLUGIN_DISPOSED', 'Plugin has been disposed', null);
        this.getLocationResult = null;
      }
      return;
    }
    try {
      const onResolved = this.onCurrentLocationResolved;
      const onRejected = this.onCurrentLocationRejected;
      geoLocationManager.getCurrentLocation(this.buildCurrentLocationRequest())
        .then((location: geoLocationManager.Location) => {
          if (onResolved != null) {
            onResolved(location);
          }
        })
        .catch((err: BusinessError) => {
          if (onRejected != null) {
            onRejected(err);
          }
        });
    } catch (err) {
      Log.e(TAG, 'getCurrentLocation call err: ' + JSON.stringify(err));
      this.sendError('UNEXPECTED_ERROR',
        'Failed to call getCurrentLocation: ' + JSON.stringify(err), null);
      return;
    }
    if (!this.checkPermissions()) {
      return;
    }
    if (this.events != null) {
      try {
        if (this.requestInfo.timeInterval == 0) {
          this.requestInfo.timeInterval = 1;
        }
        this.stopLocationSubscription();
        if (this.locationCallback != null) {
          geoLocationManager.on('locationChange', this.requestInfo, this.locationCallback);
          this.isSubscribed = true;
        }
      } catch (err) {
        Log.e(TAG, 'locationChange err: ' + JSON.stringify(err));
        // Propagate subscription failure to Flutter, otherwise the
        // onLocationChanged stream would never emit any event or error.
        if (this.events != null) {
          this.events.error('LOCATION_SUBSCRIPTION_ERROR',
            'Failed to subscribe to location changes: ' + JSON.stringify(err), null);
          this.events = null;
        } else if (this.getLocationResult != null) {
          this.getLocationResult.error('LOCATION_SUBSCRIPTION_ERROR',
            'Failed to subscribe to location changes: ' + JSON.stringify(err), null);
          this.getLocationResult = null;
        }
      }
    }
  }

  /**
   * Stop the location change subscription.
   */
  stopLocationSubscription(): void {
    if (this.isSubscribed) {
      try {
        if (this.locationCallback != null) {
          geoLocationManager.off('locationChange', this.locationCallback);
        }
      } catch (err) {
        Log.e(TAG, 'stopLocationSubscription err: ' + JSON.stringify(err));
        // Fallback: try unregistering without the callback reference.
        // This ensures geoLocationManager releases its hold on the callback
        // even if the typed off() fails, preventing a dangling reference chain
        // (geoLocationManager → locationCallback → FlutterLocation) that would
        // keep the FlutterLocation instance from being garbage-collected.
        try {
          geoLocationManager.off('locationChange');
        } catch (err2) {
          Log.e(TAG, 'stopLocationSubscription fallback err: ' + JSON.stringify(err2));
        }
      }
      // Mark as unsubscribed regardless of whether off() succeeded,
      // so state stays consistent and dispose() does not retry incorrectly.
      this.isSubscribed = false;
    }
  }

  /**
   * Check if the app is in foreground (background task) mode.
   * This is the internal implementation of the public API `isBackgroundModeEnabled`.
   * In OHOS, "foreground mode" (long-running task) is equivalent to "background mode enabled" —
   * when a background task is running, the app is in the foreground from the system's perspective.
   * @returns true if background task is running
   */
  isInForegroundMode(): boolean {
    return this.isForeground;
  }

  /**
   * Enable background location mode by starting a background task.
   * @param result - MethodResult to return the response to Flutter
   */
  enableBackgroundMode(result: MethodResult): void {
    try {
    Log.i(TAG, 'enableBackgroundMode');
    if (this.ability == null) {
      result.error('NO_ABILITY', 'Ability context is not available', null);
      return;
    }
    // OHOS LOCATION_IN_BACKGROUND is granted manually in Settings and cannot be
    // reliably obtained via requestPermissionsFromUser. Match the pre-refactor
    // behavior: start the location background task directly when foreground
    // location permission is already granted (checked by MethodCallHandler).
    this.startBackgroundRunningTask(result);
    } catch (err) {
      Log.e(TAG, 'enableBackgroundMode sync err: ' + JSON.stringify(err));
      result.error('BACKGROUND_MODE_ERROR',
        'Failed to enable background mode: ' + JSON.stringify(err), null);
    }
  }

  /**
   * Start the OHOS location background long-running task.
   */
  private startBackgroundRunningTask(result: MethodResult): void {
    let wantAgentInfo: wantAgent.WantAgentInfo = {
      wants: [
        {
          bundleName: this.ability!.context.abilityInfo.bundleName,
          abilityName: this.ability!.context.abilityInfo.name
        }
      ],
      operationType: wantAgent.OperationType.START_ABILITY,
      requestCode: 0,
      wantAgentFlags: [wantAgent.WantAgentFlags.UPDATE_PRESENT_FLAG]
    };
    wantAgent.getWantAgent(wantAgentInfo).then((wantAgentObj: WantAgent) => {
      if (this.isDisposed) {
        result.error('PLUGIN_DISPOSED', 'Plugin has been disposed', null);
        return;
      }
      backgroundTaskManager.startBackgroundRunning(this.ability?.context,
        backgroundTaskManager.BackgroundMode.LOCATION, wantAgentObj).then(() => {
        if (this.isDisposed) {
          try {
            backgroundTaskManager.stopBackgroundRunning(this.ability?.context);
          } catch (e) {
            Log.e(TAG, 'stopBackgroundRunning after dispose err: ' + JSON.stringify(e));
          }
          return;
        }
        this.isForeground = true;
        Log.i(TAG, 'Operation startBackgroundRunning succeeded');
        result.success(1);
      }).catch((err: BusinessError) => {
        Log.e(TAG, 'Operation startBackgroundRunning failed Cause: ' + JSON.stringify(err));
        // Fallback: try requesting background permission (Settings grant on some devices)
        if (!this.checkBackgroundPermissions()) {
          this.requestBackgroundPermission(result);
        } else {
          result.error('BACKGROUND_MODE_ERROR',
            'Failed to start background running: ' + err.message, null);
        }
      });
    }).catch((err: BusinessError) => {
      Log.e(TAG, 'getWantAgent failed: ' + JSON.stringify(err));
      result.error('WANT_AGENT_ERROR',
        'Failed to create WantAgent: ' + err.message, null);
    });
  }

  /**
   * Disable background location mode by stopping the background task.
   * @param result - Optional MethodResult to return the response
   */
  disableBackgroundMode(result?: MethodResult): void {
    Log.i(TAG, 'disableBackgroundMode');
    if (this.ability == null) {
      if (result) {
        result.success(0);
      }
      return;
    }
    try {
      backgroundTaskManager.stopBackgroundRunning(this.ability.context).then(() => {
        this.isForeground = false;
        Log.i(TAG, 'Operation stopBackgroundRunning succeeded');
        if (result) {
          result.success(0);
        }
      }).catch((err: BusinessError) => {
        Log.e(TAG, 'Operation stopBackgroundRunning failed Cause: ' + JSON.stringify(err));
        // If no background task is running, treat disable as success (matching Android)
        this.isForeground = false;
        if (result) {
          result.success(0);
        }
      });
    } catch (err) {
      Log.e(TAG, 'stopBackgroundRunning call err: ' + JSON.stringify(err));
      if (result) {
        result.error('BACKGROUND_MODE_ERROR',
          'Failed to call stopBackgroundRunning: ' + JSON.stringify(err), null);
      }
    }
  }

  /**
   * Check if the app has background location permission.
   * @returns true if LOCATION_IN_BACKGROUND permission is granted
   */
  checkBackgroundPermissions(): boolean {
    Log.i(TAG, 'checkBackgroundPermissions');
    try {
      if (!this.tokenId) {
        let bundleInfo = bundleManager
          .getBundleInfoForSelfSync(bundleManager.BundleFlag.GET_BUNDLE_INFO_WITH_APPLICATION);
        this.tokenId = bundleInfo.appInfo.accessTokenId;
      }
      let backgroundPermissionState = this.atManager.verifyAccessTokenSync(
        this.tokenId, 'ohos.permission.LOCATION_IN_BACKGROUND');
      return backgroundPermissionState == abilityAccessCtrl.GrantStatus.PERMISSION_GRANTED;
    } catch (err) {
      Log.e(TAG, 'checkBackgroundPermissions err: ' + JSON.stringify(err));
      return false;
    }
  }

  /**
   * Request background location permission.
   * @param result - MethodResult to return the response
   */
  private requestBackgroundPermission(result: MethodResult): void {
    Log.i(TAG, 'requestBackgroundPermission');
    if (this.ability == null) {
      result.error('NO_ABILITY', 'Ability context is not available', null);
      return;
    }
    let array: Permissions[] = ['ohos.permission.LOCATION_IN_BACKGROUND'];
    this.atManager.requestPermissionsFromUser(this.ability.context, array).then((data) => {
      if (this.isDisposed) {
        result.error('PLUGIN_DISPOSED', 'Plugin has been disposed', null);
        return;
      }
      // Boundary check: ensure authResults array exists and has expected length
      if (!data.authResults || data.authResults.length < 1) {
        Log.e(TAG, 'requestBackgroundPermission: unexpected authResults format');
        result.error('PERMISSION_REQUEST_ERROR',
          'Unexpected background permission result format', null);
        return;
      }
      if (data.authResults[0] == abilityAccessCtrl.GrantStatus.PERMISSION_GRANTED) {
        this.enableBackgroundMode(result);
      } else {
        result.error('PERMISSION_DENIED',
          'Background location permission denied', null);
      }
    }).catch((err: BusinessError) => {
      Log.e(TAG, 'requestBackgroundPermission err: ' + JSON.stringify(err));
      result.error('PERMISSION_REQUEST_ERROR',
        'Failed to request background permission: ' + err.message, null);
    });
  }

  /**
   * Dispose all resources held by this instance.
   */
  dispose(): void {
    Log.i(TAG, 'dispose');
    this.isDisposed = true;
    // 1. Stop location subscription
    this.stopLocationSubscription();
    // 2. Stop background mode. The context is captured into a local so the async
    // operation can still run after this.ability is cleared below. isForeground is
    // updated in the completion callback to stay consistent with the actual task state.
    if (this.ability != null) {
      const bgContext = this.ability.context;
      try {
        backgroundTaskManager.stopBackgroundRunning(bgContext).then(() => {
          this.isForeground = false;
        }).catch((e: BusinessError) => {
          Log.e(TAG, 'stopBackgroundRunning err in dispose: ' + JSON.stringify(e));
        });
      } catch (err) {
        Log.e(TAG, 'stopBackgroundRunning sync err in dispose: ' + JSON.stringify(err));
      }
    }
    // 3. Clear all references including callbacks and manager (fields are nullable)
    this.locationCallback = null;
    this.onCurrentLocationResolved = null;
    this.onCurrentLocationRejected = null;
    this.events = null;
    this._result = null;
    this._getLocationResult = null;
    this.ability = null;
    this.tokenId = null;
  }

  /**
   * Build a location payload map for Flutter.
   * Uses Map<string, number> to match EventChannel/MethodChannel encoding expectations.
   * Only includes latitude/longitude/accuracy to avoid integer fields (e.g. time)
   * breaking Dart-side LocationData.fromMap double casts.
   */
  private buildLocationMap(location: geoLocationManager.Location): Map<string, number> {
    let loc: Map<string, number> = new Map<string, number>();
    loc.set('latitude', location.latitude);
    loc.set('longitude', location.longitude);
    loc.set('accuracy', location.accuracy);
    return loc;
  }

  /**
   * Build a one-shot location request for getCurrentLocation().
   */
  private buildCurrentLocationRequest(): geoLocationManager.CurrentLocationRequest {
    return {
      'priority': this.requestInfo.priority,
      'scenario': this.requestInfo.scenario,
      'maxAccuracy': this.requestInfo.maxAccuracy
    };
  }

  /**
   * Map accuracy enum value to OHOS LocationRequestPriority.
   * @param value - Accuracy enum index
   * @returns Corresponding OHOS LocationRequestPriority
   */
  private getLocationPriority(value: number): geoLocationManager.LocationRequestPriority {
    switch (value) {
      case LocationPriority.powerSave:
        return geoLocationManager.LocationRequestPriority.FIRST_FIX;
      case LocationPriority.low:
      case LocationPriority.balanced:
      case LocationPriority.reduced:
        return geoLocationManager.LocationRequestPriority.LOW_POWER;
      case LocationPriority.high:
      case LocationPriority.navigation:
        // navigation maps to high accuracy (matching Android PRIORITY_HIGH_ACCURACY)
        return geoLocationManager.LocationRequestPriority.ACCURACY;
      default:
        return geoLocationManager.LocationRequestPriority.UNSET;
    }
  }

  /**
   * Map scenario enum value to OHOS LocationRequestScenario.
   * @param value - Scenario enum index
   * @returns Corresponding OHOS LocationRequestScenario
   */
  private getLocationScenario(value: number): geoLocationManager.LocationRequestScenario {
    switch (value) {
      case LocationScenario.navigation:
        return geoLocationManager.LocationRequestScenario.NAVIGATION;
      case LocationScenario.trajectoryTracking:
        return geoLocationManager.LocationRequestScenario.TRAJECTORY_TRACKING;
      case LocationScenario.carHailing:
        return geoLocationManager.LocationRequestScenario.CAR_HAILING;
      case LocationScenario.dailyLifeService:
        return geoLocationManager.LocationRequestScenario.DAILY_LIFE_SERVICE;
      case LocationScenario.noPower:
        return geoLocationManager.LocationRequestScenario.NO_POWER;
      default:
        return geoLocationManager.LocationRequestScenario.UNSET;
    }
  }
}

/** Location accuracy priority enum */
enum LocationPriority {
  powerSave = 0,
  low = 1,
  balanced = 2,
  high = 3,
  navigation = 4,
  reduced = 5,
  unset = 6
}

/** Location scenario enum for OHOS-specific optimization */
enum LocationScenario {
  unset,
  navigation,
  trajectoryTracking,
  carHailing,
  dailyLifeService,
  noPower
}
