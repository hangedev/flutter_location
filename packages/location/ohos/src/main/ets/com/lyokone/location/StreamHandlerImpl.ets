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

import { BinaryMessenger, EventChannel, Log } from '@ohos/flutter_ohos';
import { EventSink, StreamHandler } from '@ohos/flutter_ohos/src/main/ets/plugin/common/EventChannel';
import { FlutterLocation } from './FlutterLocation';

const TAG = "StreamHandlerImpl";
const STREAM_CHANNEL_NAME = "lyokone/locationstream";

export default class StreamHandlerImpl implements StreamHandler {
  private location: FlutterLocation | null = null;
  private channel: EventChannel | null = null;

  setLocation(location: FlutterLocation | null) {
    this.location = location;
  }

  startListening(messenger: BinaryMessenger) {
    if (this.channel != null) {
      this.stopListening();
    }
    this.channel = new EventChannel(messenger, STREAM_CHANNEL_NAME);
    this.channel.setStreamHandler(this);
  }

  stopListening() {
    if (this.channel == null) {
      return;
    }
    this.channel.setStreamHandler(null);
    this.channel = null;
  }

  onListen(args: ESObject, events: EventSink): void {
    Log.i(TAG, "onListen");
    if (this.location == null || this.location.ability == null) {
      return;
    }
    this.location.events = events;
    if (!this.location.checkPermissions()) {
      this.location.requestPermissions();
    } else {
      this.location.startRequestingLocation();
    }
  }

  onCancel(args: ESObject): void {
    Log.i(TAG, "onCancel");
    if (this.location) {
      this.location.events = null;
    }
  }
}