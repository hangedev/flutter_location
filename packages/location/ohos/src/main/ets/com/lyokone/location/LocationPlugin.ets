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

import { AbilityAware, AbilityPluginBinding, FlutterPlugin, Log } from '@ohos/flutter_ohos';
import { FlutterPluginBinding } from '@ohos/flutter_ohos/src/main/ets/embedding/engine/plugins/FlutterPlugin';
import MethodCallHandlerImpl from './MethodCallHandlerImpl';
import StreamHandlerImpl from './StreamHandlerImpl';
import { FlutterLocation } from './FlutterLocation';

const TAG = 'LocationPlugin';

/**
 * Main plugin class for the location Flutter plugin on OpenHarmony.
 * Implements FlutterPlugin and AbilityAware lifecycle management.
 */
export default class LocationPlugin implements FlutterPlugin, AbilityAware {
  private methodCallHandler: MethodCallHandlerImpl | null = null;
  private streamHandlerImpl: StreamHandlerImpl | null = null;
  private abilityBinding: AbilityPluginBinding | null = null;
  private location: FlutterLocation | null = null;

  getUniqueClassName(): string {
    return TAG;
  }

  onAttachedToEngine(binding: FlutterPluginBinding): void {
    Log.i(TAG, 'onAttachedToEngine');
    this.methodCallHandler = new MethodCallHandlerImpl();
    this.methodCallHandler.startListening(binding.getBinaryMessenger());
    this.streamHandlerImpl = new StreamHandlerImpl();
    this.streamHandlerImpl.startListening(binding.getBinaryMessenger());
    this.ensureLocation();
  }

  onDetachedFromEngine(binding: FlutterPluginBinding): void {
    Log.i(TAG, 'onDetachedFromEngine');
    if (this.streamHandlerImpl != null) {
      this.streamHandlerImpl.setLocation(null);
    }
    if (this.methodCallHandler != null) {
      this.methodCallHandler.setLocation(null);
    }
    if (this.location != null) {
      this.location.dispose();
      this.location = null;
    }
    if (this.streamHandlerImpl != null) {
      this.streamHandlerImpl.stopListening();
      this.streamHandlerImpl = null;
    }
    if (this.methodCallHandler != null) {
      this.methodCallHandler.stopListening();
      this.methodCallHandler = null;
    }
    this.abilityBinding = null;
  }

  onAttachedToAbility(binding: AbilityPluginBinding): void {
    Log.i(TAG, 'onAttachedToAbility');
    this.abilityBinding = binding;
    this.ensureLocation();
    this.location?.setAbility(binding.getAbility());
  }

  onDetachedFromAbility(): void {
    Log.i(TAG, 'onDetachedFromAbility');
    // Keep abilityBinding — Flutter may not re-invoke onAttachedToAbility after
    // the permission dialog closes; ensureLocation() restores ability on next call.
    this.location?.detachFromAbility();
    if (this.abilityBinding != null) {
      this.location?.setAbility(this.abilityBinding.getAbility());
    }
  }

  private ensureLocation(): void {
    if (this.location == null) {
      this.location = new FlutterLocation();
    }
    if (this.abilityBinding != null) {
      this.location.setAbility(this.abilityBinding.getAbility());
    }
    this.methodCallHandler?.setLocation(this.location);
    this.streamHandlerImpl?.setLocation(this.location);
  }
}
