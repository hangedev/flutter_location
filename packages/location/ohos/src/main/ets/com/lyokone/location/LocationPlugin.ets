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

  /**
   * Get the unique class name for this plugin.
   * @returns The plugin class name
   */
  getUniqueClassName(): string {
    return TAG;
  }

  /**
   * Called when the plugin is attached to the Flutter engine.
   * @param binding - FlutterPluginBinding providing engine resources
   */
  onAttachedToEngine(binding: FlutterPluginBinding): void {
    Log.i(TAG, 'onAttachedToEngine');
    this.methodCallHandler = new MethodCallHandlerImpl();
    this.methodCallHandler.startListening(binding.getBinaryMessenger());
    this.streamHandlerImpl = new StreamHandlerImpl();
    this.streamHandlerImpl.startListening(binding.getBinaryMessenger());
  }

  /**
   * Called when the plugin is detached from the Flutter engine.
   * Releases all resources including location subscription and background mode.
   * @param binding - FlutterPluginBinding providing engine resources
   */
  onDetachedFromEngine(binding: FlutterPluginBinding): void {
    Log.i(TAG, 'onDetachedFromEngine');
    // 1. Clear handlers' location references FIRST so there is no window where
    //    a handler holds a reference to an already-disposed FlutterLocation.
    if (this.streamHandlerImpl != null) {
      this.streamHandlerImpl.setLocation(null);
    }
    if (this.methodCallHandler != null) {
      this.methodCallHandler.setLocation(null);
    }
    // 2. Stop location subscription and background mode
    if (this.location != null) {
      this.location.dispose();
      this.location = null;
    }
    // 3. Stop listening and release handler instances
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

  /**
   * Called when the plugin is attached to an Ability.
   * @param binding - AbilityPluginBinding providing Ability context
   */
  onAttachedToAbility(binding: AbilityPluginBinding): void {
    Log.i(TAG, 'onAttachedToAbility');
    this.abilityBinding = binding;
    this.initialize(new FlutterLocation());
  }

  /**
   * Called when the plugin is detached from an Ability.
   */
  onDetachedFromAbility(): void {
    Log.i(TAG, 'onDetachedFromAbility');
    this.dispose();
  }

  /**
   * Initialize the FlutterLocation instance and bind it to handlers.
   * @param location - The FlutterLocation instance to initialize
   */
  private initialize(location: FlutterLocation): void {
    this.location = location;
    // Safe null check instead of non-null assertion
    if (this.abilityBinding != null) {
      this.location?.setAbility(this.abilityBinding.getAbility());
    }
    this.methodCallHandler?.setLocation(this.location);
    this.streamHandlerImpl?.setLocation(this.location);
  }

  /**
   * Dispose all Ability-level resources.
   * Stops location subscription, background mode, and clears all references.
   */
  private dispose(): void {
    // 1. Stop location subscription and background mode
    if (this.location != null) {
      this.location.dispose();
      this.location = null;
    }
    // 2. Clear handlers' location references
    this.streamHandlerImpl?.setLocation(null);
    this.methodCallHandler?.setLocation(null);
    // 3. Clear ability binding
    this.abilityBinding = null;
  }
}
