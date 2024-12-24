/*
 * MIT License
 * 
 * Copyright (c) 2023 Hunan OpenValley Digital Industry Development Co., Ltd.
 * 
 * Permission is hereby granted, free of charge, to any person obtaining a copy
 * of this software and associated documentation files (the "Software"), to deal
 * in the Software without restriction, including without limitation the rights
 * to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 * copies of the Software, and to permit persons to whom the Software is
 * furnished to do so, subject to the following conditions:
 * 
 * The above copyright notice and this permission notice shall be included in all
 * copies or substantial portions of the Software.
 * 
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 * OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
 * SOFTWARE.
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