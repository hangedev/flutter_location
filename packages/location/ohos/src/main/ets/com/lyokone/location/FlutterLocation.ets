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

const TAG = "FlutterLocation";

export class FlutterLocation {
  ability: UIAbility | null = null;
  events: EventSink | null = null;
  result: MethodResult | null = null;
  getLocationResult: MethodResult | null = null;
  private tokenId: number | null = null;
  private atManager: abilityAccessCtrl.AtManager = abilityAccessCtrl.createAtManager();
  private isForeground: boolean = false;
  private requestInfo: geoLocationManager.LocationRequest = {
    'priority': geoLocationManager.LocationRequestPriority.FIRST_FIX,
    'scenario': geoLocationManager.LocationRequestScenario.UNSET,
    'timeInterval': 0,
    'distanceInterval': 0,
    'maxAccuracy': 0
  };
  private mLocationCallback = (location: geoLocationManager.Location) => {
    let loc: Map<string, number> = new Map<string, number>();
    loc.set("latitude", location.latitude);
    loc.set("longitude", location.longitude);
    loc.set("accuracy", location.accuracy);
    if (this.getLocationResult != null) {
      this.getLocationResult.success(loc);
      this.getLocationResult = null;
    }
    if (this.events != null) {
      this.events.success(loc);
    } else {
      geoLocationManager.off("locationChange", this.mLocationCallback);
    }
  }

  setAbility(ability: UIAbility | null) {
    this.ability = ability;
  }

  checkPermissions(): boolean {
    Log.i(TAG, "checkPermissions");
    if (!this.tokenId) {
      let bundleInfo = bundleManager
        .getBundleInfoForSelfSync(bundleManager.BundleFlag.GET_BUNDLE_INFO_WITH_APPLICATION);
      this.tokenId = bundleInfo.appInfo.accessTokenId;
    }
    let locationPermissionState = this.atManager.verifyAccessTokenSync(this.tokenId,
      "ohos.permission.LOCATION");
    return locationPermissionState == abilityAccessCtrl.GrantStatus.PERMISSION_GRANTED;
  }

  requestPermissions(): void {
    Log.i(TAG, "requestPermissions");
    if (!this.ability || !(this.result || this.getLocationResult || this.events != null)) {
      return;
    }
    if (this.checkPermissions()) {
      this.result?.success(1);
      return;
    }
    let array: Array<Permissions> = [
      "ohos.permission.APPROXIMATELY_LOCATION",
      "ohos.permission.LOCATION"
    ]
    this.atManager.requestPermissionsFromUser(this.ability.context, array).then((data) => {
      if (data.authResults[0] == abilityAccessCtrl.GrantStatus.PERMISSION_GRANTED || data.authResults[1] == abilityAccessCtrl.GrantStatus.PERMISSION_GRANTED) {
        if (this.getLocationResult != null || this.events != null) {
          this.startRequestingLocation();
        } else {
          this.result?.success(1);
          this.result = null;
        }
      } else if (data.authResults[1] == abilityAccessCtrl.GrantStatus.PERMISSION_DENIED) {
        this.sendError("PERMISSION_DENIED_NEVER_ASK", "Location permission denied forever - please open app settings", null);
        this.result?.success(2);
        this.result = null;
      } else {
        this.sendError("PERMISSION_DENIED", "Location permission denied", null);
        this.result?.success(0);
        this.result = null;
      }
    }).catch((err: BusinessError) => {
      this.sendError(String(err.code), err.name, err.message);
    })
  }

  private sendError(errorCode: string, errorMessage: string, errorDetails: ESObject) {
    if(this.getLocationResult != null){
      this.getLocationResult?.error(errorCode, errorMessage, errorDetails);
      this.getLocationResult = null;
    }
    if(this.events != null){
      this.events?.error(errorCode, errorMessage, errorDetails);
      this.events = null;
    }
  }

  checkServiceEnabled(): boolean {
    Log.i(TAG, "checkServiceEnabled");
    try {
      return geoLocationManager.isLocationEnabled();
    } catch (err) {
      Log.e(TAG, "isLocationEnabled err:" + JSON.stringify(err));
      return false;
    }
  }

  requestService(result: MethodResult): void {
    Log.i(TAG, "Method requestService not implemented.");
  }

  changeSettings(accuracy: number, interval: number, distanceFilter: number, distanceInterval: number, scenario: number): void {
    Log.i(TAG, "changeSettings");
    this.requestInfo.timeInterval = interval / 1000;
    this.requestInfo.maxAccuracy = distanceFilter;
    this.requestInfo.distanceInterval = distanceInterval;
    this.requestInfo.priority = this.getLocationPriority(accuracy);
    this.requestInfo.scenario = this.getLocationScenario(scenario);
    if (this.events != null) {
      this.startRequestingLocation();
    }
  }

  startRequestingLocation() {
    Log.i(TAG, "startRequestingLocation");
    try {
      geoLocationManager.getCurrentLocation(this.requestInfo).then((location) => {
        this.mLocationCallback(location);
      }).catch((err: BusinessError) => {
        Log.e(TAG, "getCurrentLocation err: " + JSON.stringify(err));
        this.sendError(String(err.code), "Failed to get location: " + err.message, null);
      })
    } catch (err) {
      Log.e(TAG, "getCurrentLocation err: " + JSON.stringify(err));
      this.sendError(String(err.code), "Failed to get location: " + err.message, null);
    }
    if (!this.checkPermissions()) {
      return;
    }
    if (this.events != null) {
      try {
        if (this.requestInfo.timeInterval == 0) {
          this.requestInfo.timeInterval = 1
        }
        geoLocationManager.off("locationChange", this.mLocationCallback);
        geoLocationManager.on("locationChange", this.requestInfo, this.mLocationCallback);
      } catch (err) {
        Log.e(TAG, "locationChange err: " + JSON.stringify(err));
      }
    }
  }

  isInForegroundMode(): boolean {
    return this.isForeground;
  }

  enableBackgroundMode(): void {
    Log.i(TAG, "enableBackgroundMode");
    if (this.ability != null) {
      let wantAgentInfo: wantAgent.WantAgentInfo = {
        wants: [
          {
            bundleName: this.ability.context.abilityInfo.bundleName,
            abilityName: this.ability.context.abilityInfo.name
          }
        ],
        operationType: wantAgent.OperationType.START_ABILITY,
        requestCode: 0,
        wantAgentFlags: [wantAgent.WantAgentFlags.UPDATE_PRESENT_FLAG]
      };

      wantAgent.getWantAgent(wantAgentInfo).then((wantAgentObj: WantAgent) => {
        backgroundTaskManager.startBackgroundRunning(this.ability?.context,
          backgroundTaskManager.BackgroundMode.LOCATION, wantAgentObj).then(() => {
          this.isForeground = true;
          Log.i(TAG, "Operation startBackgroundRunning succeeded");
        }).catch((err: BusinessError) => {
          Log.e(TAG, "Operation startBackgroundRunning failed Cause: " + JSON.stringify(err));
        });
      });
    }
  }

  disableBackgroundMode(): void {
    Log.i(TAG, "disableBackgroundMode");
    if (this.ability != null) {
      backgroundTaskManager.stopBackgroundRunning(this.ability?.context).then(() => {
        this.isForeground = false;
        Log.i(TAG, "Operation stopBackgroundRunning succeeded");
      }).catch((err: BusinessError) => {
        Log.e(TAG, "Operation stopBackgroundRunning failed Cause: " + JSON.stringify(err));
      });
    }
  }

  checkBackgroundPermissions(): boolean {
    Log.i(TAG, "checkBackgroundPermissions");
    if (!this.tokenId) {
      let bundleInfo = bundleManager
        .getBundleInfoForSelfSync(bundleManager.BundleFlag.GET_BUNDLE_INFO_WITH_APPLICATION);
      this.tokenId = bundleInfo.appInfo.accessTokenId;
    }
    let backgroundPermissionState = this.atManager.verifyAccessTokenSync(this.tokenId,
      "ohos.permission.LOCATION_IN_BACKGROUND");
    return backgroundPermissionState == abilityAccessCtrl.GrantStatus.PERMISSION_GRANTED;
  }

  private getLocationPriority(value: number): geoLocationManager.LocationRequestPriority {
    switch (value) {
      case LocationPriority.powerSave:
        return geoLocationManager.LocationRequestPriority.FIRST_FIX;
      case LocationPriority.low:
        return geoLocationManager.LocationRequestPriority.LOW_POWER;
      case LocationPriority.high:
        return geoLocationManager.LocationRequestPriority.ACCURACY;
      default:
        return geoLocationManager.LocationRequestPriority.UNSET;
    }
  }

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

enum LocationPriority {
  powerSave = 0,
  low = 1,
  high = 3,
  unset = 6
}

enum LocationScenario {
  unset,
  navigation,
  trajectoryTracking,
  carHailing,
  dailyLifeService,
  noPower
}