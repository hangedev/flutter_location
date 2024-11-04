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

const TAG = "LocationPlugin";

export default class LocationPlugin implements FlutterPlugin, AbilityAware {
  private methodCallHandler: MethodCallHandlerImpl | null = null;
  private streamHandlerImpl: StreamHandlerImpl | null = null;
  private abilityBinding: AbilityPluginBinding | null = null;
  private location: FlutterLocation | null = null

  getUniqueClassName(): string {
    return TAG;
  }

  onAttachedToEngine(binding: FlutterPluginBinding): void {
    Log.i(TAG, "onAttachedToEngine");
    this.methodCallHandler = new MethodCallHandlerImpl();
    this.methodCallHandler.startListening(binding.getBinaryMessenger());
    this.streamHandlerImpl = new StreamHandlerImpl();
    this.streamHandlerImpl.startListening(binding.getBinaryMessenger());
  }

  onDetachedFromEngine(binding: FlutterPluginBinding): void {
    Log.i(TAG, "onDetachedFromEngine");
    if (this.methodCallHandler != null) {
      this.methodCallHandler.stopListening();
      this.methodCallHandler = null;
    }
    if (this.streamHandlerImpl != null) {
      this.streamHandlerImpl.stopListening();
      this.streamHandlerImpl = null;
    }
  }

  onAttachedToAbility(binding: AbilityPluginBinding): void {
    Log.i(TAG, "onAttachedToAbility");
    this.abilityBinding = binding;
    this.initialize(new FlutterLocation());
  }

  onDetachedFromAbility(): void {
    Log.i(TAG, "onDetachedFromAbility");
    this.dispose();
  }

  private initialize(location: FlutterLocation): void {
    this.location = location;
    this.location?.setAbility(this.abilityBinding!.getAbility());
    this.methodCallHandler?.setLocation(this.location);
    this.streamHandlerImpl?.setLocation(this.location);
  }

  private dispose(): void {
    this.streamHandlerImpl?.setLocation(null);
    this.methodCallHandler?.setLocation(null);
    this.location?.setAbility(null)
  }
}