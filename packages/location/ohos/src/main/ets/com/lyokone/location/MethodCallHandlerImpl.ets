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

import { BinaryMessenger, Log, MethodCall } from '@ohos/flutter_ohos';
import MethodChannel, {
  MethodCallHandler,
  MethodResult
} from '@ohos/flutter_ohos/src/main/ets/plugin/common/MethodChannel';
import { FlutterLocation } from './FlutterLocation';

const TAG = 'MethodCallHandlerImpl';
const METHOD_CHANNEL_NAME = 'lyokone/location';

/**
 * MethodChannel call handler for the location plugin.
 * Dispatches incoming MethodChannel calls to FlutterLocation methods.
 */
export default class MethodCallHandlerImpl implements MethodCallHandler {
  private location: FlutterLocation | null = null;
  private channel: MethodChannel | null = null;

  /**
   * Set the FlutterLocation instance.
   * @param location - FlutterLocation instance or null to clear
   */
  setLocation(location: FlutterLocation | null): void {
    this.location = location;
  }

  /**
   * Start listening for MethodChannel calls.
   * @param messenger - BinaryMessenger for channel communication
   */
  startListening(messenger: BinaryMessenger): void {
    if (this.channel != null) {
      this.stopListening();
    }
    this.channel = new MethodChannel(messenger, METHOD_CHANNEL_NAME);
    this.channel.setMethodCallHandler(this);
  }

  /**
   * Stop listening for MethodChannel calls.
   */
  stopListening(): void {
    if (this.channel == null) {
      return;
    }
    this.channel.setMethodCallHandler(null);
    this.channel = null;
  }

  /**
   * Handle incoming MethodChannel calls with try-catch protection.
   * @param call - The incoming MethodCall
   * @param result - The MethodResult for sending responses
   */
  onMethodCall(call: MethodCall, result: MethodResult): void {
    Log.i(TAG, 'onMethodCall step in');
    const method = call.method;
    Log.i(TAG, 'Received ' + method + ' message.');

    // Check if location is initialized before processing
    if (this.location == null) {
      result.error('NOT_INITIALIZED', 'Location plugin not initialized yet', null);
      return;
    }

    try {
      switch (method) {
        case 'changeSettings':
          this.onChangeSettings(call, result);
          break;
        case 'getLocation':
          this.onGetLocation(result);
          break;
        case 'hasPermission':
          this.onHasPermission(result);
          break;
        case 'requestPermission':
          this.onRequestPermission(result);
          break;
        case 'serviceEnabled':
          this.onServiceEnabled(result);
          break;
        case 'requestService':
          this.location.requestService(result);
          break;
        case 'isBackgroundModeEnabled':
          this.isBackgroundModeEnabled(result);
          break;
        case 'enableBackgroundMode':
          this.enableBackgroundMode(call, result);
          break;
        case 'changeNotificationOptions':
          this.onChangeNotificationOptions(call, result);
          break;
        default:
          result.notImplemented();
          break;
      }
    } catch (err) {
      result.error('UNHANDLED_EXCEPTION',
        'Unhandled error in ' + method + ': ' + JSON.stringify(err), null);
    }
  }

  /**
   * Check if the app has location permission.
   * @param result - MethodResult for sending the permission status
   */
  private onHasPermission(result: MethodResult): void {
    try {
      if (this.location?.checkPermissions()) {
        const status = this.location.checkPermissionStatus();
        result.success(status);
      } else {
        result.success(0);
      }
    } catch (err) {
      result.error('PERMISSION_CHECK_ERROR',
        'Failed to check permissions: ' + JSON.stringify(err), null);
    }
  }

  /**
   * Request location permission from the user.
   * @param result - MethodResult for sending the permission result
   */
  private onRequestPermission(result: MethodResult): void {
    try {
      if (this.location) {
        this.location.result = result;
        this.location.requestPermissions();
      }
    } catch (err) {
      result.error('PERMISSION_REQUEST_ERROR',
        'Failed to request permissions: ' + JSON.stringify(err), null);
    }
  }

  /**
   * Get the current location.
   * @param result - MethodResult for sending the location data
   */
  private async onGetLocation(result: MethodResult): Promise<void> {
    try {
      if (this.location) {
        this.location.getLocationResult = result;
        if (!this.location.checkPermissions()) {
          this.location.requestPermissions();
        } else {
          this.location.startRequestingLocation();
        }
      }
    } catch (err) {
      result.error('GET_LOCATION_ERROR',
        'Failed to get location: ' + JSON.stringify(err), null);
    }
  }

  /**
   * Change location request settings with parameter validation.
   * @param call - MethodCall containing settings parameters
   * @param result - MethodResult for sending the response
   */
  onChangeSettings(call: MethodCall, result: MethodResult): void {
    if (this.location) {
      try {
        const accuracy: Object | null = call.argument('accuracy') as Object | null;
        const interval: Object | null = call.argument('interval') as Object | null;
        const distanceFilter: Object | null = call.argument('distanceFilter') as Object | null;
        const distanceInterval: Object | null = call.argument('distanceInterval') as Object | null;
        const scenario: Object | null = call.argument('scenario') as Object | null;
        // Validate parameter types
        if (typeof accuracy !== 'number' || typeof interval !== 'number') {
          result.error('INVALID_ARGUMENT', 'accuracy and interval must be numbers', null);
          return;
        }
        if (distanceFilter != null && typeof distanceFilter !== 'number') {
          result.error('INVALID_ARGUMENT', 'distanceFilter must be a number', null);
          return;
        }
        if (distanceInterval != null && typeof distanceInterval !== 'number') {
          result.error('INVALID_ARGUMENT', 'distanceInterval must be a number', null);
          return;
        }
        if (scenario != null && typeof scenario !== 'number') {
          result.error('INVALID_ARGUMENT', 'scenario must be a number', null);
          return;
        }
        this.location.changeSettings(
          accuracy as number,
          interval as number,
          (distanceFilter ?? 0) as number,
          (distanceInterval ?? 0) as number,
          (scenario ?? 0) as number
        );
        result.success(1);
      } catch (err) {
        result.error('CHANGE_SETTINGS_ERROR',
          'An unexpected error happened during location settings change: ' + JSON.stringify(err),
          null);
      }
    }
  }

  /**
   * Check if the location service is enabled.
   * @param result - MethodResult for sending the service status
   */
  onServiceEnabled(result: MethodResult): void {
    if (this.location) {
      try {
        result.success(this.location.checkServiceEnabled() ? 1 : 0);
      } catch (err) {
        result.error('SERVICE_STATUS_ERROR',
          'Location service status couldn\'t be determined', null);
      }
    }
  }

  /**
   * Check if background mode is enabled.
   * @param result - MethodResult for sending the background mode status
   */
  isBackgroundModeEnabled(result: MethodResult): void {
    try {
      if (this.location) {
        result.success(this.location.isInForegroundMode() ? 1 : 0);
      } else {
        result.success(0);
      }
    } catch (err) {
      result.error('BACKGROUND_MODE_ERROR',
        'Failed to check background mode status: ' + JSON.stringify(err), null);
    }
  }

  /**
   * Enable or disable background mode with proper permission handling.
   * @param call - MethodCall containing the 'enable' parameter
   * @param result - MethodResult for sending the response
   */
  enableBackgroundMode(call: MethodCall, result: MethodResult): void {
    try {
      let enable: boolean = call.argument('enable');
      if (this.location != null && enable != null && typeof enable === 'boolean') {
        if (!enable) {
          // Disable does not require permission check (matching Android behavior)
          this.location.disableBackgroundMode(result);
          return;
        }
        if (this.location.checkPermissions()) {
          this.location.enableBackgroundMode(result);
        } else {
          result.error('PERMISSION_DENIED', 'Location permission denied', null);
        }
      } else {
        result.error('INVALID_ARGUMENT',
          'enableBackgroundMode requires a valid boolean \'enable\' parameter', null);
      }
    } catch (err) {
      result.error('BACKGROUND_MODE_ERROR',
        'Failed to change background mode: ' + JSON.stringify(err), null);
    }
  }

  /**
   * Handle changeNotificationOptions (Android-only feature).
   * @param call - MethodCall containing notification options
   * @param result - MethodResult for sending the response
   */
  onChangeNotificationOptions(call: MethodCall, result: MethodResult): void {
    // Android-only feature, not supported on OHOS
    Log.i(TAG, 'Method onChangeNotificationOptions not implemented on OHOS.');
    result.notImplemented();
  }
}
